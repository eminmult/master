import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/common/widgets/app_text_field.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/auth/repositories/auth_repository.dart';

/// Сброс пароля по токену из e-mail. Открывается по deep-link
/// `itez://reset-password?token=…&login=…` (или через web-роутер при
/// open в браузере).
@RoutePage()
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    @QueryParam('token') this.token,
    @QueryParam('login') this.login,
  });

  final String? token;
  final String? login;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final TextEditingController _login;
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _sending = false;
  Map<String, List<String>>? _errors;
  String? _error;

  @override
  void initState() {
    super.initState();
    _login = TextEditingController(text: widget.login ?? '');
    _token = TextEditingController(text: widget.token ?? '');
  }

  @override
  void dispose() {
    _login.dispose();
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _errors = null;
      _error = null;
    });
    try {
      await locator<AuthRepository>().resetPassword(
        login: _login.text.trim(),
        token: _token.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirm.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль обновлён, войдите снова')),
      );
      await context.router.replaceAll([const LoginRoute()]);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errors = e.errors;
        _error = e.message;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message ?? 'Не удалось обновить пароль';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errs = _errors ?? const <String, List<String>>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пароль')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w, vertical: AppSpacing.lg.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(_error!,
                    style: TextStyle(color: AppColors.danger, fontSize: 13.sp)),
                SizedBox(height: 12.h),
              ],
              AppTextField(
                controller: _login,
                label: 'E-mail или телефон',
                errorText: errs['login']?.first,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _token,
                label: 'Токен из письма',
                errorText: errs['token']?.first,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _password,
                label: 'Новый пароль',
                obscure: true,
                errorText: errs['password']?.first,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _confirm,
                label: 'Повторите пароль',
                obscure: true,
              ),
              SizedBox(height: AppSpacing.lg.h),
              AppPrimaryButton(
                label: 'Сохранить',
                loading: _sending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
