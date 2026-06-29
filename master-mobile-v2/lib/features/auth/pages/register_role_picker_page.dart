import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';

/// Шаг перед регистрацией — выбор роли (client / master).
/// Клиент идёт на короткую форму, мастер — на multi-step wizard.
@RoutePage()
class RegisterRolePickerPage extends StatelessWidget {
  const RegisterRolePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w, vertical: AppSpacing.lg.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.lg.h),
              Text(
                'Кто вы?',
                style: TextStyle(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'От этого зависит, какую анкету заполнить.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.text4,
                  height: 1.4,
                ),
              ),
              SizedBox(height: AppSpacing.xxl.h),
              _RoleCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Я ищу мастера',
                subtitle: 'Заказать услугу — у себя дома или на улице',
                onTap: () => context.router.push(const RegisterRoute()),
              ),
              SizedBox(height: AppSpacing.md.h),
              _RoleCard(
                icon: Icons.handyman_outlined,
                title: 'Я мастер',
                subtitle: 'Принимать заказы, развивать профиль',
                accent: true,
                onTap: () =>
                    context.router.push(const RegisterMasterRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? AppColors.accent : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(
              color: accent ? AppColors.accent : AppColors.border2,
            ),
            boxShadow: accent ? AppShadows.accentGlow : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent ? AppColors.black : AppColors.surface2,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  icon,
                  size: 24.r,
                  color: accent ? AppColors.accent : AppColors.text,
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: accent ? AppColors.black : AppColors.text,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: accent
                            ? AppColors.black.withOpacity(0.75)
                            : AppColors.text4,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_rounded,
                color: accent ? AppColors.black : AppColors.text,
                size: 22.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
