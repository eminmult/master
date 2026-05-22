import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/routing/tab_switcher.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/orders/data/models/order.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

final _orderForReviewProvider =
    FutureProvider.autoDispose.family<Order, int>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).show(id);
});

/// Review composer — same flow as the site's `components/ReviewForm.vue`
/// but built for one-handed mobile use:
///   • partner header (avatar + name + role) so the reviewer knows who
///     they're rating,
///   • huge centred star picker that works for thumbs,
///   • quick-tag pills (Punctual / Tidy / Polite / …) for fast feedback,
///   • free-text + up to 5 photos via camera/gallery.
class OrderReviewPage extends ConsumerStatefulWidget {
  const OrderReviewPage({super.key, required this.orderId});
  final int orderId;
  @override
  ConsumerState<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends ConsumerState<OrderReviewPage> {
  int _rating = 0;
  final _text = TextEditingController();
  final _photos = <_Photo>[];
  final _selectedTags = <String>{};
  bool _busy = false;
  bool _done = false;
  String? _error;

  static const _availableTags = <String>[
    'punctual', 'polite', 'professional', 'tidy', 'fast', 'fair_price',
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 5) return;
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: HmColors.accent),
              title: Text(context.l10n.chat_attach_camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: HmColors.accent),
              title: Text(context.l10n.chat_attach_gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );
    if (src == null) return;
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: src, maxWidth: 1600, imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.chat_photo_too_big),
            backgroundColor: HmColors.danger,
          ));
        }
        return;
      }
      final mime = file.mimeType ?? _guessMime(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() => _photos.add(_Photo(bytes: bytes, dataUrl: dataUrl)));
    } catch (_) {/* swallow */}
  }

  String _guessMime(String name) {
    final l = name.toLowerCase();
    if (l.endsWith('.png')) return 'image/png';
    if (l.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(ordersRepositoryProvider).review(
            widget.orderId,
            rating: _rating,
            text: _text.text.trim().isEmpty ? null : _text.text.trim(),
            tags: _selectedTags.toList(),
            photosBase64: _photos.map((p) => p.dataUrl).toList(),
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) ref.switchTab(context, AppTab.home);
      });
      return;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final asyncOrder = ref.watch(_orderForReviewProvider(widget.orderId));
    final auth = ref.watch(authStateProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    return PopScope(
      canPop: !_done,
      child: Scaffold(
      backgroundColor: HmColors.bg,
      body: Stack(children: [
        SafeArea(
        child: asyncOrder.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4),
          ),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(loc.auth_failed_to_load,
                  style: const TextStyle(color: HmColors.danger)),
            ),
          ),
          data: (order) {
            final isClient = user?.id == order.clientId;
            final partner = isClient ? order.master : order.client;
            return Column(children: [
              _Header(orderId: widget.orderId),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
                  children: [
                    _PartnerCard(partner: partner, isMaster: isClient),
                    const SizedBox(height: 18),
                    _Stars(rating: _rating, onChange: (r) => setState(() => _rating = r)),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(_ratingLabel(_rating, loc),
                          style: TextStyle(
                              fontSize: 13.5,
                              color: _rating == 0 ? HmColors.text5 : HmColors.accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3)),
                    ),
                    const SizedBox(height: 22),
                    if (_rating > 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SectionLabel(loc.review_tags_label),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _availableTags.map((t) {
                            final active = _selectedTags.contains(t);
                            return _TagChip(
                              label: _tagLabel(t, loc),
                              active: active,
                              onTap: () => setState(() {
                                if (active) {
                                  _selectedTags.remove(t);
                                } else {
                                  _selectedTags.add(t);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SectionLabel(loc.review_text_label),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: HmColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: HmColors.border2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: TextField(
                          controller: _text,
                          minLines: 4, maxLines: 8, maxLength: 1000,
                          style: const TextStyle(fontSize: 14, color: HmColors.text2, height: 1.45),
                          decoration: InputDecoration(
                            hintText: loc.review_text_hint,
                            hintStyle: const TextStyle(color: HmColors.text5, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        _SectionLabel(loc.review_photos_label),
                        const Spacer(),
                        Text('${_photos.length}/5',
                            style: const TextStyle(
                                fontSize: 11, color: HmColors.text5, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          ..._photos.asMap().entries.map((e) => _PhotoThumb(
                                bytes: e.value.bytes,
                                onRemove: () => setState(() => _photos.removeAt(e.key)),
                              )),
                          if (_photos.length < 5) _AddPhotoTile(onTap: _addPhoto),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: const Color(0x1FEF4444),
                            border: Border.all(color: const Color(0x4DEF4444)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: HmColors.danger),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: const TextStyle(color: HmColors.danger, fontSize: 12.5))),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Sticky submit bar
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(
                  color: HmColors.bg,
                  border: Border(top: BorderSide(color: HmColors.border2)),
                ),
                child: SizedBox(
                  width: double.infinity, height: 50,
                  child: FilledButton.icon(
                    onPressed: (_rating == 0 || _busy) ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black))
                        : const Icon(Icons.send_rounded, size: 16, color: Colors.black),
                    label: Text(_busy ? loc.review_sending : loc.review_submit,
                        style: const TextStyle(color: Colors.black)),
                    style: FilledButton.styleFrom(
                      backgroundColor: HmColors.accent,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      disabledBackgroundColor: HmColors.surface2,
                      disabledForegroundColor: HmColors.text5,
                    ),
                  ),
                ),
              ),
            ]);
          },
        ),
        ),
        if (_done) _SuccessOverlay(message: loc.review_thanks),
      ]),
    ),
    );
  }

  String _ratingLabel(int r, AppLocalizations loc) => switch (r) {
        0 => loc.review_label_pick,
        1 => loc.review_label_terrible,
        2 => loc.review_label_bad,
        3 => loc.review_label_ok,
        4 => loc.review_label_good,
        _ => loc.review_label_excellent,
      };

  String _tagLabel(String t, AppLocalizations loc) => switch (t) {
        'punctual' => loc.review_tag_punctual,
        'polite' => loc.review_tag_polite,
        'professional' => loc.review_tag_professional,
        'tidy' => loc.review_tag_tidy,
        'fast' => loc.review_tag_fast,
        'fair_price' => loc.review_tag_fair_price,
        _ => t,
      };
}

class _Photo {
  _Photo({required this.bytes, required this.dataUrl});
  final Uint8List bytes;
  final String dataUrl;
}

// === Header ===

class _Header extends StatelessWidget {
  const _Header({required this.orderId});
  final int orderId;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(children: [
        HmIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          small: true, flat: true,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/order/$orderId'),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(loc.review_leave,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
      ]),
    );
  }
}

