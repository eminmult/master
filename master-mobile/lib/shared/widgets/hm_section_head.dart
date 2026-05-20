import 'package:flutter/material.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

class HmSectionHead extends StatelessWidget {
  const HmSectionHead({super.key, required this.title, this.linkLabel, this.onLinkTap});

  final String title;
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: HmColors.text,
            ),
          ),
          if (linkLabel != null)
            TextButton(
              onPressed: onLinkTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                linkLabel!,
                style: const TextStyle(fontSize: 14, color: HmColors.accent, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}
