import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/calls/bloc/call_bloc.dart';

/// UI текущего звонка. Сам [CallBloc] предоставляется выше по дереву
/// (через global singleton), эта страница только рендерит фазу.
@RoutePage()
class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandSecondary,
      body: SafeArea(
        child: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            final call = state.call;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
              child: Column(
                children: [
                  const Spacer(),
                  CircleAvatar(
                    radius: 56.r,
                    backgroundColor: AppColors.white.withOpacity(0.1),
                    child: Icon(Icons.person,
                        size: 64.r, color: AppColors.white),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    call == null
                        ? 'Звонок'
                        : 'Звонок #${call.id}',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _phaseLabel(state.phase),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.white.withOpacity(0.85),
                    ),
                  ),
                  if (state.error != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      state.error!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  const Spacer(),
                  _Controls(state: state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _phaseLabel(CallPhase p) => switch (p) {
        CallPhase.idle => 'Готов',
        CallPhase.outgoing => 'Идёт вызов…',
        CallPhase.incoming => 'Входящий вызов',
        CallPhase.connecting => 'Соединяем…',
        CallPhase.active => 'В разговоре',
        CallPhase.ended => 'Завершён',
        CallPhase.failed => 'Ошибка',
      };
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});
  final CallState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    if (state.phase == CallPhase.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CircleAction(
            icon: Icons.call_end,
            color: AppColors.danger,
            onTap: () => bloc.add(const CallRejected()),
          ),
          _CircleAction(
            icon: Icons.call,
            color: AppColors.success,
            onTap: () => bloc.add(const CallAccepted()),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleAction(
          icon: Icons.call_end,
          color: AppColors.danger,
          onTap: () => bloc.add(const CallHungUp()),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Container(
        width: 72.r,
        height: 72.r,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, size: 32.r, color: AppColors.white),
      ),
    );
  }
}
