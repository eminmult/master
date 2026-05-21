import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// Centralised snackbar / toast service. Pages call `ref.read(snackbarServiceProvider).show*(…)`
/// instead of grabbing `ScaffoldMessenger.of(context)` and hand-building a
/// SnackBar each time. That gives us:
///
///   * one consistent style (colours, duration, swipe-to-dismiss),
///   * a single place to map `ApiException` subtypes to user-friendly copy,
///   * the ability to swap rendering (e.g., Material 3 BannerService, custom
///     overlay) without a sweep through every feature.
///
/// Setup: in MasterApp pass the navigator key onto MaterialApp.router via
/// `scaffoldMessengerKey: ref.read(scaffoldMessengerKeyProvider)`.
class SnackbarService {
  SnackbarService(this._key);
  final GlobalKey<ScaffoldMessengerState> _key;

  /// Generic info — neutral surface tone, ~3 sec.
  void showInfo(String message) => _show(message, _SnackKind.info);

  /// Affirmative action — green tick, ~3 sec.
  void showSuccess(String message) => _show(message, _SnackKind.success);

  /// Error / warning — red surface, ~5 sec.
  void showError(String message) => _show(message, _SnackKind.error);

  /// Convenience: project an ApiException to user-readable text using the
  /// translation hook provided by the caller. Each ApiException subtype has
  /// a sensible default that callers can override.
  void showApiException(
    ApiException e, {
    String Function(ApiException)? translate,
  }) {
    final text = translate?.call(e) ?? e.message;
    showError(text);
  }

  void _show(String message, _SnackKind kind) {
    final messenger = _key.currentState;
    if (messenger == null) return; // app not mounted yet (e.g., during boot)
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: switch (kind) {
            _SnackKind.info => HmColors.surface,
            _SnackKind.success => HmColors.success,
            _SnackKind.error => HmColors.danger,
          },
          duration: kind == _SnackKind.error
              ? const Duration(seconds: 5)
              : const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HmRadius.card),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: kind == _SnackKind.info ? HmColors.text : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }
}

enum _SnackKind { info, success, error }

/// Shared messenger key — install on MaterialApp via `scaffoldMessengerKey`.
final scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>((_) => GlobalKey<ScaffoldMessengerState>());

final snackbarServiceProvider = Provider<SnackbarService>((ref) {
  return SnackbarService(ref.watch(scaffoldMessengerKeyProvider));
});
