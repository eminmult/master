import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';

/// Универсальный TextField с лейблом сверху, иконкой и поддержкой ошибки.
/// Используется во всех формах — авторизация, создание заказа, профиль.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6.h),
        ],
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.obscure ? _obscured : false,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon:
                widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility : Icons.visibility_off,
                      size: 20.r,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : widget.suffixIcon,
            counterText: '',
          ),
        ),
        if (widget.errorText != null) ...[
          SizedBox(height: 6.h),
          Text(
            widget.errorText!,
            style: TextStyle(color: AppColors.danger, fontSize: 12.sp),
          ),
        ],
      ],
    );
  }
}
