import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/wallet/data/wallet_repository.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';

final _balanceProvider = FutureProvider.autoDispose<WalletBalance>((ref) =>
    ref.watch(walletRepositoryProvider).balance());
final _txProvider = FutureProvider.autoDispose<List<WalletTransactionRow>>((ref) =>
    ref.watch(walletRepositoryProvider).transactions());
final _withdrawalsProvider = FutureProvider.autoDispose<List<WithdrawalRow>>((ref) =>
    ref.watch(walletRepositoryProvider).withdrawals());

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final balance = ref.watch(_balanceProvider);
    final tx = ref.watch(_txProvider);
    final wd = ref.watch(_withdrawalsProvider);
    return Scaffold(
      backgroundColor: HmColors.bg,
      appBar: AppBar(
        backgroundColor: HmColors.bg,
        elevation: 0,
        title: Text(loc.wallet_title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        color: HmColors.accent,
        onRefresh: () async {
          ref.invalidate(_balanceProvider);
          ref.invalidate(_txProvider);
          ref.invalidate(_withdrawalsProvider);
          await Future.wait([
            ref.read(_balanceProvider.future),
            ref.read(_txProvider.future),
            ref.read(_withdrawalsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            balance.when(
              loading: () => const _BalanceCardSkeleton(),
              error: (e, _) => Text(e.toString()),
              data: (b) => _BalanceCard(amountCents: b.cents, currency: b.currency),
            ),
            const SizedBox(height: 22),
            wd.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : _Section(
                      title: loc.wallet_withdrawals,
                      child: Column(children: [
                        for (final w in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _WithdrawalRow(row: w, onCancel: () async {
                              try {
                                await ref.read(walletRepositoryProvider).cancelWithdrawal(w.id);
                                ref.invalidate(_withdrawalsProvider);
                                ref.invalidate(_balanceProvider);
                              } on ApiException catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                              }
                            }),
                          ),
                      ]),
                    ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: loc.wallet_transactions,
              child: tx.when(
                loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(color: HmColors.accent))),
                error: (e, _) => Text(e.toString()),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text(loc.wallet_empty,
                            style: const TextStyle(color: HmColors.text4, fontSize: 13))),
                      )
                    : Column(children: [
                        for (final t in list)
                          _TxRow(row: t),
                      ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.amountCents, required this.currency});
  final int amountCents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final amount = (amountCents / 100).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [HmColors.accent.withOpacity(0.12), HmColors.accent.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: HmColors.accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(loc.wallet_balance,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: HmColors.text4)),
        const SizedBox(height: 8),
        Text('$amount $currency',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: amountCents <= 0 ? null : () => _openWithdraw(context, amountCents),
            icon: const Icon(Icons.north_east_rounded, size: 16, color: Colors.black),
            label: Text(loc.wallet_withdraw_cta,
                style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              backgroundColor: HmColors.accent,
              shape: const StadiumBorder(),
              disabledBackgroundColor: HmColors.surface2,
            ),
          ),
        ),
      ]),
    );
  }

  void _openWithdraw(BuildContext context, int maxCents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => _WithdrawSheet(maxCents: maxCents),
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: HmColors.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: HmColors.text4)),
      ),
      child,
    ]);
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.row});
  final WalletTransactionRow row;
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final amount = (row.amountCents / 100).toStringAsFixed(2);
    final pos = row.amountCents > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: HmColors.surface2,
        border: Border.all(color: HmColors.border2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_kindLabel(row.kind, loc), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Row(children: [
            if (row.orderId != null) ...[
              GestureDetector(
                onTap: () => context.push('/order/${row.orderId}'),
                child: Text('#${row.orderId}', style: const TextStyle(fontSize: 11.5, color: HmColors.accent, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
            Text(_fmt(row.createdAt), style: const TextStyle(fontSize: 11, color: HmColors.text4)),
          ]),
        ])),
        Text('${pos ? '+' : ''}$amount ${row.currency}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: pos ? const Color(0xFF22C55E) : const Color(0xFFF87171),
            )),
      ]),
    );
  }

  static String _kindLabel(String k, AppLocalizations loc) {
    switch (k) {
      case 'callout_fee':         return loc.wallet_kind_callout_fee;
      case 'callout_refund':      return loc.wallet_kind_callout_refund;
      case 'master_penalty':      return loc.wallet_kind_master_penalty;
      case 'withdrawal_hold':     return loc.wallet_kind_withdrawal_hold;
      case 'withdrawal_paid':     return loc.wallet_kind_withdrawal_paid;
      case 'withdrawal_restore':  return loc.wallet_kind_withdrawal_restore;
      case 'manual_adjust':       return loc.wallet_kind_manual_adjust;
      default:                    return k;
    }
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow({required this.row, required this.onCancel});
  final WithdrawalRow row;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Color color;
    switch (row.status) {
      case 'pending':   color = const Color(0xFFF59E0B); break;
      case 'approved':
      case 'paid':      color = const Color(0xFF22C55E); break;
      default:          color = const Color(0xFFF87171);
    }
    final amount = (row.amountCents / 100).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: HmColors.surface2,
        border: Border.all(color: HmColors.border2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('−$amount ${row.currency}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFF87171))),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withOpacity(0.45))),
              child: Text(_statusLabel(row.status, loc),
                  style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w700)),
            ),
            if (row.iban != null) Text(_maskIban(row.iban!),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: HmColors.text4)),
          ]),
        ])),
        if (row.status == 'pending')
          TextButton(
            onPressed: onCancel,
            child: Text(loc.common_cancel, style: const TextStyle(color: HmColors.text3)),
          ),
      ]),
    );
  }

  static String _statusLabel(String s, AppLocalizations loc) {
    switch (s) {
      case 'pending':   return loc.wallet_status_pending;
      case 'approved':  return loc.wallet_status_approved;
      case 'paid':      return loc.wallet_status_paid;
      case 'rejected':  return loc.wallet_status_rejected;
      case 'cancelled': return loc.wallet_status_cancelled;
    }
    return s;
  }
  static String _maskIban(String iban) =>
      iban.length > 8 ? '${iban.substring(0, 4)} •••• ${iban.substring(iban.length - 4)}' : iban;
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.maxCents});
  final int maxCents;
  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _amount = TextEditingController();
  final _iban = TextEditingController();
  final _holder = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _iban.dispose();
    _holder.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amt = double.tryParse(_amount.text.trim());
    final iban = _iban.text.trim();
    final holder = _holder.text.trim();
    if (amt == null || amt <= 0) return;
    if (iban.length < 6 || holder.isEmpty) return;
    final amountCents = (amt * 100).round();
    if (amountCents > widget.maxCents) {
      setState(() => _error = AppLocalizations.of(context)!.wallet_amount_exceeds);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(walletRepositoryProvider).requestWithdrawal(
            amountCents: amountCents,
            iban: iban.replaceAll(RegExp(r'\s+'), ''),
            holder: holder,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(
          width: 38, height: 4,
          decoration: BoxDecoration(color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 14),
        Text(loc.wallet_withdraw_title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        _Input(controller: _amount, label: '${loc.wallet_amount_label} (AZN)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        _Input(controller: _iban, label: 'IBAN', hint: 'AZxx xxxx xxxx xxxx xxxx xxxx'),
        _Input(controller: _holder, label: loc.wallet_holder_label),
        _Input(controller: _note, label: loc.wallet_note_label),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12.5)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 48,
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: HmColors.accent, foregroundColor: Colors.black,
              shape: const StadiumBorder(),
              disabledBackgroundColor: HmColors.surface2,
            ),
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(loc.wallet_withdraw_submit,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.label, this.hint, this.keyboardType});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HmColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HmColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HmColors.accentBorder, width: 1.4)),
        ),
      ),
    );
  }
}
