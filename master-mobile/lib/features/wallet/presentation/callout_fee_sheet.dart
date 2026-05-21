import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/payment/data/payment_cards_repository.dart';
import 'package:master_mobile/features/wallet/data/wallet_repository.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';

/// Returns true if payment succeeded and order should be reloaded.
Future<bool> showCalloutFeeSheet(BuildContext context, {required int orderId}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: HmColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
    ),
    builder: (_) => _CalloutFeeSheet(orderId: orderId),
  );
  return result == true;
}

class _CalloutFeeSheet extends ConsumerStatefulWidget {
  const _CalloutFeeSheet({required this.orderId});
  final int orderId;
  @override
  ConsumerState<_CalloutFeeSheet> createState() => _CalloutFeeSheetState();
}

class _CalloutFeeSheetState extends ConsumerState<_CalloutFeeSheet> {
  CalloutFeePricing? _pricing;
  bool _loading = true;
  int? _selectedCardId;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ref.read(calloutFeeRepositoryProvider).preview(widget.orderId);
      if (mounted) setState(() => _pricing = p);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pay(int cardId) async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await ref.read(calloutFeeRepositoryProvider).pay(widget.orderId, paymentCardId: cardId);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cards = ref.watch(paymentCardsListProvider);

    final amount = ((_pricing?.amountCents ?? 2500) / 100).toStringAsFixed(0);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(
            width: 38, height: 4,
            decoration: BoxDecoration(color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 14),
          Text(loc.callout_modal_title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text('$amount AZN', textAlign: TextAlign.center, style: HmTextStyles.displayHero),
          const SizedBox(height: 6),
          Text(loc.callout_modal_subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: HmColors.text4, height: 1.4)),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator(color: HmColors.accent)))
          else
            cards.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator(color: HmColors.accent))),
              error: (e, _) => Text(e.toString(), style: const TextStyle(color: Color(0xFFF87171))),
              data: (list) {
                if (list.isEmpty) {
                  return Column(children: [
                    const Icon(Icons.credit_card_off_rounded, size: 36, color: HmColors.text5),
                    const SizedBox(height: 6),
                    Text(loc.callout_no_cards,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: HmColors.text4)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, height: 46,
                      child: FilledButton(
                        onPressed: () { Navigator.pop(context, false); context.push('/payment-methods'); },
                        style: FilledButton.styleFrom(
                          backgroundColor: HmColors.accent, foregroundColor: Colors.black,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(loc.callout_add_card_cta,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]);
                }
                _selectedCardId ??= list.firstWhere(
                  (c) => c.isDefault,
                  orElse: () => list.first,
                ).id;
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCardId = c.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: HmColors.surface2,
                            border: Border.all(
                              color: _selectedCardId == c.id ? HmColors.accent : HmColors.border2,
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _selectedCardId == c.id ? HmColors.accent : HmColors.border, width: 2),
                                color: _selectedCardId == c.id ? HmColors.accent : Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(_brandLabel(c.brand), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(width: 8),
                            Text('•••• ${c.last4}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: HmColors.text3)),
                            const Spacer(),
                            Text('${c.expMonth.toString().padLeft(2, '0')}/${c.expYear.toString().substring(c.expYear.toString().length - 2)}',
                                style: const TextStyle(fontSize: 11, color: HmColors.text4)),
                          ]),
                        ),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12.5)),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: FilledButton(
                      onPressed: (_paying || _selectedCardId == null) ? null : () => _pay(_selectedCardId!),
                      style: FilledButton.styleFrom(
                        backgroundColor: HmColors.accent, foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        disabledBackgroundColor: HmColors.surface2,
                        disabledForegroundColor: HmColors.text5,
                      ),
                      child: _paying
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(loc.callout_pay_btn(amount),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]);
              },
            ),
        ],
      ),
    );
  }

  String _brandLabel(String b) {
    if (b == 'visa') return 'Visa';
    if (b == 'mastercard') return 'Mastercard';
    if (b == 'amex') return 'Amex';
    return b;
  }
}
