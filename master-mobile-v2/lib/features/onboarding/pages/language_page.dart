import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/config_bloc/config_bloc.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/services/local_storage.dart';

@RoutePage()
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  // Все 5 языков из SupportedLocale — точно как на оригинале master-mobile.
  static const _locales = <_LocaleOption>[
    _LocaleOption(code: 'az', label: 'Azərbaycan', flag: 'AZ'),
    _LocaleOption(code: 'ru', label: 'Русский', flag: 'RU'),
    _LocaleOption(code: 'en', label: 'English', flag: 'EN'),
    _LocaleOption(code: 'tr', label: 'Türkçe', flag: 'TR'),
    _LocaleOption(code: 'ar', label: 'العربية', flag: 'AR'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ConfigBloc>().state.configModel.locale;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Выберите язык',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Это можно изменить позже в настройках.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).hintColor,
                ),
              ),
              SizedBox(height: 32.h),
              for (final option in _locales)
                _LocaleTile(
                  option: option,
                  selected: option.code == current.languageCode,
                  onTap: () => context
                      .read<ConfigBloc>()
                      .add(ChangeLocale(Locale(option.code))),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await LocalStorage.setOnboardingDone();
                  if (!context.mounted) return;
                  await context.router.replace(const MainRoute());
                },
                child: const Text('Продолжить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleOption {
  const _LocaleOption({
    required this.code,
    required this.label,
    required this.flag,
  });
  final String code;
  final String label;
  final String flag;
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LocaleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : Theme.of(context).dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor:
                    AppColors.brandPrimary.withOpacity(0.12),
                child: Text(
                  option.flag,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.brandPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
