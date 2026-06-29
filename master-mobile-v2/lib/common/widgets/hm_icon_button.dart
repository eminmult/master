import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';

/// Круглая icon-кнопка 44×44 (стандарт) или 32×32 (small).
/// Три варианта:
///  - default — серая поверхность (`surface2`), белая иконка.
///  - `accent: true` — жёлтый бордер + жёлтая иконка.
///  - `flat: true` — прозрачный фон, только иконка.
class HmIconButton extends StatelessWidget {
  const HmIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.small = false,
    this.accent = false,
    this.flat = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool small;
  final bool accent;
  final bool flat;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final double size = small ? 32 : 44;
    final double iconSize = small ? 16 : 18;
    final color = accent ? AppColors.accent : AppColors.text;
    final bg = flat
        ? AppColors.transparent
        : (accent ? AppColors.accentSoft : AppColors.surface2);
    final border = flat
        ? null
        : Border.all(
            color: accent ? AppColors.accent : AppColors.border2,
          );

    final button = Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize.r, color: color),
    );

    final wrapped = Material(
      color: AppColors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: button,
      ),
    );

    if (tooltip == null) return wrapped;
    return Tooltip(message: tooltip!, child: wrapped);
  }
}
