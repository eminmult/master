import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/routing/routes.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// Final fallback for GoRouter — fires when a navigation request can't be
/// matched (typo'd link, removed route, malformed deep link from a push
/// notification, etc.). Keeps the user on a known surface instead of
/// crashing into Flutter's red error screen.
class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({super.key, this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.travel_explore_rounded, size: 88, color: HmColors.accent),
                const SizedBox(height: 24),
                Text(
                  loc.error_page_not_found_title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: HmColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.error_page_not_found_desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: HmColors.text4, height: 1.5),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text(loc.error_back_home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
