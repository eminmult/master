import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/addresses/data/active_address_controller.dart';
import 'package:master_mobile/features/addresses/data/addresses_repository.dart';
import 'package:master_mobile/features/addresses/presentation/address_map_picker.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Simple form for adding a new delivery / service address. No map pin yet —
/// `lat`/`lng` are left null and can be filled in by a later geocoding pass
/// when the user picks a category and submits an order. The label, entrance,
/// floor and intercom fields mirror the website's profile address dialog.
class AddAddressPage extends ConsumerStatefulWidget {
  const AddAddressPage({super.key});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _full = TextEditingController();
  final _entrance = TextEditingController();
  final _floor = TextEditingController();
  final _intercom = TextEditingController();
  final _note = TextEditingController();
  bool _isDefault = false;
  bool _busy = false;
  String? _error;

  // Coordinates picked on the map. Saved with the address so subsequent
  // distance-sort requests on /masters can use them.
  double? _pickedLat;
  double? _pickedLng;

  @override
  void dispose() {
    _label.dispose();
    _full.dispose();
    _entrance.dispose();
    _floor.dispose();
    _intercom.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final addr = await ref.read(addressesRepositoryProvider).create(
            label: _label.text.trim(),
            fullAddress: _full.text.trim(),
            lat: _pickedLat,
            lng: _pickedLng,
            entrance: _entrance.text.trim(),
            floor: _floor.text.trim(),
            intercom: _intercom.text.trim(),
            note: _note.text.trim(),
            isDefault: _isDefault,
          );
      // Refresh the list and switch to the just-created address.
      ref.invalidate(addressesListProvider);
      await ref.read(activeAddressIdProvider.notifier).setActive(addr.id);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.l10n.home_load_error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                HmIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  small: true,
                  flat: true,
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
                Expanded(
                  child: Center(
                    child: Text(loc.address_add_new,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  ),
                ),
                const SizedBox(width: 32),
              ]),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    TextFormField(
                      controller: _label,
                      decoration: InputDecoration(
                        labelText: loc.address_label_field,
                        hintText: loc.address_label_hint,
                        prefixIcon: const Icon(Icons.bookmark_outline_rounded,
                            size: 18, color: HmColors.text4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _full,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: loc.address_full_field,
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            size: 18, color: HmColors.text4),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? loc.address_full_required : null,
                    ),
                    const SizedBox(height: 14),
                    // Map picker — taps + search both write back into the
                    // _full text field and stash lat/lng for create().
                    AddressMapPicker(
                      initialLat: _pickedLat,
                      initialLng: _pickedLng,
                      onPick: (lat, lng, address) {
                        setState(() {
                          _pickedLat = lat;
                          _pickedLng = lng;
                          _full.text = address;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _entrance,
                          decoration: InputDecoration(
                            labelText: loc.address_entrance,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _floor,
                          decoration: InputDecoration(
                            labelText: loc.address_floor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _intercom,
                          decoration: InputDecoration(
                            labelText: loc.address_intercom,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Free-text note for the master — gate code, "ring
                    // twice", "second door on the left", etc. Optional.
                    TextFormField(
                      controller: _note,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: loc.address_note_for_master,
                        hintText: loc.address_note_hint,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 36),
                          child: Icon(Icons.sticky_note_2_outlined,
                              size: 18, color: HmColors.text4),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => setState(() => _isDefault = !_isDefault),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDefault ? HmColors.accentSoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isDefault ? HmColors.accentBorder : HmColors.border2,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            _isDefault
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: _isDefault ? HmColors.accent : HmColors.text5,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(loc.address_set_default,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _isDefault ? HmColors.text : HmColors.text3)),
                          ),
                        ]),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x1AEF4444),
                          border: Border.all(color: const Color(0x33EF4444)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: HmColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: HmColors.danger, fontSize: 12.5)),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: HmColors.accent,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: HmColors.accentSoft,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.black),
                              )
                            : Text(loc.address_save),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// trigger 1778312839
// trigger
