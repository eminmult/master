import 'package:flutter/material.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:url_launcher/url_launcher.dart';

/// Picker «открыть в...»: Google Maps / Yandex / Waze.
class OrderNavigationSheet extends StatelessWidget {
  const OrderNavigationSheet({
    super.key,
    required this.lat,
    required this.lng,
  });
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.order_open_in_maps,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            _NavTile(
              label: 'Google Maps',
              icon: Icons.map_rounded,
              onTap: () => _open(context,
                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
            ),
            const SizedBox(height: 8),
            _NavTile(
              label: 'Yandex Карты',
              icon: Icons.directions_car_rounded,
              onTap: () async {
                final native = Uri.parse('yandexmaps://maps.yandex.ru/?pt=$lng,$lat&z=16');
                final web = Uri.parse('https://yandex.ru/maps/?pt=$lng,$lat&z=16');
                if (await canLaunchUrl(native)) {
                  await launchUrl(native, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(web, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            _NavTile(
              label: 'Waze',
              icon: Icons.navigation_rounded,
              onTap: () => _open(
                  context, 'https://waze.com/ul?ll=$lat,$lng&navigate=yes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.text5, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
