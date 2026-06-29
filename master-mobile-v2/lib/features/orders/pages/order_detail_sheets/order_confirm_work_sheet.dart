import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';

/// Bottom-sheet мастера «Подтвердить выполнение работы»:
/// финальная цена + опциональная дата + комментарий.
class OrderConfirmWorkSheet extends StatefulWidget {
  const OrderConfirmWorkSheet({
    super.key,
    required this.onSubmit,
    this.initialPrice,
  });
  final double? initialPrice;
  final void Function(double price, DateTime? date, String? note) onSubmit;

  @override
  State<OrderConfirmWorkSheet> createState() =>
      _OrderConfirmWorkSheetState();
}

class _OrderConfirmWorkSheetState extends State<OrderConfirmWorkSheet> {
  late final TextEditingController _price;
  final _note = TextEditingController();
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
      text: widget.initialPrice == null
          ? ''
          : widget.initialPrice!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
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
              l.order_action_confirm_work,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.order_confirm_work_hint,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.text4,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.order_confirm_work_price,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.text4,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: '0',
                suffixText: '₼',
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(focused: true),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.order_confirm_work_date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.text4,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded, size: 16),
              label: Text(
                _date == null
                    ? l.order_confirm_work_time
                    : _date!.toLocal().toString().substring(0, 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l.order_confirm_work_hint,
                counterText: '',
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(focused: true),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {
                  final price = double.tryParse(_price.text.trim());
                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.order_confirm_work_price)),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  widget.onSubmit(
                    price,
                    _date,
                    _note.text.trim().isEmpty ? null : _note.text.trim(),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(l.order_confirm_work_send),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: focused ? AppColors.accent : AppColors.border,
          width: focused ? 1.5 : 1,
        ),
      );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }
}
