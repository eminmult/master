import 'package:flutter/material.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// Small pill toggle (`.btn-pill`) — used for All / Emergency / Installation /
/// Repair filter strip on the list screen.
class HmPillButton extends StatelessWidget {
  const HmPillButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? HmColors.accent : HmColors.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HmRadius.pill),
        side: BorderSide(color: active ? HmColors.accent : HmColors.border2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(HmRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.black : HmColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
