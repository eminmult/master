import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/addresses/data/active_address_controller.dart';
import 'package:master_mobile/features/addresses/data/addresses_repository.dart';

/// Bottom sheet that lists all saved addresses with a tick on the active
/// one and an "Add new address" CTA. Mirrors the Wolt delivery picker.
Future<void> showAddressPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HmColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
    ),
    builder: (_) => const _AddressPickerSheet(),
  );
}

class _AddressPickerSheet extends ConsumerWidget {
  const _AddressPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final addressesAsync = ref.watch(addressesListProvider);
    final activeId = ref.watch(activeAddressIdProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: HmColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, size: 18, color: HmColors.accent),
                const SizedBox(width: 8),
                Text(loc.address_pick_title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: HmColors.text4),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: addressesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: HmColors.accent)),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(loc.home_load_error,
                        style: const TextStyle(color: HmColors.text4)),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                      child: Column(
                        children: [
                          const Icon(Icons.location_off_outlined,
                              size: 36, color: HmColors.text5),
                          const SizedBox(height: 10),
                          Text(loc.address_no_addresses,
                              style: const TextStyle(color: HmColors.text4),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final addr = list[i];
                      final selected = activeId == addr.id ||
                          (activeId == null && addr.isDefault);
                      return _AddressTile(
                        address: addr,
                        selected: selected,
                        onTap: () async {
                          await ref
                              .read(activeAddressIdProvider.notifier)
                              .setActive(addr.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/addresses/new');
                  },
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: Text(loc.address_add_new),
                  style: FilledButton.styleFrom(
                    backgroundColor: HmColors.accent,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? HmColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? HmColors.accentBorder : HmColors.border2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
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
                              fontSize: 13, fontWeight: FontWeight.w800, color: HmColors.text)),
                      const SizedBox(width: 6),
                    ],
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HmColors.accentSoft,
                          borderRadius: BorderRadius.circular(HmRadius.pill),
                          border: Border.all(color: HmColors.accentBorder),
                        ),
                        child: Text(loc.address_default_badge,
                            style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w800, color: HmColors.accent, letterSpacing: 0.5)),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(address.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: HmColors.text3, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
