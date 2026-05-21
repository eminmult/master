import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// First-launch language picker. Shown when no `i18n_lang` value is stored in
/// SharedPreferences. Once the user picks here every subsequent surface
/// (header chip, /auth/me lang sync, etc.) finds the right locale on next
/// start.
class LanguagePickerPage extends ConsumerStatefulWidget {
  const LanguagePickerPage({super.key});
  @override
  ConsumerState<LanguagePickerPage> createState() => _LanguagePickerPageState();
}

class _LanguagePickerPageState extends ConsumerState<LanguagePickerPage>
    with TickerProviderStateMixin {
  String? _pending;
  int _greetingIdx = 0;
  Timer? _rotator;
  late final AnimationController _bgCtrl;
  late final AnimationController _enterCtrl;

  // (locale code, ISO-3166 country code for flag asset, native name, greeting)
  static const _options = <(String, String, String, String)>[
    ('az', 'az', 'Azərbaycan', 'Xoş gəldiniz'),
    ('ru', 'ru', 'Русский', 'Добро пожаловать'),
    ('en', 'gb', 'English', 'Welcome'),
    ('tr', 'tr', 'Türkçe', 'Hoş geldiniz'),
    ('ar', 'sa', 'العربية', 'أهلاً وسهلاً'),
  ];

  @override
  void initState() {
    super.initState();
    // Slow gradient drift in the background — never finishes, just loops.
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))
      ..repeat(reverse: true);
    // One-shot fade/slide-in on mount.
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    // Rotate the greeting through all 5 locales every 2.2s so even users
    // who can't read the headline word see THEIR language in motion and
    // know this app speaks it.
    _rotator = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _greetingIdx = (_greetingIdx + 1) % _options.length);
    });
  }

  @override
  void dispose() {
    _rotator?.cancel();
    _bgCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _choose(String code) async {
    setState(() => _pending = code);
    await ref.read(localeControllerProvider.notifier).setLocale(Locale(code));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _options[_greetingIdx];
    return Scaffold(
      // Full-bleed brand yellow — onboarding is the "wow" first impression,
      // so we lean into the brand colour. Hero text + cards switch to dark
      // for legible contrast.
      backgroundColor: HmColors.accent,
      body: Stack(
        children: [
          // Animated soft black blobs drifting on the yellow — adds depth
          // without overpowering the brand colour.
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              final t = _bgCtrl.value;
              return Stack(children: [
                Positioned(
                  left: -150 + t * 100,
                  top: -120 + t * 60,
                  child: _Blob(color: Colors.black.withOpacity(0.10), size: 360),
                ),
                Positioned(
                  right: -120 - t * 80,
                  bottom: -60 + t * 40,
                  child: _Blob(color: Colors.black.withOpacity(0.06), size: 280),
                ),
              ]);
            },
          ),
          // Foreground.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === Hero ===
                  Expanded(
                    flex: 5,
                    child: FadeTransition(
                      opacity: _enterCtrl,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero)
                            .animate(_enterCtrl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated mark: yellow square with bouncing chevron
                            const _LogoMark(),
                            const SizedBox(height: 24),
                            const Text('itez.app',
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    // Dark text on yellow — maximum contrast.
                                    color: Color(0xFF0A0A0A),
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 18),
                            // Greeting rotates through all 5 languages.
                            // AnimatedSwitcher cross-fades each change.
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
                                      .animate(anim),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                greeting.$4,
                                key: ValueKey(greeting.$1),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0A0A0A),
                                    letterSpacing: -0.3),
                                textDirection: greeting.$1 == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Choose your language',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  // Mid-opacity black for the helper line.
                                  color: Color(0xCC0A0A0A),
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // === Language list ===
                  Expanded(
                    flex: 6,
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: _enterCtrl, curve: const Interval(0.25, 1.0)),
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemBuilder: (_, i) {
                          final o = _options[i];
                          return _LangCard(
                            code: o.$1,
                            countryCode: o.$2,
                            native: o.$3,
                            sample: o.$4,
                            busy: _pending == o.$1,
                            onTap: _pending == null ? () => _choose(o.$1) : null,
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _options.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatefulWidget {
  const _LogoMark();
  @override
  State<_LogoMark> createState() => _LogoMarkState();
}

class _LogoMarkState extends State<_LogoMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final scale = 1.0 + _c.value * 0.06;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              // Inverse mark on the yellow page — black square with yellow
              // tool icon. The soft pulse uses a dark halo instead of yellow.
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 28 + _c.value * 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.handyman_rounded, size: 44, color: HmColors.accent),
            ),
          ),
        );
      },
    );
  }
}

/// Soft radial blob used in the background gradient.
class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    required this.code,
    required this.countryCode,
    required this.native,
    required this.sample,
    required this.busy,
    required this.onTap,
  });
  final String code;
  final String countryCode;
  final String native;
  final String sample;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HmRadius.cardLarge),
        child: Ink(
          decoration: BoxDecoration(
            // Dark cards on the yellow page — high contrast pop.
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(HmRadius.cardLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Real country flag — SVG from flagcdn, bundled as an asset
              // (offline-safe). Clipped to a rounded rect so it matches the
              // language pill aesthetic on the rest of the card.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 46,
                  height: 32,
                  child: SvgPicture.asset(
                    'assets/flags/$countryCode.svg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(native,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      sample,
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55)),
                      textDirection: code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: HmColors.accent),
                )
              else
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HmColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF0A0A0A)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
