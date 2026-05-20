import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/calls/data/call_service.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';

/// Full-screen call UI mounted globally over the router. Renders nothing when
/// [CallService.state.phase] is idle so it has zero hit-area outside an active
/// call.
class CallOverlay extends ConsumerWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(callServiceProvider);
    final s = svc.state;
    if (s.phase == CallPhase.idle) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;

    final name = (s.peerName?.isNotEmpty ?? false) ? s.peerName! : loc.call_unknown_caller;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    String stateLabel;
    switch (s.phase) {
      case CallPhase.dialing:
        stateLabel = loc.call_dialing;
        break;
      case CallPhase.incoming:
        stateLabel = loc.call_incoming;
        break;
      case CallPhase.inCall:
        stateLabel = _fmt(s.durationSec);
        break;
      case CallPhase.ended:
        stateLabel = s.durationSec > 0
            ? '${loc.call_ended} · ${_fmt(s.durationSec)}'
            : loc.call_ended;
        break;
      case CallPhase.idle:
        stateLabel = '';
        break;
    }

    return Material(
      color: Colors.black.withOpacity(0.92),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Avatar(
                pulsing: s.phase == CallPhase.incoming,
                avatarUrl: s.peerAvatar,
                initial: initial,
              ),
              const SizedBox(height: 22),
              Text(name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(stateLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (s.error != null) ...[
                const SizedBox(height: 12),
                Text(s.error!,
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 13),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 40),
              _Actions(svc: svc),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Avatar extends StatefulWidget {
  const _Avatar({required this.pulsing, required this.avatarUrl, required this.initial});
  final bool pulsing;
  final String? avatarUrl;
  final String initial;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HmColors.accent,
        image: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
            ? DecorationImage(image: NetworkImage(widget.avatarUrl!), fit: BoxFit.cover)
            : null,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 3),
      ),
      alignment: Alignment.center,
      child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
          ? Text(widget.initial,
              style: const TextStyle(color: Colors.black, fontSize: 38, fontWeight: FontWeight.w800))
          : null,
    );
    if (!widget.pulsing) return core;
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, child) {
        final t = _ac.value;
        final scale = 1.0 + t * 0.5;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Stack(alignment: Alignment.center, children: [
          IgnorePointer(
            ignoring: true,
            child: Container(
              width: 112 * scale,
              height: 112 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withOpacity(opacity * 0.4),
              ),
            ),
          ),
          child!,
        ]);
      },
      child: core,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.svc});
  final CallService svc;

  @override
  Widget build(BuildContext context) {
    final s = svc.state;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (s.phase == CallPhase.incoming) ...[
        _RoundBtn(icon: Icons.call_end_rounded, color: const Color(0xFFEF4444), onTap: svc.reject),
        const SizedBox(width: 26),
        _RoundBtn(icon: Icons.call_rounded, color: const Color(0xFF22C55E), onTap: svc.accept),
      ] else if (s.phase == CallPhase.dialing || s.phase == CallPhase.inCall) ...[
        _RoundBtn(
          icon: s.micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: s.micMuted ? const Color(0xFFF59E0B) : const Color(0xFF2A2A2A),
          onTap: svc.toggleMic,
        ),
        const SizedBox(width: 26),
        _RoundBtn(icon: Icons.call_end_rounded, color: const Color(0xFFEF4444), onTap: svc.end),
      ] else if (s.phase == CallPhase.ended) ...[
        _RoundBtn(icon: Icons.close_rounded, color: const Color(0xFF2A2A2A), onTap: svc.dismiss),
      ],
    ]);
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
