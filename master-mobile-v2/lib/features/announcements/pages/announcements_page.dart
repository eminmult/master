import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/common/widgets/hm_avatar.dart';
import 'package:itez_mobile/common/widgets/hm_icon_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/features/announcements/bloc/announcements_bloc.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';

/// Public order feed — порт `announcements_page.dart` master-mobile.
///
/// Заголовок «Объявления» + подзаголовок «N активных», поверх Scaffold.bg.
/// Карточка — surface + accent-soft pill категории + аватарка клиента +
/// фото-preview 140h с `+N` badge, описание 3 строки, бюджет справа.
@RoutePage()
class AnnouncementsPage extends StatelessWidget implements AutoRouteWrapper {
  const AnnouncementsPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    // Глобальный AnnouncementsBloc из App.MultiBlocProvider — повторно
    // не создаём, только триггерим первый запрос если ещё пуст.
    final bloc = context.read<AnnouncementsBloc>();
    if (bloc.state.items.isEmpty && !bloc.state.loading) {
      bloc.add(const AnnouncementsRequested());
    }
    return this;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  HmIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    small: true,
                    flat: true,
                    onTap: () => context.router.canPop()
                        ? context.router.maybePop()
                        : context.router
                            .replaceAll([const HomeRoute()]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
                        buildWhen: (p, c) =>
                            p.items.length != c.items.length ||
                            p.loading != c.loading,
                        builder: (context, state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l.ann_title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: AppColors.text,
                                ),
                              ),
                              if (!state.loading || state.items.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    l.ann_subtitle_n(state.items.length),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.text5,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
                builder: (context, state) {
                  if (state.loading && state.items.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    );
                  }
                  if (state.error != null && state.items.isEmpty) {
                    return Center(
                      child: Text(
                        l.auth_failed_to_load,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    );
                  }
                  if (state.items.isEmpty) {
                    return const _EmptyState();
                  }
                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async => context
                        .read<AnnouncementsBloc>()
                        .add(const AnnouncementsRefreshed()),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                                n.metrics.maxScrollExtent - 200 &&
                            !state.loadingMore &&
                            !state.endReached) {
                          context
                              .read<AnnouncementsBloc>()
                              .add(const AnnouncementsMoreRequested());
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(24, 0, 24, 110),
                        itemCount: state.items.length +
                            (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          if (i >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          final o = state.items[i];
                          return _AnnCard(
                            order: o,
                            onTap: () => context.router
                                .push(OrderDetailRoute(id: o.id)),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded,
                color: AppColors.text5, size: 48),
            const SizedBox(height: 12),
            Text(
              l.ann_empty_title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text4,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.ann_empty_desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text5,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка объявления — точный layout из оригинала.
class _AnnCard extends StatelessWidget {
  const _AnnCard({required this.order, required this.onTap});
  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final categoryName = order.categoryName ?? l.order_service_fallback;
    final budget = order.estimatedBudget;
    final clientAvatar = order.client?.avatarUrl;
    final clientName = order.client?.firstName ?? l.common_user;

    // District — первая часть `fullAddress` до запятой.
    String? district;
    final full = order.fullAddress;
    if (full != null && full.isNotEmpty) {
      district = full.split(',').first.trim();
    }

    // Photo preview.
    final hasPhoto = order.photos.isNotEmpty;
    final firstPhoto = hasPhoto ? order.photos.first.url : null;
    final photosCount = order.photos.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name + district
            Row(
              children: [
                if (clientAvatar != null && clientAvatar.isNotEmpty)
                  HmAvatar(url: clientAvatar, size: 36)
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface2,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.text5, size: 18),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (district != null && district.isNotEmpty)
                        Text(
                          district,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.text5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Photo preview + counter pill
            if (firstPhoto != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Image.network(
                          firstPhoto,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 140,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.surface2),
                        ),
                        if (photosCount > 1)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '+${photosCount - 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            // Category pill (accent-soft)
            Wrap(
              spacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            if (order.description != null &&
                order.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                order.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.text3,
                  height: 1.45,
                ),
              ),
            ],
            if (budget != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '~${budget.toStringAsFixed(0)} AZN',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
