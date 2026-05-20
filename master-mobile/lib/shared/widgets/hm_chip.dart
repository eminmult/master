import 'package:flutter/material.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

class HmChip extends StatelessWidget {
  const HmChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: HmColors.surface2,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        border: Border.all(color: HmColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: HmColors.text3,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
