import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/features/addresses/bloc/active_address_cubit.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';

/// Wolt-style bottom sheet с выбором сохранённого адреса + CTA "Добавить".
/// На активном адресе — galка (radio) + accent-soft фон, выбор сразу
/// закрывает sheet и обновляет `ActiveAddressCubit`.
Future<void> showAddressPickerSheet(BuildContext context) {
  // Все BLoC'и (AddressesBloc, ActiveAddressCubit) — глобальные в App
  // MultiBlocProvider, поэтому sheet просто пробрасывает их вниз.
  final addresses = context.read<AddressesBloc>();
  final active = context.read<ActiveAddressCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // useRootNavigator: иначе sheet анимируется внутри shell-body и
    // остаётся ПОД floating bottom-nav в Z-order (nav рисуется в Stack
    // того же body). Через root-navigator оверлей перекрывает весь shell.
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: addresses),
        BlocProvider.value(value: active),
      ],
      child: const _AddressPickerSheet(),
    ),
  );
}

class _AddressPickerSheet extends StatelessWidget {
  const _AddressPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 12.h, 0, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 18.r, color: AppColors.accent),
                  SizedBox(width: 8.w),
                  Text(
                    context.l10n.address_pick_title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.text4),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            const Flexible(child: _List()),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.router.push(AddressFormRoute());
                  },
                  icon: Icon(Icons.add_location_alt_rounded, size: 18.r),
                  label: Text(context.l10n.address_add_new),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                    shape: const StadiumBorder(),
                    textStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressesBloc, AddressesState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(40.w),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }
        if (state.error != null && state.items.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(40.w),
            child: Center(
              child: Text(
                state.error!,
                style: const TextStyle(color: AppColors.text4),
              ),
            ),
          );
        }
        if (state.items.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 20.h),
            child: Column(
              children: [
                Icon(Icons.location_off_outlined,
                    size: 36.r, color: AppColors.text5),
                SizedBox(height: 10.h),
                Text(
                  context.l10n.address_no_addresses,
                  style: TextStyle(
                    color: AppColors.text4,
                    fontSize: 13.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return BlocBuilder<ActiveAddressCubit, int?>(
          builder: (context, activeId) {
            return ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => SizedBox(height: 6.h),
              itemBuilder: (_, i) {
                final a = state.items[i];
                final selected = activeId == a.id ||
                    (activeId == null && a.isDefault);
                return _AddressTile(
                  address: a,
                  selected: selected,
                  onTap: () async {
                    await context.read<ActiveAddressCubit>().select(a.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18.r,
              color: selected ? AppColors.accent : AppColors.text5,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (address.label != null &&
                        address.label!.isNotEmpty) ...[
                      Text(
                        address.label!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(width: 6.w),
                    ],
                    if (address.isDefault)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Text(
                          context.l10n.address_default_badge,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ]),
                  SizedBox(height: 2.h),
                  Text(
                    address.fullAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: AppColors.text3,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
