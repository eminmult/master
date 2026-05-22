import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/auth/password_policy.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/auth/data/models/user.dart';
import 'package:master_mobile/features/profile/data/profile_repository.dart';
import 'package:master_mobile/features/user_profile/data/user_profile_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Editable self-profile. Mirrors the site's "Edit profile" form on
/// `/profile/edit` — for clients, name + email; for masters, name + email
/// + description + city/district + experience years. Avatar is upload-on-tap
/// so users see the change immediately rather than waiting for "Save".
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});
  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _description;
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _experience;

  bool _busy = false;
  bool _avatarBusy = false;
  bool _busyDelete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authStateProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final mp = user?.masterProfile ?? const {};
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _description = TextEditingController(text: mp['description']?.toString() ?? '');
    _city = TextEditingController(text: mp['city']?.toString() ?? '');
    _district = TextEditingController(text: mp['district']?.toString() ?? '');
    final exp = mp['experience_years'];
    _experience = TextEditingController(text: exp != null ? '$exp' : '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _description.dispose();
    _city.dispose();
    _district.dispose();
    _experience.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: HmColors.accent),
              title: Text(context.l10n.chat_attach_camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: HmColors.accent),
              title: Text(context.l10n.chat_attach_gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );
    if (src == null) return;

    setState(() => _avatarBusy = true);
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
          source: src, maxWidth: 1024, imageQuality: 85);
      if (file == null) {
        setState(() => _avatarBusy = false);
        return;
      }
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.profile_avatar_too_big),
            backgroundColor: HmColors.danger,
          ));
        }
        setState(() => _avatarBusy = false);
        return;
      }
      final mime = file.mimeType ?? _guessMime(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      await ref.read(profileRepositoryProvider).uploadAvatar(dataUrl);
      await ref.read(authStateProvider.notifier).refreshUser();
      final auth = ref.read(authStateProvider);
      if (auth is AuthAuthenticated) {
        ref.invalidate(userProfileProvider(auth.user.id));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.profile_avatar_updated),
          backgroundColor: HmColors.success,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: HmColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  String _guessMime(String name) {
    final l = name.toLowerCase();
    if (l.endsWith('.png')) return 'image/png';
    if (l.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _save(User user) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(profileRepositoryProvider);
      if (user.isMaster) {
        await repo.updateMaster(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          description: _description.text.trim(),
          city: _city.text.trim(),
          district: _district.text.trim(),
          experienceYears: int.tryParse(_experience.text.trim()),
        );
      } else {
        await repo.updateClient(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        );
      }
      await ref.read(authStateProvider.notifier).refreshUser();
      ref.invalidate(userProfileProvider(user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.profile_saved),
          backgroundColor: HmColors.success,
        ));
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final auth = ref.watch(authStateProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null) {
      return const Scaffold(backgroundColor: HmColors.bg2, body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: HmColors.bg2,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
            children: [
              _Header(loc: loc),
              _AvatarBlock(
                user: user, busy: _avatarBusy, onTap: _pickAvatar,
              ),
              const SizedBox(height: 12),
              _SectionLabel(loc.profile_section_personal),
              _Field(
                  ctrl: _firstName,
                  label: loc.first_name,
                  required: true),
              _Field(
                  ctrl: _lastName,
                  label: loc.last_name,
                  required: user.isMaster),
              _Field(
                  ctrl: _email,
                  label: loc.profile_email_label,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
                    return ok ? null : loc.auth_email_invalid;
                  }),
              _ReadOnly(label: loc.profile_phone_label, value: user.phone),
              if (user.isMaster) ...[
                const SizedBox(height: 18),
                _SectionLabel(loc.profile_section_location),
                _Field(ctrl: _city, label: loc.profile_city),
                _Field(ctrl: _district, label: loc.profile_district),
                const SizedBox(height: 18),
                _SectionLabel(loc.profile_section_expertise),
                _Field(
                    ctrl: _experience,
                    label: loc.profile_experience,
                    keyboardType: TextInputType.number),
                _Field(
                    ctrl: _description,
                    label: loc.profile_about,
                    maxLines: 6,
                    hint: loc.profile_description_hint),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1FEF4444),
                      border: Border.all(color: const Color(0x4DEF4444)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: HmColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: HmColors.danger, fontSize: 12.5))),
                    ]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _save(user),
                    icon: _busy
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.black))
                        : const Icon(Icons.check_rounded, size: 16, color: Colors.black),
                    label: Text(_busy ? loc.profile_saving : loc.profile_save,
                        style: const TextStyle(color: Colors.black)),
                    style: FilledButton.styleFrom(
                      backgroundColor: HmColors.accent,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                      disabledBackgroundColor: HmColors.surface2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(loc.profile_security_label),
              _SmallActionRow(
                icon: Icons.lock_rounded,
                title: loc.profile_change_password,
                sub: loc.profile_change_password_sub,
                onTap: _showChangePassword,
              ),
              const SizedBox(height: 18),
              _SectionLabel(loc.profile_danger_zone),
              _SmallActionRow(
                icon: Icons.delete_forever_rounded,
                title: loc.profile_delete,
                sub: loc.profile_delete_sub,
                danger: true,
                busy: _busyDelete,
                onTap: _busyDelete ? null : _confirmDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePassword() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _confirmDelete() async {
    final loc = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HmColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HmRadius.cardLarge)),
        title: Text(loc.profile_delete_confirm_title,
            style: const TextStyle(color: HmColors.text)),
        content: Text(loc.profile_delete_confirm_body,
            style: const TextStyle(color: HmColors.text3)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel,
                style: const TextStyle(color: HmColors.text3)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: HmColors.danger, foregroundColor: Colors.white),
            child: Text(loc.profile_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyDelete = true);
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) context.go('/login');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: HmColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _busyDelete = false);
    }
  }
}

