import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/routing/router.dart';
import 'package:master_mobile/core/theme/app_theme.dart';
import 'package:master_mobile/features/calls/data/call_service.dart';
import 'package:master_mobile/features/calls/presentation/call_overlay.dart';
import 'package:master_mobile/features/realtime/sse_client.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';

class MasterApp extends ConsumerWidget {
  const MasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(routerProvider);

    // When the user signs in (or /auth/me bootstrap completes), pull the
    // server-stored locale onto the local controller so the language follows
    // the account across devices.
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        ref.read(localeControllerProvider.notifier).applyServerLocale(next.user.locale);
      }
    });

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Keep the call service alive for the lifetime of the app — it owns the
    // Reverb subscription that delivers incoming call events.
    ref.watch(callServiceProvider);
    // SSE client — primary realtime transport for chat (CF-Flexible-friendly).
    ref.watch(sseClientProvider);

    return MaterialApp.router(
      title: 'Master.az',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // RTL is automatic — Flutter inspects the locale and flips Directionality.
      routerConfig: router,
      builder: (context, child) {
        // Android hardware back button policy:
        // - Deep route (router can pop) → pop one step (matches edge-swipe).
        // - Tab root (/orders, /profile, /announcements, /categories) → /home.
        // - /home or / → return false so the OS handles it (minimize).
        //
        // We use BackButtonListener instead of a top-level PopScope because
        // PopScope at MaterialApp.builder level sits OUTSIDE the GoRouter
        // Navigator, so its onPopInvoked callback was not firing on Flutter
        // 3.24+ — the OS back went straight to the platform handler and the
        // app exited. BackButtonListener intercepts the platform event before
        // the navigator gets it and lets us route manually.
        return BackButtonListener(
          onBackButtonPressed: () async {
            if (router.canPop()) {
              router.pop();
              return true; // consumed
            }
            final loc = router.routerDelegate.currentConfiguration.uri.toString();
            if (loc == '/home' || loc == '/') {
              return false; // let OS minimize the app
            }
            router.go('/home');
            return true;
          },
          child: Stack(children: [
            if (child != null) child,
            const Positioned.fill(child: CallOverlay()),
          ]),
        );
      },
    );
  }
}
