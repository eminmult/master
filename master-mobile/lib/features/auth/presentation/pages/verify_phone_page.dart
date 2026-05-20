import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/auth/data/auth_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

class VerifyPhonePage extends ConsumerStatefulWidget {
  const VerifyPhonePage({super.key});
  @override
  ConsumerState<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends ConsumerState<VerifyPhonePage> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyPhoneOtp(_code.text);
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).requestPhoneOtp();
      _startCooldown(60);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final auth = ref.watch(authStateProvider);
    final phone = auth is AuthAuthenticated ? auth.user.phone : '';

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
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
              ]),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: HmColors.accentSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: HmColors.accentBorder),
                  ),
                  child: const Icon(Icons.sms_rounded, color: HmColors.accent, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(loc.auth_verify_phone_title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5))),
              const SizedBox(height: 8),
              Center(child: Text(loc.auth_verify_phone_sub(phone),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: HmColors.text5))),
              const SizedBox(height: 32),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: HmColors.danger, fontSize: 13)),
              ),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                decoration: InputDecoration(hintText: loc.auth_otp_dots_placeholder),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: (_busy || _code.text.length != 6) ? null : _verify,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(loc.auth_verify_btn),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _cooldown > 0 ? null : _resend,
                child: Text(
                  _cooldown > 0 ? loc.auth_resend_in_seconds(_cooldown) : loc.auth_resend_code,
                  style: TextStyle(color: _cooldown > 0 ? HmColors.text5 : HmColors.accent),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(loc.auth_skip_for_now, style: const TextStyle(color: HmColors.text5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
