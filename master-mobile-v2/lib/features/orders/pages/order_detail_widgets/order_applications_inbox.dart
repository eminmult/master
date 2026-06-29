import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/common/widgets/hm_avatar.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/applications/models/order_application.dart';
import 'package:itez_mobile/features/orders/bloc/order_detail_bloc.dart';

/// Список откликов мастеров — показывается клиенту, пока статус =
/// `searching_master`. Тап на карточку — открывает страницу мастера.
class OrderApplicationsInbox extends StatefulWidget {
  const OrderApplicationsInbox({super.key});

  @override
  State<OrderApplicationsInbox> createState() => _OrderApplicationsInboxState();
}

class _OrderApplicationsInboxState extends State<OrderApplicationsInbox> {
  @override
  void initState() {
    super.initState();
    context.read<OrderDetailBloc>().add(const OrderApplicationsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailBloc, OrderDetailState>(
      buildWhen: (p, c) =>
          p.applications != c.applications ||
          p.applicationsLoading != c.applicationsLoading,
      builder: (context, state) {
        if (state.applicationsLoading && state.applications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.4,
              ),
            ),
          );
        }
        if (state.applications.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.inbox_outlined,
                    color: AppColors.text5, size: 36),
                const SizedBox(height: 8),
                Text(
                  context.l10n.order_no_applications,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text4,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: state.applications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _AppCard(application: state.applications[i]),
        );
      },
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.application});
  final OrderApplication application;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final master = application.master ?? const <String, dynamic>{};
    final fn = master['first_name']?.toString() ?? '';
    final ln = master['last_name']?.toString() ?? '';
    final name = '$fn $ln'.trim();
    final avatar = master['avatar_url']?.toString();
    final rating = parseDoubleOrNull(master['rating_avg']);
    final ratingCount = parseInt(master['rating_count']);
    final mp = master['master_profile'];
    final years = mp is Map ? parseInt(mp['experience_years']) : 0;
    final completed =
        mp is Map ? parseInt(mp['completed_orders_count']) : 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.router.push(
          MasterDetailRoute(idOrSlug: '${application.masterId}'),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (avatar != null && avatar.isNotEmpty)
                    HmAvatar(url: avatar, size: 44, ring: true)
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface2,
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 22, color: AppColors.text4),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name.isEmpty ? '—' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (rating != null && rating > 0) ...[
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 13),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text2,
                                ),
                              ),
                              if (ratingCount > 0) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '($ratingCount)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.text5,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                            ],
                            if (years > 0)
                              Text(
                                l.master_meta_years(years),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.text4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (years > 0 && completed > 0) ...[
                              const SizedBox(width: 6),
                              const Text('·',
                                  style: TextStyle(color: AppColors.text5)),
                              const SizedBox(width: 6),
                            ],
                            if (completed > 0)
                              Text(
                                l.master_meta_completed(completed),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.text4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (application.proposedPrice != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${application.proposedPrice!.toStringAsFixed(0)} ₼',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
              if (application.message != null &&
                  application.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  application.message!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text3,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.router.push(
                    MasterDetailRoute(idOrSlug: '${application.masterId}'),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: Text(l.master_view_profile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
