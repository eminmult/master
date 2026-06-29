import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';

@RoutePage()
class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AddressesBloc>().add(const AddressesRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои адреса'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.router.push(AddressFormRoute()),
          ),
        ],
      ),
      body: BlocConsumer<AddressesBloc, AddressesState>(
        listenWhen: (p, c) =>
            p.mutationError != c.mutationError && c.mutationError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.mutationError!)),
          );
        },
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.items.isEmpty) {
            return AppErrorView(
              message: state.error!,
              onRetry: () => context
                  .read<AddressesBloc>()
                  .add(const AddressesRequested()),
            );
          }
          if (state.items.isEmpty) {
            return _EmptyState(
              onAdd: () => context.router.push(AddressFormRoute()),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context
                .read<AddressesBloc>()
                .add(const AddressesRequested()),
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, i) => _Tile(address: state.items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.address});
  final AddressModel address;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () =>
            context.router.push(AddressFormRoute(initial: address)),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Icon(
                Icons.place_rounded,
                color: AppColors.brandPrimary,
                size: 22.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (address.isDefault) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'по умолч.',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (address.label != null && address.label!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        address.fullAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20.r),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Удалить адрес?'),
        content: Text(address.displayTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<AddressesBloc>().add(AddressDeleted(address.id));
              Navigator.pop(dialogCtx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_location_alt_outlined,
                size: 56.r, color: AppColors.brandPrimary),
            SizedBox(height: 12.h),
            Text(
              'Добавьте первый адрес',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text(
              'Он понадобится для создания заказа.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).hintColor,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
