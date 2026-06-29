import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/common/widgets/app_text_field.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/auth/repositories/auth_repository.dart';
import 'package:itez_mobile/features/profile/bloc/profile_bloc.dart';
import 'package:itez_mobile/features/profile/repositories/profile_repository.dart';

@RoutePage()
class ChangePasswordPage extends StatefulWidget implements AutoRouteWrapper {
  const ChangePasswordPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(
        profileRepository: locator<ProfileRepository>(),
        authRepository: locator<AuthRepository>(),
        auth: context.read<AuthBloc>(),
      ),
      child: this,
    );
  }

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ProfileBloc>().add(ProfileChangePassword(
          current: _current.text,
          next: _next.text,
          confirm: _confirm.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Изменить пароль')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.passwordChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Пароль изменён')),
            );
            context.router.maybePop();
          } else if (state.status == ProfileStatus.failed && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          final errs = state.errors ?? const <String, List<String>>{};
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _current,
                    label: 'Текущий пароль',
                    obscure: true,
                    errorText: errs['current_password']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _next,
                    label: 'Новый пароль',
                    obscure: true,
                    errorText: errs['password']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _confirm,
                    label: 'Повторите новый пароль',
                    obscure: true,
                  ),
                  SizedBox(height: 20.h),
                  AppPrimaryButton(
                    label: 'Сохранить',
                    loading: state.isSaving,
                    onPressed: _submit,
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
