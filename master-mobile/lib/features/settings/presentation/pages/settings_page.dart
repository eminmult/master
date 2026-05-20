import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/i18n/locales_repository.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final loc = context.l10n;
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                HmIconButton(icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/profile')),
                Expanded(child: Center(child: Text(loc.nav_settings,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 32),
              ]),
            ),
            // Language picker — list comes from /api/v1/i18n/locales so the
            // mobile app and the website stay in sync when an admin adds
            // or disables a language. Falls back to the hardcoded set when
            // the request fails (offline / cold start).
            _SectionLabel(loc.lang_choose.toUpperCase()),
            ref.watch(localesListProvider).when(
              data: (locales) => _LangPicker(locales: locales, current: locale, ref: ref),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: HmColors.text5)),
              ),
              error: (_, __) => _LangPicker(
                locales: const [
                  AppLocale(code: 'az', name: 'Azərbaycan', isDefault: true),
                  AppLocale(code: 'ru', name: 'Русский'),
                  AppLocale(code: 'en', name: 'English'),
                  AppLocale(code: 'tr', name: 'Türkçe'),
                  AppLocale(code: 'ar', name: 'العربية', dir: 'rtl'),
                ],
                current: locale,
                ref: ref,
              ),
            ),
            _SectionLabel('${loc.profile_privacy} & ${loc.common_data}'),
            _Tile(
              icon: Icons.cloud_download_rounded,
              label: loc.profile_export,
              sub: loc.profile_export_sub,
              onTap: () => _exportData(context, ref),
            ),
            _Tile(
              icon: Icons.delete_outline_rounded,
              label: loc.profile_delete,
              sub: loc.profile_delete_sub,
              danger: true,
              onTap: () => _deleteAccount(context, ref),
            ),
            _SectionLabel(loc.common_legal.toUpperCase()),
            _Tile(icon: Icons.description_rounded, label: loc.terms_title),
            _Tile(icon: Icons.shield_rounded, label: loc.privacy_title),
            _SectionLabel(loc.common_about.toUpperCase()),
            _Tile(icon: Icons.info_outline_rounded, label: '${loc.common_version} 1.0.0'),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: FilledButton.icon(
                  onPressed: () => ref.read(authStateProvider.notifier).logout(),
                  icon: const Icon(Icons.logout_rounded, size: 16, color: HmColors.danger),
                  label: Text(loc.auth_logout),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0x1AEF4444),
                    foregroundColor: HmColors.danger,
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HmRadius.pill),
                      side: const BorderSide(color: Color(0x4DEF4444)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final loc = context.l10n;
    try {
      final dio = ref.read(apiClientProvider);
      await dio.get<Map<String, dynamic>>('/me/export');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.profile_export_done),
          backgroundColor: HmColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'), backgroundColor: HmColors.danger,
        ));
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final loc = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HmColors.surface,
        title: Text(loc.profile_delete_confirm_title),
        content: Text(loc.profile_delete_confirm_body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.common_cancel, style: const TextStyle(color: HmColors.text4))),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: HmColors.danger, foregroundColor: Colors.white),
            child: Text(loc.common_delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post<void>('/me/delete', data: {'confirm': 'DELETE'});
      await ref.read(authStateProvider.notifier).logout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'), backgroundColor: HmColors.danger,
        ));
      }
    }
  }
}

class _LangPicker extends StatelessWidget {
  const _LangPicker({required this.locales, required this.current, required this.ref});
  final List<AppLocale> locales;
  final Locale current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: locales.map((l) {
          final selected = current.languageCode == l.code;
          return InkWell(
            onTap: () => ref.read(localeControllerProvider.notifier).setLocale(Locale(l.code)),
            borderRadius: BorderRadius.circular(HmRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? HmColors.accent : HmColors.surface,
                borderRadius: BorderRadius.circular(HmRadius.pill),
                border: Border.all(color: selected ? HmColors.accent : HmColors.border),
              ),
              child: Text(l.name, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? Colors.black : HmColors.text,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.4, color: Color(0x66FFFFFF),
      )),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, this.sub, this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? HmColors.danger : HmColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Material(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(HmRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HmRadius.pill),
              border: Border.all(color: HmColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: danger ? const Color(0x1AEF4444) : HmColors.accentSoft,
                  ),
                  child: Icon(icon, color: danger ? HmColors.danger : HmColors.accent, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
                      if (sub != null) ...[
                        const SizedBox(height: 2),
                        Text(sub!, style: const TextStyle(fontSize: 12, color: HmColors.text5)),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right_rounded, color: HmColors.accent, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
