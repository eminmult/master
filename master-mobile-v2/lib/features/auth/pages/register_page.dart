import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/common/widgets/app_text_field.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';

/// Регистрация клиента. Регистрация мастера — отдельный длинный wizard
/// в Phase 1.1 (категория, описание, опыт, город…), оттуда же позже
/// привяжется онбординг "Я мастер".
@RoutePage()
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthRegisterClientRequested(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim().isEmpty
                ? null
                : _lastName.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            password: _password.text,
            passwordConfirmation: _passwordConfirm.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.router.replaceAll([const MainRoute()]);
          }
          if (state is AuthFailed && state.user == null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          final failed = state is AuthFailed ? state : null;
          final errors = failed?.errors ?? const <String, List<String>>{};
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _firstName,
                    label: 'Имя',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    errorText: errors['first_name']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _lastName,
                    label: 'Фамилия (опционально)',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    errorText: errors['last_name']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _phone,
                    label: 'Телефон',
                    hint: '+99450...',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    errorText: errors['phone']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _email,
                    label: 'E-mail (опционально)',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: errors['email']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _password,
                    label: 'Пароль',
                    hint: 'буквы + цифры, не менее 8',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    errorText: errors['password']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _passwordConfirm,
                    label: 'Повторите пароль',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: 20.h),
                  AppPrimaryButton(
                    label: 'Создать аккаунт',
                    loading: loading,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: TextButton(
                      onPressed: () => context.router.maybePop(),
                      child: Text(
                        'Уже есть аккаунт? Войти',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
