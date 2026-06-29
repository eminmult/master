import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_primary_button.dart';
import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';
import 'package:itez_mobile/features/masters/widgets/master_card.dart';
import 'package:itez_mobile/features/smart_search/bloc/smart_search_bloc.dart';

/// Free-form "опиши задачу" — heuristic-fallback пока нет AI-эндпоинта.
@RoutePage()
class SmartSearchPage extends StatelessWidget implements AutoRouteWrapper {
  const SmartSearchPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => SmartSearchBloc(
        client: locator<ApiClient>(),
        categories: locator<CategoryRepository>(),
        masters: locator<MasterRepository>(),
      ),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Опиши задачу')),
      body: const SafeArea(child: _Body()),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmartSearchBloc, SmartSearchState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl.w, AppSpacing.lg.h,
              AppSpacing.xl.w, AppSpacing.xl.h),
          children: [
            Text(
              'Что у тебя сломалось?',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Напиши обычным языком — мы подберём подходящих мастеров.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.text4,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            TextField(
              controller: _input,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText:
                    'Например: течёт смеситель на кухне, нужен сантехник '
                    'сегодня вечером',
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            AppPrimaryButton(
              label: 'Подобрать мастеров',
              loading: state is SmartSearchAnalyzing,
              onPressed: () => context
                  .read<SmartSearchBloc>()
                  .add(SmartSearchSubmitted(description: _input.text)),
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Result(state: state),
          ],
        );
      },
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.state});
  final SmartSearchState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      SmartSearchIdle() => const SizedBox.shrink(),
      SmartSearchAnalyzing() => Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      SmartSearchFailed(:final message) => Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Text(
            message,
            style: TextStyle(color: AppColors.danger, fontSize: 13.sp),
          ),
        ),
      SmartSearchSuggested(
        :final suggestedCategory,
        :final confidence,
        :final masters,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestedCategory != null)
              Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(AppSpacing.md.w),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.accent, size: 18.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Подходит: ${suggestedCategory.name}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'уверенность ${(confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (masters.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'По вашему описанию мастеров не нашли. '
                  'Попробуйте описать иначе.',
                  style: TextStyle(color: AppColors.text4, fontSize: 13.sp),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.685,
                ),
                itemCount: masters.length.clamp(0, 8),
                itemBuilder: (_, i) {
                  final m = masters[i];
                  return MasterCard(
                    master: m,
                    onTap: () => context.router.push(MasterDetailRoute(
                      idOrSlug: m.slug.isNotEmpty ? m.slug : '${m.id}',
                    )),
                  );
                },
              ),
          ],
        ),
    };
  }
}
