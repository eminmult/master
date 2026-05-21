import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/routing/router.dart';
import 'package:master_mobile/core/theme/app_theme.dart';
import 'package:master_mobile/core/ui/snackbar_service.dart';
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
      // SnackbarService routes through this key, so anywhere in the app can
      // pop a snackbar without grabbing a BuildContext-bound messenger.
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
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
        // - /home or / → minimise the app via SystemNavigator.pop.
        //
        // PopScope is the right tool here even though we're at MaterialApp.
        // builder level (above the navigator). BackButtonListener tried to
        // look up Router via an ancestor and crashed with a null-check
        // exception — the Router widget lives in our SUBTREE, not above us.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (router.canPop()) {
              router.pop();
              return;
            }
            final loc = router.routerDelegate.currentConfiguration.uri.toString();
            if (loc == '/home' || loc == '/') {
              SystemNavigator.pop();
            } else {
              router.go('/home');
            }
          },
          // Stack needs at least one non-positioned child to compute its size;
          // when MaterialApp passes a null child during route transitions we
          // fall back to a sized-box placeholder so the call overlay still
          // has somewhere to render.
          child: Stack(children: [
            child ?? const SizedBox.expand(),
            const Positioned.fill(child: CallOverlay()),
          ]),
        );
      },
    );
  }
}
