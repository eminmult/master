import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/routing/tab_switcher.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/addresses/data/addresses_repository.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';
import 'package:master_mobile/features/user_profile/data/user_profile_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Categories shown on the order create step. Family-keyed by master id so
/// the listing is *narrowed to the master's own categories* when the user
/// arrived from a master profile (we shouldn't let them order plumbing from
/// an electrician). When `null`, falls back to the public catalog.
final _categoriesProvider = FutureProvider.autoDispose
    .family<List<ServiceCategory>, int?>((ref, masterId) async {
  if (masterId != null) {
    final profile = await ref.watch(userProfileProvider(masterId).future);
    final mp = profile['master_profile'];
    if (mp is Map<String, dynamic>) {
      final raw = (mp['categories'] as List?) ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ServiceCategory.fromJson)
          .toList();
    }
    return const [];
  }
  return ref.watch(categoriesRepositoryProvider).list(onlyWithMasters: true);
});

/// Multi-step order create — pick category → describe → address → submit.
/// Photos are deferred to after MVP since `image_picker` flow needs platform
/// permissions plumbing the user might not have ready.
///
/// When opened from a master profile, `preferredMasterId` is set and the
/// order is sent directly to that specific master with status pending_master
/// (rather than broadcast to the public pool).
class OrderCreatePage extends ConsumerStatefulWidget {
  const OrderCreatePage({
    super.key,
    this.preselectedCategoryId,
    this.preferredMasterId,
    this.preferredMasterName,
  });
  final int? preselectedCategoryId;
  final int? preferredMasterId;
  final String? preferredMasterName;

