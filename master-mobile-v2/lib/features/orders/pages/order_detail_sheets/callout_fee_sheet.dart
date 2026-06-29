import 'package:flutter/material.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

/// Bottom-sheet с превью callout fee + кнопкой "Оплатить".
/// Возвращает true, если оплата прошла успешно — caller должен
/// перезагрузить заказ.
Future<bool> showCalloutFeeSheet(
  BuildContext context, {
  required int orderId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.cardLarge),
      ),
    ),
    builder: (_) => _CalloutFeeSheet(orderId: orderId),
  );
  return result == true;
}

class _CalloutFeeSheet extends StatefulWidget {
  const _CalloutFeeSheet({required this.orderId});
  final int orderId;
  @override
  State<_CalloutFeeSheet> createState() => _CalloutFeeSheetState();
}

class _CalloutFeeSheetState extends State<_CalloutFeeSheet> {
  Map<String, dynamic>? _pricing;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await locator<OrderRepository>().calloutFeePreview(widget.orderId);
      if (mounted) setState(() => _pricing = p);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await locator<OrderRepository>().payCallout(widget.orderId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _paying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final amountCents = parseIntOrNull(_pricing?['amount_cents']) ?? 2500;
    final amount = (amountCents / 100).toStringAsFixed(0);
    final currency = _pricing?['currency']?.toString() ?? 'AZN';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.callout_modal_title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else ...[
            Text(
              '$amount $currency',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.callout_modal_subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.text4,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (_pricing != null) _SplitPreview(pricing: _pricing!),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _paying ? null : _pay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  shape: const StadiumBorder(),
                  disabledBackgroundColor: AppColors.surface2,
                  disabledForegroundColor: AppColors.text5,
                ),
                child: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      )
                    : Text(
                        l.callout_pay_btn(amount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Показывает раздел денег: 19 / 6 (master / platform), если бэкенд их
/// прислал в preview.
class _SplitPreview extends StatelessWidget {
  const _SplitPreview({required this.pricing});
  final Map<String, dynamic> pricing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final masterCents = parseIntOrNull(pricing['master_share_cents']);
    final platformCents = parseIntOrNull(pricing['platform_share_cents']);
    if (masterCents == null && platformCents == null) {
      return const SizedBox.shrink();
    }
    final currency = pricing['currency']?.toString() ?? 'AZN';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          if (masterCents != null)
            _SplitRow(
              label: l.callout_split_master,
              amount: '${(masterCents / 100).toStringAsFixed(0)} $currency',
            ),
          if (masterCents != null && platformCents != null)
            const SizedBox(height: 6),
          if (platformCents != null)
            _SplitRow(
              label: l.callout_split_platform,
              amount: '${(platformCents / 100).toStringAsFixed(0)} $currency',
            ),
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({required this.label, required this.amount});
  final String label;
  final String amount;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.text3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
