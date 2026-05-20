import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/notifications/data/notifications_providers.dart';

/// Bell icon button used in the home header. Watches the unread-count
/// stream and:
///  • paints the bell solid yellow when count > 0 (vs muted outline at 0),
///  • adds a small accent badge with the number,
///  • shakes the icon every ~3 seconds while there is an unread item.
///
/// Tap → caller-provided onTap (typically `context.push('/notifications')`).
class HmNotificationBell extends ConsumerStatefulWidget {
  const HmNotificationBell({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  ConsumerState<HmNotificationBell> createState() => _HmNotificationBellState();
}

class _HmNotificationBellState extends ConsumerState<HmNotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  Timer? _scheduler;
  int _lastUnread = 0;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _scheduler?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _ensureScheduler(int unread) {
    if (unread > 0 && _scheduler == null) {
      // Initial nudge so the bell shakes immediately when count goes 0→N.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shake.status == AnimationStatus.dismissed) {
          _shake.forward(from: 0);
        }
      });
      _scheduler = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        if (_shake.status == AnimationStatus.dismissed) {
          _shake.forward(from: 0);
        }
      });
    } else if (unread == 0 && _scheduler != null) {
      _scheduler?.cancel();
      _scheduler = null;
      _shake.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => _lastUnread);
    if (unread != _lastUnread) _lastUnread = unread;
    _ensureScheduler(unread);

    final hasUnread = unread > 0;

    return InkResponse(
      onTap: widget.onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasUnread ? HmColors.accentSoft : HmColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: hasUnread ? HmColors.accentBorder : HmColors.border2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _shake,
              builder: (_, child) {
                // Damped sine: 4 cycles over the animation, fading amplitude.
                final t = _shake.value;
                final angle = hasUnread
                    ? math.sin(t * math.pi * 8) * 0.30 * (1 - t)
                    : 0.0;
                return Transform.rotate(angle: angle, child: child);
              },
              child: Icon(
                hasUnread ? Icons.notifications_rounded : Icons.notifications_outlined,
                size: 20,
                color: hasUnread ? HmColors.accent : HmColors.text3,
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: HmColors.accent,
                    borderRadius: BorderRadius.circular(HmRadius.pill),
                    border: Border.all(color: HmColors.bg, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
