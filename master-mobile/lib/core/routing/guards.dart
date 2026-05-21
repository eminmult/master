import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/onboarding/onboarding_state.dart';
import 'package:master_mobile/core/routing/routes.dart';

/// Pluggable route guard. Returns a redirect target string OR null to let
/// the next guard (or the actual route) take over. Composing many small
/// guards beats one giant 50-line redirect closure: each rule is
/// independently testable, named, and won't accidentally short-circuit a
/// sibling check by misordering an early `return`.
abstract class RouteGuard {
  String? evaluate(Ref ref, GoRouterState state);
}

/// Runs all guards in order; first non-null wins.
class RouteGuardChain {
  RouteGuardChain(this.guards);
  final List<RouteGuard> guards;

  String? evaluate(Ref ref, GoRouterState state) {
    for (final g in guards) {
      final r = g.evaluate(ref, state);
      if (r != null) return r;
    }
    return null;
  }
}

/// Gate that ensures each one-time onboarding step has been completed.
/// Reads typed flags from `onboardingFlagsProvider` so future steps (tour,
/// permissions) plug in here without poking SharedPreferences directly.
class OnboardingGuard implements RouteGuard {
  @override
  String? evaluate(Ref ref, GoRouterState state) {
    final loc = state.matchedLocation;
    final flags = ref.read(onboardingFlagsProvider);
    if (!flags.localePicked && loc != Routes.onboardingLanguage) {
      return Routes.onboardingLanguage;
    }
    if (flags.localePicked && loc == Routes.onboardingLanguage) {
      return Routes.home;
    }
    return null;
  }
}

/// Auth routing policy:
///
/// - Auth flow (/login, /register, /verify, …) — kicks an authenticated
///   user back to /home (or to ?next= when one is set), prevents re-login.
/// - Splash (/) — resolves to /home regardless of auth state.
/// - Inside the shell (Orders, Profile and their drill-downs) — does NOT
///   bounce a guest to /login. The pages themselves wrap their content in
///   `AuthGate`, which renders a "Sign in to continue" placeholder with a
///   CTA that pushes /login?next=…. This keeps the bottom-nav visible and
///   preserves the user's tab context across the auth round-trip.
class AuthGuard implements RouteGuard {
  @override
  String? evaluate(Ref ref, GoRouterState state) {
    final auth = ref.read(authStateProvider);
    final loc = state.matchedLocation;
    return switch (auth) {
      AuthLoading() => null,
      AuthAuthenticated() when Routes.isAuthGate(loc) => () {
          final next = state.uri.queryParameters['next'];
          return (next != null && next.isNotEmpty)
              ? Uri.decodeComponent(next)
              : Routes.home;
        }(),
      AuthAuthenticated() when loc == Routes.splash => Routes.home,
      AuthAuthenticated() => null,
      AuthUnauthenticated() when loc == Routes.splash => Routes.home,
      AuthUnauthenticated() => null, // protected pages render via AuthGate
    };
  }
}
