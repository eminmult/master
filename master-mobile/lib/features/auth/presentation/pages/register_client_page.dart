import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/auth/password_policy.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

class RegisterClientPage extends ConsumerStatefulWidget {
  const RegisterClientPage({super.key});
  @override
  ConsumerState<RegisterClientPage> createState() => _RegisterClientPageState();
}

class _RegisterClientPageState extends ConsumerState<RegisterClientPage> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _busy = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = {};

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _email, _password, _passwordConfirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = {};
    });
    try {
      await ref.read(authStateProvider.notifier).registerClient({
        'first_name': _firstName.text.trim(),
        if (_lastName.text.trim().isNotEmpty) 'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        'password': _password.text,
        'password_confirmation': _passwordConfirm.text,
      });
      if (mounted) context.go('/verify-phone');
    } on ValidationException catch (e) {
      if (mounted) setState(() => _fieldErrors = e.errors);
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
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  HmIconButton(icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                      onPressed: () => context.canPop() ? context.pop() : context.pushReplacement('/register')),
                ]),
                const SizedBox(height: 12),
                Text(loc.auth_register_client_title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(loc.auth_register_client_subtitle,
                    style: const TextStyle(fontSize: 14, color: HmColors.text5)),
                const SizedBox(height: 24),
                if (_error != null) _ErrorBox(_error!),
                _Field(
                  controller: _firstName,
                  hint: loc.auth_first_name,
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? loc.common_required : null,
                  serverErrors: _fieldErrors['first_name'],
                ),
                _Field(
                  controller: _lastName,
                  hint: loc.auth_last_name_optional,
                  icon: Icons.person_outline_rounded,
                  serverErrors: _fieldErrors['last_name'],
                ),
                _Field(
                  controller: _phone,
                  hint: loc.auth_phone_format_hint,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return loc.common_required;
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(v.trim())) return loc.auth_invalid_phone;
                    return null;
                  },
                  serverErrors: _fieldErrors['phone'],
                ),
                _Field(
                  controller: _email,
                  hint: loc.auth_email_optional,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  serverErrors: _fieldErrors['email'],
                ),
                _Field(
                  controller: _password,
                  hint: loc.auth_password,
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: (v) => validateStrongPassword(v, loc),
                  serverErrors: _fieldErrors['password'],
                ),
                _Field(
                  controller: _passwordConfirm,
                  hint: loc.auth_password_confirm,
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: (v) => v != _password.text ? loc.auth_passwords_do_not_match : null,
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
                          : Text(loc.auth_create_account),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pushReplacement('/login'),
                  child: Text(loc.auth_already_have_account_signin,
                      style: const TextStyle(color: HmColors.accent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.serverErrors,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<String>? serverErrors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20, color: HmColors.text4),
            ),
            validator: validator,
          ),
          if (serverErrors != null && serverErrors!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(serverErrors!.first,
                  style: const TextStyle(color: HmColors.danger, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1AEF4444),
          borderRadius: BorderRadius.circular(HmRadius.pill),
          border: Border.all(color: const Color(0x4DEF4444)),
        ),
        child: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: HmColors.danger, fontSize: 13)),
      ),
    );
  }
}
