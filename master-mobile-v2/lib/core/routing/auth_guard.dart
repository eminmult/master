import 'package:auto_route/auto_route.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';

/// Защита приватных роутов.
///
/// Состояния:
///  - `AuthAuthenticated`           — `next()`.
///  - `AuthUnknown` / `AuthLoading` — `next()` тоже: bootstrap асинхронный,
///    на deep-link guard срабатывает раньше чем bloc успевает резолвить
///    токен. Если потом окажется guest → AuthBloc эмитит
///    `AuthUnauthenticated`, App-уровень BlocListener делает глобальный
///    `replaceAll([LoginRoute()])`.
///  - `AuthUnauthenticated` / `AuthFailed`(без user) — `redirect(LoginRoute)`.
class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final auth = locator<AuthBloc>().state;
    final shouldPass = auth is AuthAuthenticated ||
        auth is AuthUnknown ||
        auth is AuthLoading ||
        (auth is AuthFailed && auth.user != null);
    if (shouldPass) {
      resolver.next();
      return;
    }
    resolver.redirect(const LoginRoute());
  }
}
