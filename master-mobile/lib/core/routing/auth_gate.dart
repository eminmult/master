import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/routing/routes.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// Wrap pages that require auth (Orders, Profile, etc) so a guest stays
/// inside the current tab branch and sees a placeholder instead of being
/// kicked out to /login. Tapping the CTA pushes /login with a ?next=…
/// query so login can return the user back to the branch they started in.
///
/// Why a widget rather than a redirect:
///
///   - A `redirect: '/login'` from inside a branch boots the user out of
///     the StatefulShellRoute, breaking the persistent-tabs UX (the bottom
///     nav disappears, returning loses scroll position, etc.).
///   - A placeholder INSIDE the branch keeps the user's mental model
///     ("I'm on the Profile tab, I just need to sign in") and lets us
///     pre-fill `?next=` so post-login routing is deterministic.
class AuthGate extends ConsumerWidget {
  const AuthGate({
    super.key,
    required this.child,
    required this.placeholderTitle,
    required this.placeholderBody,
    required this.nextPath,
  });

  /// The real content, shown to authenticated users.
  final Widget child;

  /// Headline for the guest placeholder ("Войдите чтобы …").
  final String placeholderTitle;

  /// Sub-line describing why auth is needed.
  final String placeholderBody;

  /// Where the user wanted to be — login will return here on success.
  final String nextPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return switch (auth) {
      AuthLoading() => const _LoadingPlaceholder(),
      AuthAuthenticated() => child,
      AuthUnauthenticated() => _GuestPlaceholder(
          title: placeholderTitle,
          body: placeholderBody,
          nextPath: nextPath,
        ),
    };
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: HmColors.accent));
  }
}

class _GuestPlaceholder extends StatelessWidget {
  const _GuestPlaceholder({required this.title, required this.body, required this.nextPath});
  final String title;
  final String body;
  final String nextPath;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 64, color: HmColors.accent),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: HmColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: HmColors.text4, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              // push (not go) — keeps the current branch alive underneath.
              // After login, AuthGuard's `?next=` handling returns the user
              // to nextPath, which is exactly this page.
              onPressed: () => context.push(Routes.loginWithNext(nextPath)),
              child: Text(loc.auth_login_title),
            ),
          ],
        ),
      ),
    );
  }
}
