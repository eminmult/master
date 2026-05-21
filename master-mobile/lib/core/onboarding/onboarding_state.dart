import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/features/addresses/data/active_address_controller.dart';

/// Tracks which one-time onboarding steps the user has completed.
///
/// Today we only have "picked a language". Tomorrow we'll add things like
/// "saw the brief feature tour", "granted location permission", "verified
/// phone for the first time" — and they all need to be persisted across
/// app restarts independently of each other.
///
/// Each flag is backed by a SharedPreferences key, with the controller
/// exposing typed getters/setters. The router's `OnboardingGuard` reads
/// these instead of poking at raw SharedPreferences keys.
class OnboardingFlags {
  const OnboardingFlags({
    required this.localePicked,
    required this.tourSeen,
    required this.permissionsGranted,
  });

  /// True once the user has explicitly selected a language at least once.
  /// Also implies LocaleController has a saved `i18n_lang` value.
  final bool localePicked;

  /// True once the user has tapped through the post-language feature tour
  /// (not implemented yet — placeholder for the next milestone).
  final bool tourSeen;

  /// True once we've at least ASKED for runtime permissions (location,
  /// notifications). The user may have denied — we still mark this as seen
  /// so we don't re-prompt on every launch.
  final bool permissionsGranted;

  static const initial = OnboardingFlags(
    localePicked: false,
    tourSeen: false,
    permissionsGranted: false,
  );

  OnboardingFlags copyWith({
    bool? localePicked,
    bool? tourSeen,
    bool? permissionsGranted,
  }) => OnboardingFlags(
        localePicked: localePicked ?? this.localePicked,
        tourSeen: tourSeen ?? this.tourSeen,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      );
}

/// Read-only synchronous view derived from SharedPreferences. Cheap to
/// recompute, so we expose it as a Provider rather than a Notifier — the
/// flags change rarely and each setter just writes a single boolean.
final onboardingFlagsProvider = Provider<OnboardingFlags>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return OnboardingFlags(
    localePicked: (prefs.getString('i18n_lang') ?? '').isNotEmpty,
    tourSeen: prefs.getBool('onboarding_tour_seen') ?? false,
    permissionsGranted: prefs.getBool('onboarding_perms_asked') ?? false,
  );
});

/// Mutators — call from page widgets after the user completes a step.
extension OnboardingMutations on Ref {
  Future<void> markTourSeen() async {
    final prefs = read(sharedPrefsProvider);
    await prefs.setBool('onboarding_tour_seen', true);
  }

  Future<void> markPermissionsAsked() async {
    final prefs = read(sharedPrefsProvider);
    await prefs.setBool('onboarding_perms_asked', true);
  }
}
