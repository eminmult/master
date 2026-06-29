import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';
import 'package:itez_mobile/features/smart_search/bloc/smart_search_bloc.dart';

/// Inline AI search panel на главной — точный порт `smart_search_widget.dart`
/// из master-mobile.
///
/// Surface фон + accent border + accent-glow тень. AI-badge сверху, multiline
/// textarea, опциональное превью прикреплённого фото (160h), error-плашка,
/// внизу Row(PhotoButton, Spacer, "Найти" FilledButton 42h).
class SmartSearchWidget extends StatelessWidget {
  const SmartSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SmartSearchBloc(
        client: locator<ApiClient>(),
        categories: locator<CategoryRepository>(),
        masters: locator<MasterRepository>(),
      ),
      child: const _SmartSearchBody(),
    );
  }
}

class _SmartSearchBody extends StatefulWidget {
  const _SmartSearchBody();

  @override
  State<_SmartSearchBody> createState() => _SmartSearchBodyState();
}

class _SmartSearchBodyState extends State<_SmartSearchBody> {
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageMime;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
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
      if (mounted) {
        setState(() => _error = context.l10n.smart_error);
      }
    }
  }

  String _guessMime(String name) {
    final l = name.toLowerCase();
    if (l.endsWith('.png')) return 'image/png';
    if (l.endsWith('.webp')) return 'image/webp';
    if (l.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  void _clearPhoto() => setState(() {
        _imageBytes = null;
        _imageMime = null;
      });

  void _submit(BuildContext blocCtx) {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _imageBytes == null) return;
    setState(() => _error = null);
    blocCtx.read<SmartSearchBloc>().add(SmartSearchSubmitted(
          description: text,
          photos: _imageBytes != null ? [base64Encode(_imageBytes!)] : const [],
          imageMime: _imageMime,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SmartSearchBloc, SmartSearchState>(
      listener: (ctx, state) {
        if (state is SmartSearchSuggested) {
          final slug = state.suggestedCategory?.slug;
          if (slug != null && slug.isNotEmpty) {
            ctx.router.push(MastersListRoute(
              categoryId: state.suggestedCategory!.id,
              categoryName: state.title ?? state.suggestedCategory!.name,
              initialSearch: state.title,
            ));
          } else {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(ctx.l10n.smart_no_match)),
            );
          }
          // Сбрасываем UI, чтобы при возврате на home поле было пустое.
          ctx.read<SmartSearchBloc>().add(const SmartSearchReset());
          _ctrl.clear();
          _clearPhoto();
        } else if (state is SmartSearchFailed) {
          setState(() => _error = state.message);
        }
      },
      builder: (ctx, state) {
        final busy = state is SmartSearchAnalyzing;
        final hasInput =
            _ctrl.text.trim().isNotEmpty || _imageBytes != null;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.accent, width: 1),
            boxShadow: AppShadows.accentGlow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 12, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'AI · ${ctx.l10n.smart_find}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ctrl,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                enabled: !busy,
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.accent,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: ctx.l10n.smart_placeholder,
                  hintMaxLines: 3,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.memory(
                        _imageBytes!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.black.withOpacity(0.7),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: busy ? null : _clearPhoto,
                            child: const SizedBox(
                              width: 28,
                              height: 28,
                              child: Icon(Icons.close_rounded,
                                  color: AppColors.text, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x1AEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33EF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _PhotoButton(
                    hasPhoto: _imageBytes != null,
                    onTap: busy ? null : _pickPhoto,
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: (!busy && hasInput) ? () => _submit(ctx) : null,
                      icon: busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.black,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: AppColors.black),
                      label: Text(
                        busy ? ctx.l10n.smart_analyzing : ctx.l10n.smart_find,
                        style: const TextStyle(color: AppColors.black),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.black,
                        disabledBackgroundColor: AppColors.accentSoft,
                        disabledForegroundColor: AppColors.accent,
                        shape: const StadiumBorder(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18),
                        // Без override — глобальная тема даёт minimumSize
                        // (double.infinity, 54), что растягивает кнопку на
                        // весь Row и съедает PhotoButton + Spacer.
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Secondary pill: фото-attachment. Прозрачный с border при отсутствии фото,
/// accent-soft + accent-border + accent-icon при наличии — как в оригинале.
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.hasPhoto, required this.onTap});
  final bool hasPhoto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasPhoto ? AppColors.accentSoft : AppColors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: hasPhoto ? AppColors.accent : AppColors.border2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasPhoto ? Icons.photo_rounded : Icons.photo_camera_outlined,
                size: 14,
                color: hasPhoto ? AppColors.accent : AppColors.text3,
              ),
              const SizedBox(width: 6),
              Text(
                hasPhoto
                    ? context.l10n.smart_photo_attached
                    : context.l10n.smart_attach_photo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasPhoto ? AppColors.accent : AppColors.text3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
