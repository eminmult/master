import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/common/widgets/hm_avatar.dart';
import 'package:itez_mobile/common/widgets/hm_notification_bell.dart';
import 'package:itez_mobile/common/widgets/hm_pill_button.dart';
import 'package:itez_mobile/features/addresses/bloc/active_address_cubit.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';
import 'package:itez_mobile/features/addresses/pages/address_picker_sheet.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/categories/bloc/categories_bloc.dart';
import 'package:itez_mobile/features/categories/models/category_model.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';
import 'package:itez_mobile/features/masters/bloc/masters_list_bloc.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';
import 'package:itez_mobile/features/masters/widgets/master_card.dart';
import 'package:itez_mobile/features/smart_search/widgets/smart_search_widget.dart';

/// Главная страница (анонимная-friendly):
///  - Header: аватар + brand + bell-notifications.
///  - Smart-search баннер (AI — пока заглушка → MastersListRoute).
///  - Pills с быстрыми фильтрами категорий.
///  - 2-col grid «Лучшие мастера» (sort=rating).
@RoutePage()
class HomePage extends StatelessWidget implements AutoRouteWrapper {
  const HomePage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CategoriesBloc(locator<CategoryRepository>())
            ..add(const CategoriesRequested()),
        ),
        BlocProvider(
          create: (_) => MastersListBloc(locator<MasterRepository>())
            ..add(MastersRequested(MasterListFilter(sort: 'rating'))),
        ),
      ],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          context.read<CategoriesBloc>().add(const CategoriesRefreshed());
          context.read<MastersListBloc>().add(const MastersRefreshed());
        },
        child: CustomScrollView(
          slivers: [
            const _Header(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: const SmartSearchWidget(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const _Recommended(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ),
    );
  }
}

/// Точный порт из старого master-mobile:
///   слева — аватар 40×40 (ring=true когда auth, outline у гостя),
///   центр — Wolt-style address bar (3 состояния),
///   справа — HmNotificationBell 44×44 с unread-badge.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, auth) {
              final isGuest = auth is! AuthAuthenticated;
              final user = auth.user;
              final avatarUrl = user?.avatarUrl;
              return Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () => isGuest
                        ? ctx.router.push(const LoginRoute())
                        : ctx.router.push(const ProfileRoute()),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? HmAvatar(url: avatarUrl, size: 40, ring: true)
                        : Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(
                                color: AppColors.border2,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isGuest
                                  ? Icons.person_outline_rounded
                                  : Icons.person_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _AddressBar(isGuest: isGuest)),
                  const SizedBox(width: 8),
                  HmNotificationBell(
                    onTap: () =>
                        ctx.router.push(const NotificationsRoute()),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Wolt-style address bar — 3 состояния:
//   1. Гость               → "Добро пожаловать" / "Войти / Регистрация"
//   2. Auth, нет адресов   → "АДРЕС" / "+ Добавить адрес" (accent)
//   3. Auth, есть адреса   → "АДРЕС" / "label · полный адрес" + chevron
// ─────────────────────────────────────────────────────────────────────────
class _AddressBar extends StatelessWidget {
  const _AddressBar({required this.isGuest});
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (isGuest) {
      return _BarShell(
        onTap: () => context.router.push(const LoginRoute()),
        smallLabel: l.home_welcome,
        title: l.home_sign_in_register,
        leading: Icons.login_rounded,
      );
    }
    return BlocBuilder<AddressesBloc, AddressesState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return _BarShell(
            onTap: null,
            smallLabel: l.address_label_caps,
            title: l.home_loading,
            leading: Icons.location_on_outlined,
            muted: true,
          );
        }
        if (state.error != null && state.items.isEmpty) {
          return _BarShell(
            onTap: () => context
                .read<AddressesBloc>()
                .add(const AddressesRequested()),
            smallLabel: l.address_label_caps,
            title: l.home_load_error,
            leading: Icons.location_off_outlined,
            muted: true,
          );
        }
        if (state.items.isEmpty) {
          return _BarShell(
            onTap: () => context.router.push(AddressFormRoute()),
            smallLabel: l.address_label_caps,
            title: l.address_add_new,
            leading: Icons.add_location_alt_rounded,
            accentTitle: true,
          );
        }
        return BlocBuilder<ActiveAddressCubit, int?>(
          builder: (context, activeId) {
            final active = _resolveActive(state.items, activeId);
            return _BarShell(
              onTap: () => showAddressPickerSheet(context),
              smallLabel: l.address_label_caps,
              title: _formatAddress(active),
              leading: Icons.location_on_rounded,
              showChevron: true,
            );
          },
        );
      },
    );
  }

  static AddressModel? _resolveActive(
    List<AddressModel> items,
    int? activeId,
  ) {
    if (items.isEmpty) return null;
    if (activeId != null) {
      for (final a in items) {
        if (a.id == activeId) return a;
      }
    }
    return items.firstWhere(
      (a) => a.isDefault,
      orElse: () => items.first,
    );
  }

  static String _formatAddress(AddressModel? a) {
    if (a == null) return '—';
    final label = a.label?.trim();
    if (label != null && label.isNotEmpty) return '$label · ${a.fullAddress}';
    return a.fullAddress;
  }
}

