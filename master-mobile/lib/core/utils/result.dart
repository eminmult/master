/// Result<T, E> — sum type for "computation that may fail" without
/// throwing. Lets controllers and repositories communicate failure with
/// the same expressiveness as success, and removes the need for try/catch
/// in the presentation layer.
///
/// Why this exists:
///
///   Repositories today throw `ApiException`. UI does:
///     try { final r = await repo.x(); … } on ApiException catch (e) { … }
///   That's noisy AND it bleeds throw-semantics into the widget tree
///   (forgetting a catch silently propagates to the framework, the user
///   sees a red error screen). Result moves both cases into the type:
///     final r = await repo.x();
///     return switch (r) {
///       Ok(:final value) => _renderData(value),
///       Err(:final error) => _renderError(error),
///     };
///
/// Adoption: new repositories should return `Future<Result<T, ApiException>>`.
/// Existing throw-based repos stay as-is until incrementally migrated —
/// no big-bang refactor required.
sealed class Result<T, E> {
  const Result();

  /// Convenience — true iff this is Ok.
  bool get isOk => this is Ok<T, E>;

  /// Convenience — true iff this is Err.
  bool get isErr => this is Err<T, E>;

  /// The success value if Ok, otherwise null.
  T? get valueOrNull => switch (this) {
        Ok<T, E>(:final value) => value,
        Err<T, E>() => null,
      };

  /// The error value if Err, otherwise null.
  E? get errorOrNull => switch (this) {
        Ok<T, E>() => null,
        Err<T, E>(:final error) => error,
      };

  /// Map over the success value.
  Result<U, E> map<U>(U Function(T) f) => switch (this) {
        Ok<T, E>(:final value) => Ok<U, E>(f(value)),
        Err<T, E>(:final error) => Err<U, E>(error),
      };

  /// Map over the error value.
  Result<T, F> mapError<F>(F Function(E) f) => switch (this) {
        Ok<T, E>(:final value) => Ok<T, F>(value),
        Err<T, E>(:final error) => Err<T, F>(f(error)),
      };

  /// Pattern-style accessor — call one of two callbacks. Useful in build()
  /// where switch expressions get awkward.
  R fold<R>({required R Function(T) ok, required R Function(E) err}) =>
      switch (this) {
        Ok<T, E>(:final value) => ok(value),
        Err<T, E>(:final error) => err(error),
      };
}

class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;

  @override
  bool operator ==(Object other) => other is Err<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Err($error)';
}

/// Run a throwing async function and capture the outcome as a Result.
///
/// Use sparingly — repositories should be migrated to return Result
/// natively, not wrap each call here. This is for one-off adapter use.
Future<Result<T, E>> runCatching<T, E>(
  Future<T> Function() body, {
  required E Function(Object error, StackTrace stackTrace) onError,
}) async {
  try {
    return Ok<T, E>(await body());
  } catch (e, st) {
    return Err<T, E>(onError(e, st));
  }
}