  @override
  ConsumerState<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends ConsumerState<OrderCreatePage> {
  int _step = 0;
  int? _categoryId;
  final _description = TextEditingController();
  // Picked saved address — drives step 3. We don't free-type here anymore;
  // /addresses/new is the single source of truth for new entries.
  Address? _selectedAddress;
  bool _busy = false;
  String? _error;

  /// Up to 5 photos, base64-encoded with `data:image/jpeg;base64,…` prefix —
  /// matches the format `OrderController::store` expects under `photos.*`.
  final List<String> _photos = [];
  static const int _maxPhotos = 5;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.preselectedCategoryId;
    if (_categoryId != null) _step = 1;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= _maxPhotos) return;
    final picker = ImagePicker();
    final remaining = _maxPhotos - _photos.length;
    final picked = await picker.pickMultiImage(imageQuality: 80, limit: remaining);
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    final encoded = <String>[];
    for (final x in picked.take(remaining)) {
      final bytes = await x.readAsBytes();
      // Compress further to keep base64 payload reasonable (server caps at 5 photos).
      final Uint8List compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );
      encoded.add('data:image/jpeg;base64,${base64Encode(compressed)}');
    }
    setState(() {
      _photos.addAll(encoded);
      _busy = false;
    });
  }

  void _removePhoto(int idx) {
    setState(() => _photos.removeAt(idx));
  }

  bool get _canContinue => switch (_step) {
    0 => _categoryId != null,
    1 => _description.text.trim().length >= 10,
    2 => _selectedAddress != null,
    _ => true,
  };

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final addr = _selectedAddress!;
      // Backend requires contact_phone — pull from the authed user. Auth
      // is guaranteed at this point because the order create route is
      // gated by middleware in the router.
      final auth = ref.read(authStateProvider);
      final user = auth is AuthAuthenticated ? auth.user : null;
      final order = await ref.read(ordersRepositoryProvider).create({
        'category_id': _categoryId,
        'description': _description.text.trim(),
        if (_photos.isNotEmpty) 'photos': _photos,
        // Address payload — full snapshot from the saved address so the
        // master gets entrance/floor/intercom/note inline with the order.
        'address_id': addr.id,
        'full_address': addr.fullAddress,
        if (addr.lat != null) 'lat': addr.lat,
        if (addr.lng != null) 'lng': addr.lng,
        if (addr.entrance != null && addr.entrance!.isNotEmpty) 'entrance': addr.entrance,
        if (addr.floor != null && addr.floor!.isNotEmpty) 'floor': addr.floor,
        if (addr.intercom != null && addr.intercom!.isNotEmpty) 'intercom': addr.intercom,
        if (addr.note != null && addr.note!.isNotEmpty) 'comment': addr.note,
        // Backend always requires these. Mobile flow uses sensible defaults
        // until we expose the full form (urgency / scheduled_at).
        'contact_phone': user?.phone ?? '',
        'desired_time': 'asap',
        'urgency': 'normal',
        if (widget.preferredMasterId != null)
          'preferred_master_id': widget.preferredMasterId,
      });
      if (mounted) context.pushReplacement('/order/${order.id}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                HmIconButton(
                  icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                  onPressed: () {
                    if (_step != 0) {
                      setState(() => _step--);
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      // Deep-link / push-notification entry with no
                      // back-stack — drop the user on the Home tab.
                      ref.switchTab(context, AppTab.home);
                    }
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: List.generate(3, (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? HmColors.accent : HmColors.surface2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ))),
                  ),
                ),
                const SizedBox(width: 32),
              ]),
            ),
            if (widget.preferredMasterId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: HmColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HmColors.accentBorder),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_pin_circle_rounded,
                        size: 18, color: HmColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.order_for_master_label,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: HmColors.accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                          const SizedBox(height: 1),
                          Text(widget.preferredMasterName ?? '#${widget.preferredMasterId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  color: HmColors.text,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: switch (_step) {
                  0 => _categoryStep(),
                  1 => _describeStep(),
                  _ => _addressStep(),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(HmRadius.pill)),
                  boxShadow: HmShadows.accentGlow,
                ),
                child: SizedBox(
                  width: double.infinity, height: 52,
                  child: FilledButton(
                    onPressed: !_canContinue || _busy ? null : () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _submit();
                      }
                    },
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(_step < 2 ? context.l10n.common_continue : context.l10n.order_create_submit),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryStep() {
    final loc = context.l10n;
    final asyncCategories = ref.watch(_categoriesProvider(widget.preferredMasterId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.order_create_step1_q,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text(loc.order_create_step1_sub, style: const TextStyle(fontSize: 14, color: HmColors.text5)),
        const SizedBox(height: 16),
        Expanded(
          child: asyncCategories.when(
            data: (cats) => GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
              ),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final c = cats[i];
                final selected = _categoryId == c.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(HmRadius.cardLarge),
                  onTap: () => setState(() => _categoryId = c.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? HmColors.accentSoft : HmColors.surface,
                      borderRadius: BorderRadius.circular(HmRadius.cardLarge),
                      border: Border.all(color: selected ? HmColors.accent : HmColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? HmColors.accent : HmColors.accentSoft,
                          ),
                          child: Icon(iconForCategorySlug(c.slug), color: selected ? Colors.black : HmColors.accent, size: 20),
                        ),
                        Text(localizedCategoryName(loc, c),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: HmColors.accent)),
            error: (_, __) => Text(loc.auth_failed_to_load,
                style: const TextStyle(color: HmColors.danger)),
          ),
        ),
      ],
    );
  }

  Widget _describeStep() {
    final loc = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.order_create_step2_title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text(loc.order_create_step2_sub,
            style: const TextStyle(fontSize: 14, color: HmColors.text5)),
        const SizedBox(height: 16),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!, style: const TextStyle(color: HmColors.danger)),
        ),
        TextField(
          controller: _description,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: loc.order_create_desc_hint,
            // Explicit borders for ALL states — without focusedBorder the
            // field falls back to the global pill radius (9999) on tap.
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HmColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HmColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HmColors.accentBorder, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _PhotosPicker(
          photos: _photos,
          max: _maxPhotos,
          busy: _busy,
          onAdd: _pickPhotos,
          onRemove: _removePhoto,
        ),
      ],
    );
  }

  Widget _addressStep() {
    final loc = context.l10n;
    final asyncAddrs = ref.watch(addressesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.order_create_step3_title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text(loc.order_create_step3_sub,
            style: const TextStyle(fontSize: 14, color: HmColors.text5)),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: const TextStyle(color: HmColors.danger)),
          ),
        Expanded(
          child: asyncAddrs.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4),
            ),
            error: (_, __) => Center(
              child: Text(loc.auth_failed_to_load,
                  style: const TextStyle(color: HmColors.danger)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: HmColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: HmColors.border2),
                      ),
                      child: const Icon(Icons.location_off_outlined,
                          size: 28, color: HmColors.text5),
                    ),
                    const SizedBox(height: 12),
                    Text(loc.address_no_addresses,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: HmColors.text4)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => _addNewAddress(),
                        icon: const Icon(Icons.add_location_alt_rounded,
                            size: 16, color: Colors.black),
                        label: Text(loc.address_add_new,
                            style: const TextStyle(color: Colors.black)),
                        style: FilledButton.styleFrom(
                          backgroundColor: HmColors.accent,
                          foregroundColor: Colors.black,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  if (i == list.length) {
                    // Trailing "+ Add new address" tile
                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _addNewAddress,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: HmColors.accentBorder),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: HmColors.accentSoft,
                                shape: BoxShape.circle,
                                border: Border.all(color: HmColors.accentBorder),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 20, color: HmColors.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(loc.address_add_new,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: HmColors.accent)),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: HmColors.accent),
                          ]),
                        ),
                      ),
                    );
                  }
                  final addr = list[i];
                  final selected = _selectedAddress?.id == addr.id;
                  return _AddressTile(
                    address: addr,
                    selected: selected,
                    onTap: () => setState(() => _selectedAddress = addr),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addNewAddress() async {
    await context.push('/addresses/new');
    // Refresh the list after returning — the new address (and the auto-set
    // active id from the form) will both be present.
    ref.invalidate(addressesListProvider);
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });
  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Material(
      color: selected ? HmColors.accentSoft : HmColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? HmColors.accentBorder : HmColors.border2,
            ),
          ),
          child: Row(children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? HmColors.accent : HmColors.text5,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (address.label != null && address.label!.isNotEmpty) ...[
                      Text(address.label!,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: HmColors.text)),
                      const SizedBox(width: 6),
                    ],
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: HmColors.accentSoft,
                          borderRadius: BorderRadius.circular(HmRadius.pill),
                          border: Border.all(color: HmColors.accentBorder),
                        ),
                        child: Text(loc.address_default_badge,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: HmColors.accent,
                                letterSpacing: 0.5)),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(address.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: HmColors.text3,
                          height: 1.35,
                          fontWeight: FontWeight.w500)),
                  if ((address.entrance?.isNotEmpty ?? false) ||
                      (address.floor?.isNotEmpty ?? false) ||
                      (address.intercom?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (address.entrance?.isNotEmpty == true)
                          '${loc.address_entrance}: ${address.entrance}',
                        if (address.floor?.isNotEmpty == true)
                          '${loc.address_floor}: ${address.floor}',
                        if (address.intercom?.isNotEmpty == true)
                          '${loc.address_intercom}: ${address.intercom}',
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: HmColors.text5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
// poke 1778323357

class _PhotosPicker extends StatelessWidget {
  const _PhotosPicker({
    required this.photos,
    required this.max,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });
  final List<String> photos;
  final int max;
  final bool busy;
  final VoidCallback onAdd;
  final void Function(int idx) onRemove;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final canAddMore = photos.length < max && !busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.photo_library_rounded, size: 16, color: HmColors.text4),
          const SizedBox(width: 6),
          Text(loc.order_create_photos_label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${photos.length}/$max',
              style: const TextStyle(fontSize: 12, color: HmColors.text5)),
        ]),
        const SizedBox(height: 6),
        Text(loc.order_create_photos_hint,
            style: const TextStyle(fontSize: 12, color: HmColors.text5, height: 1.35)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < photos.length; i++)
            _PhotoTile(dataUri: photos[i], onRemove: () => onRemove(i)),
          if (canAddMore) _AddPhotoTile(onTap: onAdd),
        ]),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.dataUri, required this.onRemove});
  final String dataUri;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // dataUri is `data:image/jpeg;base64,XYZ…` — split off the prefix.
    final commaIdx = dataUri.indexOf(',');
    final b64 = commaIdx >= 0 ? dataUri.substring(commaIdx + 1) : dataUri;
    final bytes = base64Decode(b64);
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, width: 84, height: 84, fit: BoxFit.cover, gaplessPlayback: true),
      ),
      Positioned(
        top: 4, right: 4,
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: HmColors.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 84, height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HmColors.border, style: BorderStyle.solid, width: 1.2),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add_a_photo_rounded, color: HmColors.text4, size: 22),
        ),
      ),
    );
  }
}
