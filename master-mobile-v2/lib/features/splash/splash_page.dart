import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/services/local_storage.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/main.dart' as entry;

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_resolveNext());
  }

  Future<void> _resolveNext() async {
    final onboarded = await LocalStorage.getOnboardingDone();
    // Дожидаемся, пока AuthBloc загрузит токен и сделает /me.
    final auth = context.read<AuthBloc>();
    if (auth.state is AuthUnknown || auth.state is AuthLoading) {
      await auth.stream.firstWhere(
        (s) => s is! AuthUnknown && s is! AuthLoading,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (!onboarded) {
      await context.router.replace(const LanguageRoute());
      return;
    }
    // Deep-link: главная читает snapshot URL который main() взял до того,
    // как Flutter web мог его перепарсить. Если есть конкретный путь —
    // отдаём auto_route'у, он сам поднимет цепочку маршрутов.
    final deepLink = entry.initialDeepLink;
    if (deepLink != null && deepLink.isNotEmpty && deepLink != '/') {
      await context.router.replaceNamed(deepLink);
      return;
    }
    // Анонимные ходят по приложению; авторизация требуется на конкретных экранах.
    await context.router.replace(const MainRoute());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.brandPrimary,
      body: Center(child: _LogoMark()),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'itez',
      style: TextStyle(
        color: AppColors.white,
        fontSize: 56.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
    );
  }
}
