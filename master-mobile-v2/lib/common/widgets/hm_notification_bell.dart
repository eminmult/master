import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/notifications/bloc/notifications_bloc.dart';

/// Bell icon button — точный порт из master-mobile.
///
/// 44×44 круг; смотрит на `NotificationsBloc.unreadCount`:
///  - paints the bell solid yellow when count > 0 (vs muted outline at 0)
///  - accent badge (16×16 round) с числом, "99+" если >99
///  - shake-анимация каждые ~3 сек когда есть unread
class HmNotificationBell extends StatefulWidget {
  const HmNotificationBell({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<HmNotificationBell> createState() => _HmNotificationBellState();
}

class _HmNotificationBellState extends State<HmNotificationBell>
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
    // На первом построении NotificationsBloc уже может содержать unread —
    // подтянем счётчик мягко (одиночный refresh).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<NotificationsBloc>()
          .add(const NotificationsUnreadRefreshed());
    });
  }

  @override
  void dispose() {
    _scheduler?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _ensureScheduler(int unread) {
    if (unread > 0 && _scheduler == null) {
      // initial nudge: 0→N сразу даёт shake.
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
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (p, c) => p.unreadCount != c.unreadCount,
      builder: (context, state) {
        final unread = state.unreadCount;
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
              color: hasUnread ? AppColors.accentSoft : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: hasUnread ? AppColors.accent : AppColors.border2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) {
                    final t = _shake.value;
                    final angle = hasUnread
                        ? math.sin(t * math.pi * 8) * 0.30 * (1 - t)
                        : 0.0;
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: Icon(
                    hasUnread
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    size: 20,
                    color: hasUnread ? AppColors.accent : AppColors.text3,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.bg, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
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
      },
    );
  }
}
