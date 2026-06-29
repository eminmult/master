import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/common/widgets/app_text_field.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/auth/repositories/auth_repository.dart';

/// Запрос ссылки на сброс пароля.
/// Backend всегда отвечает 200 (не leak'ает существование email/телефона),
/// поэтому UI всегда показывает «если аккаунт есть — мы отправили ссылку».
@RoutePage()
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _login = TextEditingController();
  bool _sending = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await locator<AuthRepository>().forgotPassword(_login.text.trim());
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message ?? 'Не удалось отправить';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сброс пароля')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w, vertical: AppSpacing.lg.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_sent) ...[
                Icon(Icons.mark_email_read_rounded,
                    size: 64.r, color: AppColors.accent),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  'Если такой аккаунт существует — ссылка для сброса '
                  'отправлена на e-mail или телефон.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: AppColors.text3,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
                AppPrimaryButton(
                  label: 'Назад ко входу',
                  onPressed: () => context.router.maybePop(),
                ),
              ] else ...[
                Text(
                  'Восстановить доступ',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Введите e-mail или телефон. Мы отправим ссылку.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.text4,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
                AppTextField(
                  controller: _login,
                  label: 'E-mail или телефон',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _error,
                ),
                SizedBox(height: AppSpacing.lg.h),
                AppPrimaryButton(
                  label: 'Отправить ссылку',
                  loading: _sending,
                  onPressed: _submit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
