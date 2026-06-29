import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/wallet/bloc/wallet_bloc.dart';
import 'package:itez_mobile/features/wallet/models/wallet_balance.dart';
import 'package:itez_mobile/features/wallet/repositories/wallet_repository.dart';

@RoutePage()
class WalletPage extends StatelessWidget implements AutoRouteWrapper {
  const WalletPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletBloc(locator<WalletRepository>())
        ..add(const WalletRequested()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кошелёк')),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state.loading && state.balance == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.balance == null) {
            return AppErrorView(
              message: state.error!,
              onRetry: () => context.read<WalletBloc>().add(const WalletRefreshed()),
            );
          }
          final balance = state.balance;
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<WalletBloc>().add(const WalletRefreshed()),
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                if (balance != null) _BalanceCard(balance: balance),
                SizedBox(height: 16.h),
                Text(
                  'Операции',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                if (state.transactions.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Text(
                        'Операций пока нет',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  )
                else
                  for (final tx in state.transactions) _TxTile(tx: tx),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final WalletBalance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Доступно',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.white.withOpacity(0.85),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${balance.available.toStringAsFixed(2)} ${balance.currency}',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          if (balance.pending > 0) ...[
            SizedBox(height: 6.h),
            Text(
              'В обработке: ${balance.pending.toStringAsFixed(2)} ${balance.currency}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.white.withOpacity(0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncome ? AppColors.success : AppColors.danger;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18.r,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isEmpty ? tx.type : tx.description,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                if (tx.createdAt != null)
                  Text(
                    tx.createdAt!.toLocal().toString().substring(0, 16),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : ''}${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
