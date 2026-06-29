import 'package:flutter/material.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';

/// Bottom-sheet «Отмена заказа» с textarea для причины (опционально).
class OrderCancelSheet extends StatefulWidget {
  const OrderCancelSheet({super.key, required this.onSubmit});
  final void Function(String? reason) onSubmit;

  @override
  State<OrderCancelSheet> createState() => _OrderCancelSheetState();
}

class _OrderCancelSheetState extends State<OrderCancelSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
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
            const SizedBox(height: 16),
            Text(
              l.order_cancel_confirm_title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.order_cancel_confirm_body,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text4,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.order_cancel_reason_label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.text4,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ctrl,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l.order_cancel_reason_hint,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border2),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(l.order_cancel_keep),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final reason = _ctrl.text.trim();
                      Navigator.of(context).pop();
                      widget.onSubmit(reason.isEmpty ? null : reason);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(l.order_cancel_btn),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
