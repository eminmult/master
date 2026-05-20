import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/smart_search/data/smart_search_repository.dart';

/// Hero AI search panel on the home screen.
///
/// Stays consistent with the rest of the dark-first design system: the
/// outer card is `HmColors.surface` like every other elevated card, the
/// inner input matches the global pill input style. The yellow accent is
/// expressed only through (a) a subtle accent border, (b) the accent glow
/// shadow, (c) the AI badge pill, and (d) the primary submit FilledButton —
/// never as a body fill, so the section reads as "ours" instead of an
/// alien yellow stripe.
class SmartSearchWidget extends ConsumerStatefulWidget {
  const SmartSearchWidget({super.key});

  @override
  ConsumerState<SmartSearchWidget> createState() => _SmartSearchWidgetState();
}

class _SmartSearchWidgetState extends ConsumerState<SmartSearchWidget> {
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageMime;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        setState(() => _error = context.l10n.smart_error);
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageMime = file.mimeType ?? _guessMime(file.name);
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.smart_error);
    }
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  void _clearPhoto() {
    setState(() {
      _imageBytes = null;
      _imageMime = null;
    });
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _imageBytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(smartSearchRepositoryProvider);
      final result = await repo.classify(
        description: text,
        image: _imageBytes != null ? base64Encode(_imageBytes!) : null,
        imageMime: _imageMime,
      );

      String? slug;
      String? localizedName;
      if (result.categoryId != null) {
        try {
          final cats = await ref.read(categoriesRepositoryProvider).list();
          final cat = cats
              .where((c) => c.id == result.categoryId)
              .cast<ServiceCategory?>()
              .firstWhere((c) => true, orElse: () => null);
          slug = cat?.slug;
          localizedName = cat?.name;
        } catch (_) {/* fall back to /categories */}
      }

      if (!mounted) return;
      if (slug != null) {
        context.push('/list/$slug', extra: result.title ?? localizedName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.smart_no_match),
          backgroundColor: HmColors.surface,
        ));
        context.push('/categories');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.smart_error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final hasInput = _ctrl.text.trim().isNotEmpty || _imageBytes != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.cardLarge),
        border: Border.all(color: HmColors.accentBorder, width: 1),
        boxShadow: HmShadows.accentGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI accent badge — uses the same accentSoft pill pattern as other
          // tag/badge chips in the app (master detail, order labels).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: HmColors.accentSoft,
              borderRadius: BorderRadius.circular(HmRadius.pill),
              border: Border.all(color: HmColors.accentBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome_rounded, size: 12, color: HmColors.accent),
              const SizedBox(width: 6),
              Text('AI · ${loc.smart_find}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: HmColors.accent,
                    letterSpacing: 0.6,
                  )),
            ]),
          ),
          const SizedBox(height: 10),
          // Multiline input. Relies on the global `InputDecorationTheme` for
          // fill/border/hint styling — same look as the search field on the
          // specialist list and the auth forms. We only override the border
          // radius to 16 (cardLarge-1) so the multi-line shape doesn't read
          // as a bloated pill at 3-4 lines tall.
          TextField(
            controller: _ctrl,
            minLines: 2,
            maxLines: 4,
            maxLength: 2000,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            cursorColor: HmColors.accent,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: HmColors.text,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: loc.smart_placeholder,
              hintMaxLines: 3,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: HmColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: HmColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: HmColors.accentBorder, width: 1.5),
              ),
            ),
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(children: [
                Image.memory(_imageBytes!,
                    height: 160, width: double.infinity, fit: BoxFit.cover),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black.withOpacity(0.7),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : _clearPhoto,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(Icons.close_rounded, color: HmColors.text, size: 16),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x1AEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x33EF4444)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: HmColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(fontSize: 12, color: HmColors.danger, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          // Action row — secondary outlined photo pill on the left, primary
          // accent FilledButton on the right (matches global filledButtonTheme).
          Row(children: [
            _PhotoButton(
              hasPhoto: _imageBytes != null,
              attachLabel: loc.smart_attach_photo,
              attachedLabel: loc.smart_photo_attached,
              onTap: _busy ? null : _pickPhoto,
            ),
            const Spacer(),
            SizedBox(
              height: 42,
              child: FilledButton.icon(
                onPressed: (!_busy && hasInput) ? _submit : null,
                icon: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
                label: Text(_busy ? loc.smart_analyzing : loc.smart_find,
                    style: const TextStyle(color: Colors.black)),
                style: FilledButton.styleFrom(
                  // Explicit pure-yellow override — Material 3 surface tint
                  // can wash out the global filledButtonTheme accent on
                  // dark surfaces, so we pin it here.
                  backgroundColor: HmColors.accent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: HmColors.accentSoft,
                  disabledForegroundColor: HmColors.accent,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Outlined secondary pill — same pattern as the "filter / category" chips
/// elsewhere in the app: transparent fill + faint border + white text, with
/// an accent fill flip when the photo is attached.
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.hasPhoto,
    required this.attachLabel,
    required this.attachedLabel,
    required this.onTap,
  });

  final bool hasPhoto;
  final String attachLabel;
  final String attachedLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasPhoto ? HmColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(HmRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HmRadius.pill),
            border: Border.all(
              color: hasPhoto ? HmColors.accentBorder : HmColors.border2,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              hasPhoto ? Icons.photo_rounded : Icons.photo_camera_outlined,
              size: 14,
              color: hasPhoto ? HmColors.accent : HmColors.text3,
            ),
            const SizedBox(width: 6),
            Text(
              hasPhoto ? attachedLabel : attachLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasPhoto ? HmColors.accent : HmColors.text3,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
