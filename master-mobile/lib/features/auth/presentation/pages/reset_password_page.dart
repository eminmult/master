import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/password_policy.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/auth/data/auth_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.initialLogin, this.token});
  final String? initialLogin;
  final String? token;
  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  late final TextEditingController _login = TextEditingController(text: widget.initialLogin ?? '');
  late final TextEditingController _token = TextEditingController(text: widget.token ?? '');
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _token.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = context.l10n;
    if (_password.text != _passwordConfirm.text) {
      setState(() => _error = loc.auth_passwords_do_not_match);
      return;
    }
    final pwErr = validateStrongPassword(_password.text, loc);
    if (pwErr != null) {
      setState(() => _error = pwErr);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
        login: _login.text.trim(),
        token: _token.text.trim(),
        password: _password.text,
        passwordConfirmation: _passwordConfirm.text,
      );
      if (mounted) setState(() => _done = true);
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
                    onPressed: () => context.go('/login')),
              ]),
              const SizedBox(height: 24),
              Text(loc.auth_reset_title,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(loc.auth_reset_subtitle,
                  style: const TextStyle(fontSize: 14, color: HmColors.text5)),
              const SizedBox(height: 24),
              if (_done)
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
                      Expanded(child: Text(loc.auth_reset_success,
                          style: const TextStyle(color: HmColors.success))),
                    ],
                  ),
                )
              else ...[
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: HmColors.danger), textAlign: TextAlign.center),
                ),
                _f(_login, loc.auth_phone_or_email_hint, Icons.person_outline_rounded),
                _f(_token, loc.auth_reset_token, Icons.vpn_key_outlined),
                _f(_password, loc.auth_new_password, Icons.lock_outline_rounded, obscure: true),
                _f(_passwordConfirm, loc.auth_new_password_confirm, Icons.lock_outline_rounded, obscure: true),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(loc.auth_reset_submit),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(loc.auth_back_to_login, style: const TextStyle(color: HmColors.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String hint, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: HmColors.text4),
        ),
      ),
    );
  }
}