// === Partner card (who is being reviewed) ===

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partner, required this.isMaster});
  final Map<String, dynamic>? partner;
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final fn = (partner?['first_name'] ?? '').toString();
    final ln = (partner?['last_name'] ?? '').toString();
    final name = '$fn $ln'.trim();
    final avatar = partner?['avatar_url']?.toString();
    final rating = double.tryParse(partner?['rating_avg']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x14FFFF00), Color(0x05FFFF00)],
          ),
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: HmColors.accentBorder),
        ),
        child: Row(children: [
          if (avatar != null && avatar.isNotEmpty)
            HmAvatar(url: avatar, size: 52, ring: true)
          else
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HmColors.surface,
                border: Border.all(color: HmColors.accentBorder, width: 1.5),
              ),
              child: Icon(
                  isMaster ? Icons.person_rounded : Icons.person_outline_rounded,
                  size: 24, color: HmColors.accent),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isMaster ? loc.review_for_master : loc.review_for_client,
                style: const TextStyle(
                    fontSize: 10, color: HmColors.accent,
                    fontWeight: FontWeight.w900, letterSpacing: 1.1),
              ),
              const SizedBox(height: 2),
              Text(name.isEmpty ? '—' : name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: HmColors.text, letterSpacing: -0.3)),
              if (rating != null && rating > 0) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 12, color: HmColors.accent),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: HmColors.accent)),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// === Star picker ===

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.onChange});
  final int rating;
  final ValueChanged<int> onChange;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final filled = i < rating;
          return GestureDetector(
            onTap: () => onChange(i + 1),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey(filled),
                  size: 48,
                  color: filled ? HmColors.accent : HmColors.text5,
                  shadows: filled
                      ? const [Shadow(color: Color(0x66FFFF00), blurRadius: 16)]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// === Section label / tag chip / photo thumb / add tile ===

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w900,
          color: HmColors.text4, letterSpacing: 1.2));
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? HmColors.accent : HmColors.surface,
      borderRadius: BorderRadius.circular(HmRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HmRadius.pill),
            border: Border.all(
                color: active ? HmColors.accent : HmColors.border2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (active) ...[
              const Icon(Icons.check_rounded, size: 13, color: Colors.black),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.black : HmColors.text3)),
          ]),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.bytes, required this.onRemove});
  final Uint8List bytes;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(bytes, width: 92, height: 92, fit: BoxFit.cover),
      ),
      Positioned(
        top: 4, right: 4,
        child: Material(
          color: Colors.black.withOpacity(0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: const SizedBox(
              width: 24, height: 24,
              child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: HmColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 92, height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HmColors.accentBorder, width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 24, color: HmColors.accent),
              SizedBox(height: 4),
              Text('+', style: TextStyle(
                  fontSize: 16, color: HmColors.accent, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

// === Success overlay shown after submit; auto-redirects to /home ===

class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay({required this.message});
  final String message;
  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _textCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..forward();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    Future.delayed(const Duration(milliseconds: 220),
        () { if (mounted) _checkCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 480),
        () { if (mounted) _textCtrl.forward(); });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _checkCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xE6000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140, height: 140,
                child: Stack(alignment: Alignment.center, children: [
                  // Glow
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) => Container(
                      width: 130 * Curves.easeOutCubic.transform(_ringCtrl.value),
                      height: 130 * Curves.easeOutCubic.transform(_ringCtrl.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HmColors.accentSoft,
                        boxShadow: const [
                          BoxShadow(color: Color(0x66FFFF00), blurRadius: 32, spreadRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  // Yellow disc
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) {
                      final v = Curves.elasticOut.transform(_ringCtrl.value.clamp(0.0, 1.0));
                      return Transform.scale(
                        scale: v,
                        child: Container(
                          width: 92, height: 92,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: HmColors.accent,
                          ),
                        ),
                      );
                    },
                  ),
                  // Animated checkmark
                  AnimatedBuilder(
                    animation: _checkCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(58, 58),
                      painter: _CheckPainter(_checkCtrl.value),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _textCtrl,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25), end: Offset.zero,
                  ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: HmColors.text,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p1 = Offset(size.width * 0.18, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.72);
    final p3 = Offset(size.width * 0.82, size.height * 0.30);
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (eased <= 0.5) {
      final k = eased / 0.5;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * k, p1.dy + (p2.dy - p1.dy) * k);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final k = (eased - 0.5) / 0.5;
      path.lineTo(p2.dx + (p3.dx - p2.dx) * k, p2.dy + (p3.dy - p2.dy) * k);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.t != t;
}
