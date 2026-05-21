import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/auth/password_policy.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';
import 'package:master_mobile/shared/widgets/hm_pill_button.dart';

final _categoriesProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(categoriesRepositoryProvider).list();
});

class RegisterMasterPage extends ConsumerStatefulWidget {
  const RegisterMasterPage({super.key});
  @override
  ConsumerState<RegisterMasterPage> createState() => _RegisterMasterPageState();
}

class _RegisterMasterPageState extends ConsumerState<RegisterMasterPage> {
  int _step = 0; // 0 = identity, 1 = profile, 2 = categories
  final _form = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _description = TextEditingController();
  final _experience = TextEditingController(text: '0');
  final Set<int> _categoryIds = {};

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _email, _password, _passwordConfirm,
                     _city, _district, _description, _experience]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_categoryIds.isEmpty) {
      setState(() => _error = context.l10n.auth_pick_at_least_one_category);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).registerMaster({
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'password_confirmation': _passwordConfirm.text,
        'city': _city.text.trim(),
        if (_district.text.trim().isNotEmpty) 'district': _district.text.trim(),
        'description': _description.text.trim(),
        'experience_years': int.tryParse(_experience.text) ?? 0,
        'category_ids': _categoryIds.toList(),
      });
      if (mounted) context.go('/verify-phone');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validateCurrentStep() {
    if (_step == 0) {
      return (_form.currentState?.validate() ?? false);
    }
    if (_step == 1) {
      return _city.text.trim().isNotEmpty && _description.text.trim().length >= 20;
    }
    return true;
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  HmIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    small: true, flat: true,
                    onPressed: () {
                      if (_step != 0) {
                        setState(() => _step--);
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.pushReplacement('/register');
                      }
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: List.generate(3, (i) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step ? HmColors.accent : HmColors.surface2,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ))),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: switch (_step) {
                    0 => _identityStep(),
                    1 => _profileStep(),
                    _ => _categoriesStep(),
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(HmRadius.pill)),
                  boxShadow: HmShadows.accentGlow,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _next,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(_step < 2 ? context.l10n.common_continue : context.l10n.auth_create_account),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityStep() {
    final loc = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.auth_register_master_title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(loc.auth_master_step_1,
            style: const TextStyle(fontSize: 14, color: HmColors.text5)),
        const SizedBox(height: 24),
        if (_error != null) _ErrorBox(_error!),
        _f(_firstName, loc.auth_first_name, Icons.person_outline_rounded, required: true),
        _f(_lastName, loc.auth_last_name, Icons.person_outline_rounded, required: true),
        _f(_phone, loc.auth_phone_format_hint, Icons.phone_outlined, required: true,
            keyboardType: TextInputType.phone,
            validator: (v) => RegExp(r'^\+?[0-9]{10,15}$').hasMatch(v ?? '') ? null : loc.auth_invalid_phone),
        _f(_email, loc.auth_email, Icons.alternate_email_rounded, required: true,
            keyboardType: TextInputType.emailAddress),
        _f(_password, loc.auth_password_with_min, Icons.lock_outline_rounded, obscure: true,
            validator: (v) => validateStrongPassword(v, loc)),
        _f(_passwordConfirm, loc.auth_password_confirm, Icons.lock_outline_rounded, obscure: true,
            validator: (v) => v != _password.text ? loc.auth_passwords_do_not_match : null),
      ],
    );
  }

  Widget _profileStep() {
    final loc = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.auth_about_you,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(loc.auth_master_step_2,
            style: const TextStyle(fontSize: 14, color: HmColors.text5)),
        const SizedBox(height: 24),
        if (_error != null) _ErrorBox(_error!),
        _f(_city, loc.auth_city_hint, Icons.location_city_rounded, required: true),
        _f(_district, loc.auth_district_optional, Icons.location_on_outlined),
        _f(_experience, loc.auth_experience, Icons.work_history_rounded,
            keyboardType: TextInputType.number),
        const SizedBox(height: 4),
        Text(loc.auth_description_label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HmColors.text4, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _description,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: loc.auth_about_placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HmColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: HmColors.border),
            ),
          ),
          validator: (v) => (v == null || v.trim().length < 20) ? loc.auth_description_min_20 : null,
        ),
      ],
    );
  }

  Widget _categoriesStep() {
    final loc = context.l10n;
    final asyncCategories = ref.watch(_categoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(loc.auth_master_pick_categories,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(loc.auth_master_step_3,
            style: const TextStyle(fontSize: 14, color: HmColors.text5)),
        const SizedBox(height: 24),
        if (_error != null) _ErrorBox(_error!),
        asyncCategories.when(
          data: (cats) => Wrap(
            spacing: 8, runSpacing: 8,
            children: cats.map((c) {
              final selected = _categoryIds.contains(c.id);
              return HmPillButton(
                label: c.name,
                active: selected,
                onTap: () => setState(() {
                  selected ? _categoryIds.remove(c.id) : _categoryIds.add(c.id);
                }),
              );
            }).toList(),
          ),
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: HmColors.accent),
          )),
          error: (e, _) => Text('${loc.auth_failed_to_load}: $e', style: const TextStyle(color: HmColors.danger)),
        ),
      ],
    );
  }

  Widget _f(TextEditingController c, String hint, IconData icon, {
    bool required = false, bool obscure = false, TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: HmColors.text4),
        ),
        validator: validator ?? (required
            ? (v) => (v == null || v.trim().isEmpty) ? context.l10n.common_required : null
            : null),
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
        child: Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: HmColors.danger, fontSize: 13)),
      ),
    );
  }
}
