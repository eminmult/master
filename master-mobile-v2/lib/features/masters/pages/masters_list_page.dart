import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/features/masters/bloc/masters_list_bloc.dart';
import 'package:itez_mobile/features/masters/models/master_list_item.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';
import 'package:itez_mobile/features/masters/widgets/master_card.dart';

@RoutePage()
class MastersListPage extends StatefulWidget implements AutoRouteWrapper {
  const MastersListPage({
    super.key,
    this.categoryId,
    this.categoryName,
    this.initialSearch,
  });

  final int? categoryId;
  final String? categoryName;
  final String? initialSearch;

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => MastersListBloc(locator<MasterRepository>())
        ..add(MastersRequested(MasterListFilter(
          categoryId: categoryId,
          search: initialSearch,
        ))),
      child: this,
    );
  }

  @override
  State<MastersListPage> createState() => _MastersListPageState();
}

class _MastersListPageState extends State<MastersListPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = widget.initialSearch ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final bloc = context.read<MastersListBloc>();
      final current = _currentFilter(bloc.state);
      bloc.add(MastersFilterChanged(current.copyWith(search: v.trim())));
    });
  }

  MasterListFilter _currentFilter(MastersListState s) => switch (s) {
        MastersListLoading() => s.filter,
        MastersListLoaded() => s.filter,
        MastersListFailed() => s.filter,
        _ => MasterListFilter(categoryId: widget.categoryId),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Мастера'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Поиск по имени...',
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MastersListBloc, MastersListState>(
              builder: (context, state) => switch (state) {
                MastersListInitial() ||
                MastersListLoading() =>
                  const Center(child: CircularProgressIndicator()),
                MastersListFailed(:final message) => AppErrorView(
                    message: message,
                    onRetry: () => context
                        .read<MastersListBloc>()
                        .add(const MastersRefreshed()),
                  ),
                MastersListLoaded(:final items) => _List(items: items),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});
  final List<MasterListItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppErrorView(message: 'Никого не нашли. Попробуйте изменить фильтры.');
    }
    return RefreshIndicator(
      onRefresh: () async => context
          .read<MastersListBloc>()
          .add(const MastersRefreshed()),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (_, i) {
          final m = items[i];
          return MasterCard(
            master: m,
            onTap: () => context.router.push(
              MasterDetailRoute(idOrSlug: m.slug.isNotEmpty ? m.slug : '${m.id}'),
            ),
          );
        },
      ),
    );
  }
}
