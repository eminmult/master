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
class EditProfilePage extends StatefulWidget implements AutoRouteWrapper {
  const EditProfilePage({super.key});

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
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthBloc>().state.user;
    _first = TextEditingController(text: u?.firstName);
    _last = TextEditingController(text: u?.lastName);
    _email = TextEditingController(text: u?.email);
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    context.read<ProfileBloc>().add(ProfileUpdateClient(
          firstName: _first.text.trim(),
          lastName: _last.text.trim().isEmpty ? null : _last.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Личные данные')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сохранено')),
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
                    controller: _first,
                    label: 'Имя',
                    errorText: errs['first_name']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _last,
                    label: 'Фамилия',
                    errorText: errs['last_name']?.first,
                  ),
                  SizedBox(height: 12.h),
                  AppTextField(
                    controller: _email,
                    label: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    errorText: errs['email']?.first,
                  ),
                  SizedBox(height: 20.h),
                  AppPrimaryButton(
                    label: 'Сохранить',
                    loading: state.isSaving,
                    onPressed: _save,
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