// === Subwidgets ===

class _Header extends StatelessWidget {
  const _Header({required this.loc});
  final AppLocalizations loc;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        HmIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            small: true, flat: true,
            onPressed: () => context.canPop() ? context.pop() : context.go('/profile')),
        const SizedBox(width: 4),
        Expanded(
          child: Text(loc.profile_edit_btn,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
      ]),
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.user, required this.busy, required this.onTap,
  });
  final User user;
  final bool busy;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: GestureDetector(
          onTap: busy ? null : onTap,
          child: Stack(clipBehavior: Clip.none, children: [
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              HmAvatar(url: user.avatarUrl, size: 120, ring: true)
            else
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HmColors.surface,
                  border: Border.all(color: HmColors.accent, width: 2),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 60, color: HmColors.accent),
              ),
            if (busy)
              Positioned.fill(
                child: ClipOval(
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                        color: HmColors.accent, strokeWidth: 2.4),
                  ),
                ),
              ),
            Positioned(
              right: 0, bottom: 4,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HmColors.accent,
                  border: Border.all(color: Colors.black, width: 4),
                ),
                child: const Icon(Icons.photo_camera_rounded,
                    size: 16, color: Colors.black),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: HmColors.text4)),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl, required this.label,
    this.required = false, this.keyboardType, this.maxLines = 1,
    this.hint, this.validator,
  });
  final TextEditingController ctrl;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HmColors.border2),
        ),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          minLines: 1, maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: HmColors.text2),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(color: HmColors.text4, fontSize: 13),
            hintStyle: const TextStyle(color: HmColors.text5, fontSize: 13),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          validator: validator ??
              (v) {
                if (required && (v == null || v.trim().isEmpty)) {
                  return context.l10n.required_field;
                }
                return null;
              },
        ),
      ),
    );
  }
}

class _ReadOnly extends StatelessWidget {
  const _ReadOnly({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        decoration: BoxDecoration(
          color: HmColors.surface3,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HmColors.border2),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: HmColors.text4,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, color: HmColors.text2)),
                ]),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: HmColors.text5),
        ]),
      ),
    );
  }
}

class _SmallActionRow extends StatelessWidget {
  const _SmallActionRow({
    required this.icon, required this.title, required this.sub,
    this.danger = false, this.onTap, this.busy = false,
  });
  final IconData icon;
  final String title;
  final String sub;
  final bool danger;
  final VoidCallback? onTap;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final color = danger ? HmColors.danger : HmColors.accent;
    final bg = danger ? const Color(0x1FEF4444) : HmColors.accentSoft;
    final border = danger ? const Color(0x4DEF4444) : HmColors.border2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HmRadius.card),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: HmColors.surface,
              borderRadius: BorderRadius.circular(HmRadius.card),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: color, strokeWidth: 2.4),
                      )
                    : Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: danger ? HmColors.danger : HmColors.text)),
                      const SizedBox(height: 2),
                      Text(sub,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: HmColors.text4, height: 1.35)),
                    ]),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: HmColors.text4, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}

// === Change-password bottom sheet ===

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();
  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _hideCur = true;
  bool _hideNew = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.profile_password_changed),
          backgroundColor: HmColors.success,
        ));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
                color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(loc.profile_change_password,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ),
          const SizedBox(height: 14),
          _SheetField(
            ctrl: _current,
            label: loc.profile_current_password,
            obscure: _hideCur,
            onToggle: () => setState(() => _hideCur = !_hideCur),
            validator: (v) =>
                (v == null || v.isEmpty) ? loc.required_field : null,
          ),
          const SizedBox(height: 8),
          _SheetField(
            ctrl: _next,
            label: loc.profile_new_password,
            obscure: _hideNew,
            onToggle: () => setState(() => _hideNew = !_hideNew),
            validator: (v) => validateStrongPassword(v, loc),
          ),
          const SizedBox(height: 8),
          _SheetField(
            ctrl: _confirm,
            label: loc.profile_confirm_password,
            obscure: _hideNew,
            validator: (v) {
              if (v != _next.text) return loc.profile_passwords_dont_match;
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x1FEF4444),
                border: Border.all(color: const Color(0x4DEF4444)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: HmColors.danger, fontSize: 12.5)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.black))
                  : const Icon(Icons.check_rounded, size: 16, color: Colors.black),
              label: Text(_busy ? loc.profile_saving : loc.profile_save,
                  style: const TextStyle(color: Colors.black)),
              style: FilledButton.styleFrom(
                backgroundColor: HmColors.accent,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.ctrl, required this.label,
    required this.obscure, this.onToggle, this.validator,
  });
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HmColors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HmColors.border2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: HmColors.text2),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: HmColors.text4, fontSize: 13),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18, color: HmColors.text4),
                  onPressed: onToggle,
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }
}
