part of 'wallet_bloc.dart';

class WalletState {
  const WalletState({
    this.loading = false,
    this.balance,
    this.transactions = const [],
    this.error,
  });

  final bool loading;
  final WalletBalance? balance;
  final List<WalletTransaction> transactions;
  final String? error;

  WalletState copyWith({
    bool? loading,
    WalletBalance? balance,
    List<WalletTransaction>? transactions,
    String? error,
    bool clearError = false,
  }) =>
      WalletState(
        loading: loading ?? this.loading,
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
        error: clearError ? null : (error ?? this.error),
      );
}
