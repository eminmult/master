import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// First step of registration — pick role. Real registration forms live at
/// /register/client and /register/master.
class RegisterRolePickerPage extends StatelessWidget {
  const RegisterRolePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Scaffold(
      backgroundColor: HmColors.bg,
      appBar: AppBar(title: Text(loc.auth_register_pick_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.auth_register_pick_q,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              _RoleCard(
                title: loc.auth_role_client_title,
                desc: loc.auth_role_client_desc,
                icon: Icons.person_search_rounded,
                primary: true,
                onTap: () => context.push('/register/client'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: loc.auth_role_master_title,
                desc: loc.auth_role_master_desc,
                icon: Icons.handyman_rounded,
                primary: false,
                onTap: () => context.push('/register/master'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.canPop() ? context.pop() : context.pushReplacement('/login'),
                child: Text(loc.auth_back_to_login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.primary,
    required this.onTap,
  });
  final String title;
  final String desc;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? HmColors.accent : HmColors.surface;
    final fg = primary ? Colors.black : HmColors.text;
    final descColor = primary ? Colors.black87 : HmColors.text5;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HmRadius.cardLarge),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: primary ? HmColors.accent : HmColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary ? Colors.black12 : HmColors.accentSoft,
              ),
              child: Icon(icon, color: primary ? Colors.black : HmColors.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 13, color: descColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: fg.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
