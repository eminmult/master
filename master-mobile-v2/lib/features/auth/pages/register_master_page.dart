import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/common/widgets/app_text_field.dart';
import 'package:itez_mobile/common/widgets/hm_pill_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/categories/bloc/categories_bloc.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';

/// Регистрация мастера — длинная анкета:
/// имя/фамилия, телефон, e-mail, пароль, город, описание, опыт, категории.
/// Категории — мульти-выбор pills, минимум одна.
@RoutePage()
class RegisterMasterPage extends StatefulWidget implements AutoRouteWrapper {
  const RegisterMasterPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesBloc(locator<CategoryRepository>())
        ..add(const CategoriesRequested()),
      child: this,
    );
  }

  @override
  State<RegisterMasterPage> createState() => _RegisterMasterPageState();
}

class _RegisterMasterPageState extends State<RegisterMasterPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _description = TextEditingController();
  final _experience = TextEditingController();
  final Set<int> _categoryIds = {};

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _city.dispose();
    _district.dispose();
    _description.dispose();
    _experience.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final exp = int.tryParse(_experience.text.trim()) ?? 0;
    if (_categoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну категорию')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthRegisterMasterRequested(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          passwordConfirmation: _passwordConfirm.text,
          city: _city.text.trim(),
          district: _district.text.trim().isEmpty
              ? null
              : _district.text.trim(),
          description: _description.text.trim(),
          experienceYears: exp,
          categoryIds: _categoryIds.toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Анкета мастера')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.router.replaceAll([const MainRoute()]);
          } else if (state is AuthFailed && state.user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          final errs = state is AuthFailed
              ? (state.errors ?? const <String, List<String>>{})
              : const <String, List<String>>{};
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl.w, vertical: AppSpacing.lg.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(title: 'О вас', children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _firstName,
                            label: 'Имя',
                            errorText: errs['first_name']?.first,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: AppTextField(
                            controller: _lastName,
                            label: 'Фамилия',
                            errorText: errs['last_name']?.first,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _phone,
                      label: 'Телефон',
                      hint: '+99450...',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      errorText: errs['phone']?.first,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _email,
                      label: 'E-mail',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      errorText: errs['email']?.first,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _password,
                      label: 'Пароль',
                      obscure: true,
                      errorText: errs['password']?.first,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _passwordConfirm,
                      label: 'Повторите пароль',
                      obscure: true,
                    ),
                  ]),
                  SizedBox(height: AppSpacing.lg.h),
                  _Section(title: 'Где работаете', children: [
                    AppTextField(
                      controller: _city,
                      label: 'Город',
                      prefixIcon: Icons.location_city_outlined,
                      errorText: errs['city']?.first,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _district,
                      label: 'Район (опционально)',
                      errorText: errs['district']?.first,
                    ),
                  ]),
                  SizedBox(height: AppSpacing.lg.h),
                  _Section(title: 'Опыт и услуги', children: [
                    AppTextField(
                      controller: _experience,
                      label: 'Опыт работы, лет',
                      keyboardType: TextInputType.number,
                      errorText: errs['experience_years']?.first,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _description,
                      label: 'О себе',
                      hint: 'Кратко: какие задачи решаете лучше всего',
                      maxLines: 4,
                      errorText: errs['description']?.first,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Категории, в которых работаете',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text3,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    BlocBuilder<CategoriesBloc, CategoriesState>(
                      builder: (ctx, s) {
                        if (s is! CategoriesLoaded) {
                          return const SizedBox(
                            height: 36,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            for (final c in s.items.where((c) => c.hasMasters))
                              HmPillButton(
                                label: c.name,
                                selected: _categoryIds.contains(c.id),
                                onTap: () => setState(() {
                                  if (_categoryIds.contains(c.id)) {
                                    _categoryIds.remove(c.id);
                                  } else {
                                    _categoryIds.add(c.id);
                                  }
                                }),
                              ),
                          ],
                        );
                      },
                    ),
                    if (errs['category_ids'] != null) ...[
                      SizedBox(height: 6.h),
                      Text(
                        errs['category_ids']!.first,
                        style: TextStyle(
                            color: AppColors.danger, fontSize: 12.sp),
                      ),
                    ],
                  ]),
                  SizedBox(height: AppSpacing.xl.h),
                  AppPrimaryButton(
                    label: 'Создать профиль мастера',
                    loading: loading,
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.text3,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 12.h),
        ...children,
      ],
    );
  }
}
