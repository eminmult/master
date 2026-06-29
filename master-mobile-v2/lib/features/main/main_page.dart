import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/main/navbar_bloc/navbar_bloc.dart';
import 'package:itez_mobile/features/main/widgets/hm_bottom_nav.dart';

/// Shell приложения. 4 таба, плавающая pill-навигация поверх контента
/// (контент сам учитывает bottom-inset через 110px padding-снизу).
@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  DateTime? _lastBackPressed;

  List<HmNavItem> _items(BuildContext ctx) {
    final l = ctx.l10n;
    return [
      HmNavItem(icon: Icons.home_rounded, label: l.tab_home),
      HmNavItem(icon: Icons.calendar_today_rounded, label: l.tab_bookings),
      HmNavItem(icon: Icons.campaign_rounded, label: l.tab_announcements),
      HmNavItem(icon: Icons.person_outline_rounded, label: l.tab_profile),
    ];
  }

  Future<bool> _onBack(bool canPop) async {
    if (canPop) return false;
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 3)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
        ),
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavbarBloc(),
      child: AutoRouter(
        builder: (context, child) {
          final canPop = context.router.canPop();
          return BackButtonListener(
            onBackButtonPressed: () => _onBack(canPop),
            child: Scaffold(
              extendBody: true,
              body: Stack(
                children: [
                  Positioned.fill(child: child),
                  if (!canPop)
                    Align(
                      alignment: Alignment.bottomCenter,
                      // Без SafeArea: оригинал master-mobile позиционирует
                      // nav с собственным padding(24,0,24,12) и игнорирует
                      // bottom inset — home-indicator на iOS просвечивает
                      // через accent-soft бордюр капсулы, как и задумано.
                      child: BlocBuilder<NavbarBloc, NavbarState>(
                        builder: (ctx, state) => HmBottomNav(
                          currentIndex: state.index,
                          items: _items(ctx),
                          onTap: (i) => _onTap(ctx, i),
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

  Future<void> _onTap(BuildContext context, int index) async {
    context.read<NavbarBloc>().add(SelectTabEvent(index));

    final isGuest = context.read<AuthBloc>().state is! AuthAuthenticated;
    // Bookings (мои заказы) и Profile требуют авторизации.
    if (isGuest && (index == 1 || index == 3)) {
      await context.router.push(const LoginRoute());
      return;
    }

    switch (index) {
      case 0:
        await context.router.replaceAll([const HomeRoute()]);
        break;
      case 1:
        await context.router.replaceAll([const OrdersRoute()]);
        break;
      case 2:
        await context.router.replaceAll([const AnnouncementsRoute()]);
        break;
      case 3:
        await context.router.replaceAll([const ProfileRoute()]);
        break;
      default:
        await context.router.replaceAll([const HomeRoute()]);
    }
  }
}
