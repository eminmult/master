import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).login(_login.text.trim(), _password.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
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
        child: Stack(
          children: [
            // Back button — same flat-style HmIconButton used on every other
            // page. Falls back to /home when there's nothing to pop (i.e.
            // user landed on /login as a fresh tab).
            Positioned(
              top: 12,
              left: 12,
              child: HmIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                small: true,
                flat: true,
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 72, height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: HmColors.accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: HmColors.accentBorder),
                      ),
                      child: const Icon(Icons.handyman_rounded, color: HmColors.accent, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(loc.auth_welcome_back,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(loc.auth_sign_in_to_continue,
                          style: const TextStyle(fontSize: 14, color: HmColors.text5)),
                    ),
                    const SizedBox(height: 32),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x1AEF4444),
                          borderRadius: BorderRadius.circular(HmRadius.pill),
                          border: Border.all(color: const Color(0x4DEF4444)),
                        ),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: HmColors.danger, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _login,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        hintText: loc.auth_phone_or_email,
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: HmColors.text4, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? loc.auth_required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: loc.auth_password,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: HmColors.text4, size: 20),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? loc.auth_min6 : null,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(HmRadius.pill)),
                        boxShadow: HmShadows.accentGlow,
                      ),
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(loc.auth_login_title),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pushReplacement('/register'),
                      child: Text(loc.auth_create_account, style: const TextStyle(color: HmColors.accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
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
}
