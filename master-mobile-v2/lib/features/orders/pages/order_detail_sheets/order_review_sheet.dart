import 'package:flutter/material.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';

/// Bottom-sheet для оставления отзыва: 5 звёзд + опциональный комментарий.
class OrderReviewSheet extends StatefulWidget {
  const OrderReviewSheet({super.key, required this.onSubmit});

  final void Function(int rating, String? comment) onSubmit;

  @override
  State<OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<OrderReviewSheet> {
  int _rating = 5;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final txt = _controller.text.trim();
    widget.onSubmit(_rating, txt.isEmpty ? null : txt);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l.review_leave,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 36,
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled ? Colors.amber : AppColors.text5,
                    ),
                    onPressed: () => setState(() => _rating = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 3,
                maxLength: 500,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l.review_placeholder,
                  hintStyle: const TextStyle(color: AppColors.text5),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(l.common_send),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
