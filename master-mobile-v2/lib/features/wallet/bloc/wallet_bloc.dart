import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/wallet/models/wallet_balance.dart';
import 'package:itez_mobile/features/wallet/repositories/wallet_repository.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc(this._repo) : super(const WalletState()) {
    on<WalletRequested>(_onRequested);
    on<WalletRefreshed>(_onRequested);
  }

  final WalletRepository _repo;

  Future<void> _onRequested(
    WalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      // Параллельно: баланс + последние транзакции.
      final results = await Future.wait([
        _repo.balance(),
        _repo.transactions(),
      ]);
      emit(state.copyWith(
        loading: false,
        balance: results[0] as WalletBalance,
        transactions: results[1] as List<WalletTransaction>,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Не удалось загрузить кошелёк',
      ));
    }
  }
}
