import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// Mobile parity for the website's `AddressMapPicker.client.vue`. Uses the
/// same OSM tile server and Nominatim endpoints, defaults to Baku, supports
/// tap-to-place + drag-to-refine, and emits `(lat, lng, formattedAddress)`
/// to the parent on every change.
typedef OnPickAddress = void Function(double lat, double lng, String address);

class AddressMapPicker extends StatefulWidget {
  const AddressMapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.onPick,
  });

  final double? initialLat;
  final double? initialLng;
  final OnPickAddress onPick;

  @override
  State<AddressMapPicker> createState() => _AddressMapPickerState();
}

class _AddressMapPickerState extends State<AddressMapPicker> {
  static const _bakuCenter = LatLng(40.4093, 49.8671);

  final _mapController = MapController();
  final _searchCtrl = TextEditingController();

  LatLng? _marker;
  String? _selectedAddress;
  bool _searching = false;
  Timer? _reverseDebounce;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) {
      _marker = LatLng(lat, lng);
      _scheduleReverse(_marker!);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _reverseDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _center => _marker ?? _bakuCenter;

  void _onTap(TapPosition tap, LatLng latlng) {
    setState(() => _marker = latlng);
    _mapController.move(latlng, _mapController.camera.zoom < 14 ? 14 : _mapController.camera.zoom);
    _scheduleReverse(latlng);
  }

  /// Debounced reverse geocoding so quick successive taps don't spam
  /// Nominatim (1-req/sec usage policy).
  void _scheduleReverse(LatLng p) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 400), () => _reverseGeocode(p));
  }

  Future<void> _reverseGeocode(LatLng p) async {
    final loc = context.l10n;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${p.latitude}&lon=${p.longitude}&accept-language=${loc.localeName}',
      );
      final res = await http.get(uri, headers: const {'User-Agent': 'master-mobile/1.0'});
      String addr;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        addr = (data['display_name'] as String?) ??
            '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
      } else {
        addr = '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
      }
      if (!mounted) return;
      setState(() => _selectedAddress = addr);
      widget.onPick(p.latitude, p.longitude, addr);
    } catch (_) {
      final addr = '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
      if (!mounted) return;
      setState(() => _selectedAddress = addr);
      widget.onPick(p.latitude, p.longitude, addr);
    }
  }

  Future<void> _searchAddress() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(q)}&limit=1&countrycodes=az',
      );
      final res = await http.get(uri, headers: const {'User-Agent': 'master-mobile/1.0'});
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final r = list.first as Map<String, dynamic>;
          final lat = double.tryParse(r['lat'].toString());
          final lng = double.tryParse(r['lon'].toString());
          final display = r['display_name']?.toString();
          if (lat != null && lng != null) {
            final p = LatLng(lat, lng);
            setState(() {
              _marker = p;
              _selectedAddress = display ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
            });
            _mapController.move(p, 15);
            widget.onPick(lat, lng, _selectedAddress!);
          }
        }
      }
    } catch (_) {/* swallow — search is best-effort */}
    if (mounted) setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HmColors.border2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: HmColors.border2)),
            ),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 18, color: HmColors.text4),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchAddress(),
                  style: const TextStyle(fontSize: 13, color: HmColors.text),
                  decoration: InputDecoration(
                    hintText: loc.address_search_map,
                    hintStyle: const TextStyle(color: HmColors.text5, fontSize: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (_searching)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: HmColors.accent),
                )
              else if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: HmColors.accent),
                  onPressed: _searchAddress,
                ),
            ]),
          ),
          // Map
          SizedBox(
            height: 260,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 13,
                onTap: _onTap,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'az.gasimov.master',
                  maxZoom: 18,
                ),
                if (_marker != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _marker!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: HmColors.accent,
                        size: 36,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                    ),
                  ]),
              ],
            ),
          ),
          // Selected
          if (_selectedAddress != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: HmColors.accentSoft,
                border: Border(top: BorderSide(color: HmColors.accentBorder)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: HmColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedAddress!,
                      style: const TextStyle(
                          fontSize: 12, color: HmColors.accent, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: HmColors.border2)),
              ),
              child: Text(
                loc.address_tap_to_pick,
                style: const TextStyle(fontSize: 12, color: HmColors.text5, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}
