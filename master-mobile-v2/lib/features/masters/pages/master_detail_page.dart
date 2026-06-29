import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/masters/bloc/master_detail_bloc.dart';
import 'package:itez_mobile/features/masters/models/master_detail.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';

@RoutePage()
class MasterDetailPage extends StatelessWidget implements AutoRouteWrapper {
  const MasterDetailPage({
    super.key,
    @PathParam('idOrSlug') required this.idOrSlug,
  });

  final String idOrSlug;

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => MasterDetailBloc(locator<MasterRepository>())
        ..add(MasterDetailRequested(idOrSlug))
        ..add(const MasterReviewsRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MasterDetailBloc, MasterDetailState>(
        builder: (context, state) {
          if (state.loading && state.master == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final err = state.error;
          if (err != null && state.master == null) {
            return AppErrorView(
              message: err,
              onRetry: () => context
                  .read<MasterDetailBloc>()
                  .add(MasterDetailRequested(idOrSlug)),
            );
          }
          final m = state.master!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 200.h,
                flexibleSpace: FlexibleSpaceBar(
                  background: _CoverAvatar(url: m.avatarUrl),
                  title: Text(m.fullName),
                  centerTitle: false,
                ),
              ),
              SliverToBoxAdapter(child: _Body(master: m)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: AppPrimaryButton(
                    label: 'Заказать услугу',
                    onPressed: () => context.router.push(
                      CreateOrderRoute(preferredMasterId: m.id),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoverAvatar extends StatelessWidget {
  const _CoverAvatar({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(color: AppColors.brandPrimary.withOpacity(0.15));
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) =>
          Container(color: AppColors.brandPrimary.withOpacity(0.15)),
      errorWidget: (_, __, ___) =>
          Container(color: AppColors.brandPrimary.withOpacity(0.15)),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.master});
  final MasterDetail master;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 20.r),
              SizedBox(width: 4.w),
              Text(
                master.ratingAvg.toStringAsFixed(1),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 4.w),
              Text(
                '(${master.ratingCount})',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const Spacer(),
              if (master.isVerified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.brandPrimary, size: 14.r),
                      SizedBox(width: 4.w),
                      Text(
                        'Проверен',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          if (master.city != null)
            Row(
              children: [
                Icon(Icons.place_outlined, size: 16.r),
                SizedBox(width: 4.w),
                Text(
                  [master.city, master.district].whereType<String>().join(', '),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          SizedBox(height: 16.h),
          if (master.categories.isNotEmpty) ...[
            Text(
              'Категории',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final c in master.categories)
                  Chip(label: Text(c.name)),
              ],
            ),
            SizedBox(height: 16.h),
          ],
          if (master.description != null && master.description!.isNotEmpty) ...[
            Text(
              'О мастере',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              master.description!,
              style: TextStyle(fontSize: 14.sp, height: 1.5),
            ),
            SizedBox(height: 16.h),
          ],
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.task_alt_rounded,
                  label: 'Заказы',
                  value: '${master.completedOrders}',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatChip(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Опыт',
                  value: '${master.experienceYears} лет',
                ),
              ),
              if (master.urgentAvailable) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: _StatChip(
                    icon: Icons.flash_on_rounded,
                    label: 'Срочно',
                    value: 'есть',
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 24.h),
          if (master.portfolio.isNotEmpty) ...[
            Text(
              'Портфолио',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 120.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: master.portfolio.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (_, i) {
                  final url = (master.portfolio[i]['image_url'] ??
                          master.portfolio[i]['url'] ??
                          '')
                      .toString();
                  if (url.isEmpty) return const SizedBox.shrink();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 120.h,
                      height: 120.h,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18.r, color: AppColors.brandPrimary),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
