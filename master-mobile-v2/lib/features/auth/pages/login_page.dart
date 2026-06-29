import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/common/widgets/app_text_field.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            login: _login.text.trim(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
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
                  Text(
                    'Добро пожаловать',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Войдите по телефону или e-mail',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  AppTextField(
                    controller: _login,
                    label: 'Телефон или e-mail',
                    hint: '+99450...  или  you@itez.app',
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    errorText: errors['login']?.first,
                  ),
                  SizedBox(height: 14.h),
                  AppTextField(
                    controller: _password,
                    label: 'Пароль',
                    hint: 'не менее 8 символов',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    errorText: errors['password']?.first,
                    onSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.router
                          .push(const ForgotPasswordRoute()),
                      child: const Text('Забыли пароль?'),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  AppPrimaryButton(
                    label: 'Войти',
                    loading: loading,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Нет аккаунта? ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.router
                            .push(const RegisterRolePickerRoute()),
                        child: Text(
                          'Создать',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ],
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
