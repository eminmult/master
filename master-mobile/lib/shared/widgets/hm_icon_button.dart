import 'package:flutter/material.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// Round icon button matching the `.icon-btn` class:
///   - default 44x44 circular surface chip
///   - `accent: true` → yellow tint with accent border
///   - `flat: true` → transparent (no surface)
///   - `small: true` → 32x32
class HmIconButton extends StatelessWidget {
  const HmIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.accent = false,
    this.flat = false,
    this.small = false,
    this.iconSize,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool accent;
  final bool flat;
  final bool small;
  final double? iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final size = small ? 32.0 : 44.0;
    final iSize = iconSize ?? (small ? 16.0 : 18.0);

    final color = accent ? HmColors.accent : HmColors.text;
    final bg = flat ? Colors.transparent : (accent ? HmColors.accentSoft : HmColors.surface);
    final borderColor = flat ? Colors.transparent : (accent ? HmColors.accentBorder : HmColors.border);

    final btn = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(HmRadius.pill),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(HmRadius.pill),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iSize, color: color),
        ),
      ),
    );

    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}
