import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/auth/data/auth_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _login = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_login.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_login.text.trim());
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                HmIconButton(icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                    onPressed: () => context.canPop() ? context.pop() : context.pushReplacement('/login')),
              ]),
              const SizedBox(height: 24),
              Text(loc.auth_forgot_title,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(loc.auth_forgot_subtitle,
                  style: const TextStyle(fontSize: 14, color: HmColors.text5)),
              const SizedBox(height: 24),
              if (_sent)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x1A22C55E),
                    borderRadius: BorderRadius.circular(HmRadius.pill),
                    border: Border.all(color: const Color(0x4D22C55E)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: HmColors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        loc.auth_forgot_sent,
                        style: const TextStyle(color: HmColors.success, fontSize: 13),
                      )),
                    ],
                  ),
                ),
              if (!_sent) ...[
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: HmColors.danger, fontSize: 13)),
                ),
                TextField(
                  controller: _login,
                  decoration: InputDecoration(
                    hintText: loc.auth_phone_or_email_hint,
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: HmColors.text4),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(loc.auth_forgot_submit),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.canPop() ? context.pop() : context.pushReplacement('/login'),
                child: Text(loc.auth_back_to_login, style: const TextStyle(color: HmColors.text5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
