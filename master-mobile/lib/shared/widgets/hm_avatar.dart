import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:master_mobile/core/config/app_config.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

String? _resolveAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) {
    final base = Uri.tryParse(AppConfig.apiBaseUrl);
    final origin = base == null ? 'https://itez.app' : '${base.scheme}://${base.host}';
    return '$origin$url';
  }
  return url;
}

/// Circular avatar from URL. Optionally shows a yellow ring (matches the
/// `.avatar-ring` class) and an online indicator dot in the bottom-right.
class HmAvatar extends StatelessWidget {
  const HmAvatar({
    super.key,
    required this.url,
    this.size = 48,
    this.ring = false,
    this.online = false,
  });

  final String? url;
  final double size;
  final bool ring;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveAvatarUrl(url);
    final inner = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: resolved == null
            ? const ColoredBox(color: HmColors.surface)
            : CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: HmColors.surface),
                errorWidget: (_, __, ___) => Container(
                  color: HmColors.surface,
                  child: const Icon(Icons.person, color: HmColors.text5),
                ),
              ),
      ),
    );

    final ringed = ring
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: HmColors.accentBorder, width: 2),
            ),
            child: inner,
          )
        : inner;

    if (!online) return ringed;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ringed,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HmColors.success,
              border: Border.all(color: HmColors.bg, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
