part of 'addresses_bloc.dart';

class AddressesState {
  const AddressesState({
    this.loading = false,
    this.items = const [],
    this.error,
    this.mutating = false,
    this.mutationError,
    this.justSavedId,
  });

  final bool loading;
  final List<AddressModel> items;
  final String? error;
  final bool mutating;
  final String? mutationError;
  final int? justSavedId;

  AddressesState copyWith({
    bool? loading,
    List<AddressModel>? items,
    String? error,
    bool? mutating,
    String? mutationError,
    int? justSavedId,
    bool clearError = false,
    bool clearMutationError = false,
    bool clearJustSaved = false,
  }) =>
      AddressesState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        error: clearError ? null : (error ?? this.error),
        mutating: mutating ?? this.mutating,
        mutationError:
            clearMutationError ? null : (mutationError ?? this.mutationError),
        justSavedId: clearJustSaved ? null : (justSavedId ?? this.justSavedId),
      );
}