class _BarShell extends StatelessWidget {
  const _BarShell({
    required this.onTap,
    required this.smallLabel,
    required this.title,
    required this.leading,
    this.showChevron = false,
    this.accentTitle = false,
    this.muted = false,
  });

  final VoidCallback? onTap;
  final String smallLabel;
  final String title;
  final IconData leading;
  final bool showChevron;
  final bool accentTitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              smallLabel,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.text5,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  leading,
                  size: 16,
                  color: muted ? AppColors.text5 : AppColors.accent,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: muted
                          ? AppColors.text4
                          : (accentTitle
                              ? AppColors.accent
                              : AppColors.text),
                    ),
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.text4,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (ctx, state) {
          final items = switch (state) {
            CategoriesLoaded(:final items) =>
              items.where((c) => c.hasMasters).toList(),
            _ => const <CategoryModel>[],
          };
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl.w, 0, AppSpacing.xl.w, AppSpacing.sm.h),
                child: Text(
                  ctx.l10n.home_recommended,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                child: Row(
                  children: [
                    for (final c in items.take(12))
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: HmPillButton(
                          label: c.name,
                          selected: false,
                          onTap: () => ctx.router.push(MastersListRoute(
                            categoryId: c.id,
                            categoryName: c.name,
                          )),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
            ],
          );
        },
      ),
    );
  }
}

class _Recommended extends StatelessWidget {
  const _Recommended();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
      sliver: SliverToBoxAdapter(
        child: BlocBuilder<MastersListBloc, MastersListState>(
          builder: (ctx, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ctx.l10n.home_recommended,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ctx.router.push(MastersListRoute()),
                      child: Text(ctx.l10n.common_see_all),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm.h),
                _RecommendedBody(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecommendedBody extends StatelessWidget {
  const _RecommendedBody({required this.state});
  final MastersListState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      MastersListInitial() ||
      MastersListLoading() =>
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      MastersListFailed(:final message) => AppErrorView(
          message: message,
          onRetry: () =>
              context.read<MastersListBloc>().add(const MastersRefreshed()),
        ),
      MastersListLoaded(:final items) when items.isEmpty => Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Text(
            'Пока нет рекомендаций. Загляните позже.',
            style: TextStyle(color: AppColors.text4, fontSize: 13.sp),
          ),
        ),
      MastersListLoaded(:final items) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.685,
          ),
          itemCount: items.length.clamp(0, 8),
          itemBuilder: (_, i) {
            final m = items[i];
            return MasterCard(
              master: m,
              onTap: () => context.router.push(MasterDetailRoute(
                idOrSlug: m.slug.isNotEmpty ? m.slug : '${m.id}',
              )),
            );
          },
        ),
    };
  }
}
