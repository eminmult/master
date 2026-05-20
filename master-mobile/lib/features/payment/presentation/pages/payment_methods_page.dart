import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/payment/data/payment_cards_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// List of saved payment cards. Add / set-default / delete. The full card
/// number is NEVER stored — the add flow keeps only brand+last4+expiry+holder.
class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final asyncCards = ref.watch(paymentCardsListProvider);

    return Scaffold(
      backgroundColor: HmColors.bg2,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(children: [
              HmIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                small: true, flat: true,
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/profile'),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(loc.profile_payment_methods,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
              ),
            ]),
          ),
          Expanded(
            child: asyncCards.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: HmColors.accent, strokeWidth: 2.4),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(loc.auth_failed_to_load,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: HmColors.danger)),
                ),
              ),
              data: (cards) {
                if (cards.isEmpty) {
                  return _EmptyState();
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    for (final c in cards) ...[
                      _CardRow(card: c),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
          // Sticky "Add card" button at the bottom
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 12 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: FilledButton.icon(
                onPressed: () => context.push('/payment-methods/new'),
                icon: const Icon(Icons.add_card_rounded, size: 16, color: Colors.black),
                label: Text(loc.payment_add_card,
                    style: const TextStyle(color: Colors.black)),
                style: FilledButton.styleFrom(
                  backgroundColor: HmColors.accent,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.credit_card_off_rounded,
              size: 36, color: HmColors.text5),
          const SizedBox(height: 10),
          Text(loc.payment_no_cards,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13.5,
                  color: HmColors.text4,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _CardRow extends ConsumerWidget {
  const _CardRow({required this.card});
  final PaymentCard card;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: card.isDefault
              ? const [Color(0x1FFFFF00), Color(0x05FFFF00)]
              : const [Color(0x0DFFFFFF), Color(0x03FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(HmRadius.cardLarge),
        border: Border.all(
            color: card.isDefault ? HmColors.accentBorder : HmColors.border2),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(children: [
        _BrandLogo(brand: card.brand),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Text('•••• ${card.last4}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: HmColors.text,
                        letterSpacing: 1.2)),
                if (card.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: HmColors.accentSoft,
                      borderRadius: BorderRadius.circular(HmRadius.pill),
                      border: Border.all(color: HmColors.accentBorder),
                    ),
                    child: Text(loc.profile_default,
                        style: const TextStyle(
                            fontSize: 9.5,
                            color: HmColors.accent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Row(children: [
                if (card.holderName != null && card.holderName!.isNotEmpty) ...[
                  Flexible(
                    child: Text(card.holderName!.toUpperCase(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: HmColors.text4,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                    '${card.expMonth.toString().padLeft(2, '0')}/${card.expYear.toString().substring(2)}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: HmColors.text5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
              ]),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              size: 18, color: HmColors.text4),
          color: HmColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HmRadius.card)),
          itemBuilder: (_) => [
            if (!card.isDefault)
              PopupMenuItem(
                value: 'default',
                child: Row(children: [
                  const Icon(Icons.star_outline_rounded,
                      size: 16, color: HmColors.accent),
                  const SizedBox(width: 8),
                  Text(loc.payment_set_default),
                ]),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_outline_rounded,
                    size: 16, color: HmColors.danger),
                const SizedBox(width: 8),
                Text(loc.payment_delete_card,
                    style: const TextStyle(color: HmColors.danger)),
              ]),
            ),
          ],
          onSelected: (v) async {
            try {
              if (v == 'default') {
                await ref
                    .read(paymentCardsRepositoryProvider)
                    .setDefault(card.id);
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: HmColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HmRadius.cardLarge)),
                    title: Text(loc.payment_delete_confirm,
                        style: const TextStyle(color: HmColors.text)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(loc.cancel,
                            style: const TextStyle(color: HmColors.text3)),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                            backgroundColor: HmColors.danger,
                            foregroundColor: Colors.white),
                        child: Text(loc.payment_delete_card),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                await ref
                    .read(paymentCardsRepositoryProvider)
                    .destroy(card.id);
              }
              ref.invalidate(paymentCardsListProvider);
            } on ApiException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.message),
                  backgroundColor: HmColors.danger,
                ));
              }
            }
          },
        ),
      ]),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand});
  final String brand;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (brand) {
      'visa' => ('VISA', const Color(0xFF1A1F71)),
      'mastercard' => ('MC', const Color(0xFFEB001B)),
      'amex' => ('AMEX', const Color(0xFF2E77BB)),
      _ => ('CARD', HmColors.text5),
    };
    return Container(
      width: 56, height: 36,
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HmColors.border2),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: TextStyle(
              fontSize: brand == 'mastercard' ? 13 : 11,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.8)),
    );
  }
}
