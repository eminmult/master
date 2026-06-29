import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/orders/bloc/order_detail_bloc.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_sheets/callout_fee_sheet.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_sheets/order_cancel_sheet.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_sheets/order_confirm_work_sheet.dart';

/// Контекстные баннеры + кнопки действий, зависящие от роли и статуса.
///
/// Закрывает большую часть UX в одной точке — оригинал master-mobile имеет
/// 6+ отдельных классов prompt'ов (Warn24h, MasterPendingButtons,
/// ClientProposalPrompt, MasterAdvanceButtons и т.д.); здесь они собраны
/// в pattern-match по статусу.
class OrderActionPrompt extends StatelessWidget {
  const OrderActionPrompt({
    super.key,
    required this.order,
    required this.isClient,
    required this.mutating,
  });
  final OrderModel order;
  final bool isClient;
  final bool mutating;

  @override
  Widget build(BuildContext context) {
    final isMaster = !isClient;
    final bloc = context.read<OrderDetailBloc>();
    final showWarn24h = _showWarn24h(order);

    Widget? content;

    // --- Master в pendingMaster: принять/отказать ---
    if (isMaster && order.status == OrderStatus.pendingMaster) {
      content = _PromptRow(
        title: context.l10n.order_pending_master_q,
        children: [
          Expanded(
            child: _OutlineBtn(
              label: context.l10n.order_action_decline,
              destructive: true,
              mutating: mutating,
              onTap: () => bloc.add(const OrderDeclined()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilledBtn(
              label: context.l10n.order_action_accept,
              mutating: mutating,
              onTap: () => bloc.add(const OrderAccepted()),
            ),
          ),
        ],
      );
    }
    // --- Client получил proposal от мастера: принять/отклонить ---
    else if (isClient && order.status == OrderStatus.pendingClient) {
      final agreedPrice = parseDoubleOrNull(order.raw['agreed_price']);
      content = _PromptRow(
        title: context.l10n.order_proposal_q,
        subtitle: agreedPrice != null
            ? '${agreedPrice.toStringAsFixed(0)} ₼'
            : null,
        children: [
          Expanded(
            child: _OutlineBtn(
              label: context.l10n.order_action_reject_proposal,
              destructive: true,
              mutating: mutating,
              onTap: () => bloc.add(const OrderRejectProposal()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilledBtn(
              label: context.l10n.order_action_accept_proposal,
              mutating: mutating,
              onTap: () => bloc.add(const OrderConfirmRequested()),
            ),
          ),
        ],
      );
    }
    // --- Master advance: status pipeline ---
    else if (isMaster && _masterCanAdvance(order.status)) {
      final next = _nextStatusForMaster(order.status);
      final label = _labelForNext(context, next);
      content = _PrimaryAction(
        label: label,
        mutating: mutating,
        onTap: () {
          if (next == 'awaiting_completion') {
            _showConfirmWork(context, bloc);
          } else {
            bloc.add(OrderStatusUpdated(next));
          }
        },
      );
    }
    // --- Client в pendingPayment: оплата callout fee ---
    else if (isClient && order.status == OrderStatus.pendingPayment) {
      content = _PromptRow(
        title: context.l10n.callout_modal_title,
        subtitle: context.l10n.callout_modal_subtitle,
        children: [
          Expanded(
            child: _FilledBtn(
              label: context.l10n.callout_pay_btn('25'),
              mutating: mutating,
              onTap: () => _openCalloutSheet(context, bloc, order.id),
            ),
          ),
        ],
      );
    }
    // --- Client в pendingMaster (ждёт ответа мастера) — info-баннер ---
    else if (isClient && order.status == OrderStatus.pendingMaster) {
      content = _InfoBanner(
        icon: Icons.schedule_rounded,
        text: context.l10n.order_waiting_master,
      );
    }

    if (content == null && !showWarn24h) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          if (showWarn24h) ...[
            _Warn24h(isClient: isClient),
            const SizedBox(height: 8),
          ],
          if (content != null)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: AppColors.accent),
                boxShadow: AppShadows.accentGlow,
              ),
              child: content,
            ),
        ],
      ),
    );
  }

  /// 24h watch — для pendingMaster/searching. created_at старше суток =>
  /// бэкенд скоро автоматически отменит заказ, надо предупредить.
  static bool _showWarn24h(OrderModel order) {
    if (order.status != OrderStatus.pendingMaster &&
        order.status != OrderStatus.searching) {
      return false;
    }
    final created = parseDate(order.raw['created_at']);
    if (created == null) return false;
    return DateTime.now().difference(created) > const Duration(hours: 24);
  }

  static bool _masterCanAdvance(OrderStatus s) => const {
        OrderStatus.confirmed,
        OrderStatus.accepted,
        OrderStatus.onTheWay,
        OrderStatus.arrived,
        OrderStatus.inProgress,
      }.contains(s);

  static String _nextStatusForMaster(OrderStatus s) => switch (s) {
        OrderStatus.confirmed || OrderStatus.accepted => 'on_the_way',
        OrderStatus.onTheWay => 'arrived',
        OrderStatus.arrived => 'in_progress',
        OrderStatus.inProgress => 'awaiting_completion',
        _ => 'in_progress',
      };

  static String _labelForNext(BuildContext context, String s) =>
      switch (s) {
        'on_the_way' => context.l10n.order_action_on_the_way,
        'arrived' => context.l10n.order_action_arrived,
        'in_progress' => context.l10n.order_action_start_work,
        'awaiting_completion' => context.l10n.order_action_confirm_work,
        _ => context.l10n.order_action_start_work,
      };

  Future<void> _openCalloutSheet(
      BuildContext context, OrderDetailBloc bloc, int orderId) async {
    final paid = await showCalloutFeeSheet(context, orderId: orderId);
    if (paid && context.mounted) {
      bloc.add(OrderDetailRequested(orderId, publicFallback: false));
    }
  }

  void _showConfirmWork(BuildContext context, OrderDetailBloc bloc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cardLarge),
        ),
      ),
      builder: (_) => OrderConfirmWorkSheet(
        initialPrice: parseDoubleOrNull(order.raw['agreed_price']) ??
            order.estimatedBudget,
        onSubmit: (price, date, note) {
          bloc.add(OrderConfirmWork(
            price: price,
            completedAt: date,
            note: note,
          ));
        },
      ),
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.title,
    this.subtitle,
    required this.children,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.accent,
              letterSpacing: -0.3,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: children),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.mutating,
    required this.onTap,
  });
  final String label;
  final bool mutating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FilledBtn(label: label, mutating: mutating, onTap: onTap);
  }
}

