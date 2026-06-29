import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/config_bloc/config_bloc.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/supported_locales.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/auth/models/user_role.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth.user;
    if (user == null) {
      // Защита: PoO для гостя - но мы не редиректим
      // (роутер уже не должен сюда пускать без auth).
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () =>
                context.router.push(const NotificationsRoute()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.router.push(const SettingsRoute()),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor:
                      AppColors.brandPrimary.withOpacity(0.12),
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Icon(Icons.person, size: 32.r,
                          color: AppColors.brandPrimary)
                      : ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.avatarUrl!,
                            width: 64.r,
                            height: 64.r,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        user.phone,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      if (user.role.isMaster && (user.ratingCount > 0)) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.amber, size: 16.r),
                            SizedBox(width: 2.w),
                            Text(
                              user.ratingAvg.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '  ·  ${user.ratingCount}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          _Section(children: [
            _Tile(
              icon: Icons.person_outline,
              label: 'Личные данные',
              onTap: () => context.router.push(const EditProfileRoute()),
            ),
            if (!user.hasVerifiedPhone)
              _Tile(
                icon: Icons.phonelink_lock_outlined,
                label: 'Подтвердить телефон',
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'не подтверждён',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                onTap: () => context.router.push(const VerifyPhoneRoute()),
              ),
            _Tile(
              icon: Icons.lock_outline,
              label: 'Изменить пароль',
              onTap: () => context.router.push(const ChangePasswordRoute()),
            ),
            if (user.isClient)
              _Tile(
                icon: Icons.place_outlined,
                label: 'Мои адреса',
                onTap: () => context.router.push(const AddressesRoute()),
              ),
            if (user.isMaster)
              _Tile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Кошелёк',
                onTap: () => context.router.push(const WalletRoute()),
              ),
          ]),
          SizedBox(height: 16.h),
          _Section(children: [
            _Tile(
              icon: Icons.language_outlined,
              label: 'Язык',
              trailing: Text(
                _localeLabel(context),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).hintColor,
                ),
              ),
              onTap: () => _showLanguagePicker(context),
            ),
            _Tile(
              icon: Icons.dark_mode_outlined,
              label: 'Тёмная тема',
              trailing: BlocBuilder<ConfigBloc, ConfigState>(
                builder: (ctx, state) => Switch.adaptive(
                  value: state.configModel.themeMode == ThemeMode.dark,
                  onChanged: (_) =>
                      ctx.read<ConfigBloc>().add(const ToggleThemeMode()),
                ),
              ),
            ),
          ]),
          SizedBox(height: 16.h),
          _Section(children: [
            _Tile(
              icon: Icons.logout,
              label: 'Выйти',
              destructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ]),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  String _localeLabel(BuildContext context) {
    final code = context.read<ConfigBloc>().state.configModel.locale.languageCode;
    return SupportedLocale.fromCode(code)?.name ?? code;
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      builder: (sheetCtx) {
        final bloc = context.read<ConfigBloc>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final l in SupportedLocale.values)
                ListTile(
                  title: Text(l.name),
                  onTap: () {
                    bloc.add(ChangeLocale(l.locale));
                    Navigator.pop(sheetCtx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pop(dialogCtx);
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : null;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}