class _FilledBtn extends StatelessWidget {
  const _FilledBtn({
    required this.label,
    required this.mutating,
    required this.onTap,
  });
  final String label;
  final bool mutating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: mutating ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.black,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        child: mutating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.mutating,
    required this.onTap,
    this.destructive = false,
  });
  final String label;
  final bool mutating;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.danger : AppColors.text;
    final border =
        destructive ? const Color(0x4DEF4444) : AppColors.border2;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: mutating
            ? null
            : (destructive
                ? () => _confirmDestructive(context, onTap)
                : onTap),
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          shape: const StadiumBorder(),
          side: BorderSide(color: border),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  void _confirmDestructive(BuildContext context, VoidCallback action) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(context.l10n.order_cancel_confirm_title),
        content: Text(context.l10n.order_cancel_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.l10n.order_cancel_keep),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              action();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text3,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Warn24h extends StatelessWidget {
  const _Warn24h({required this.isClient});
  final bool isClient;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0x1FEF4444),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4DEF4444)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isClient
                  ? l.order_pending_master_24h_warning_client
                  : l.order_pending_master_24h_warning,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.danger,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Хелпер: показать cancel sheet с reason.
void showOrderCancelSheet(BuildContext context, OrderDetailBloc bloc) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.cardLarge),
      ),
    ),
    builder: (_) => OrderCancelSheet(
      onSubmit: (reason) => bloc.add(OrderCancelRequested(reason: reason)),
    ),
  );
}
