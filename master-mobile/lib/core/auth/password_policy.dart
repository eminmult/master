import 'package:master_mobile/l10n/generated/app_localizations.dart';

/// Registration / reset / change-password policy.
/// Login keeps a looser check so existing users with pre-policy passwords
/// can still sign in.
String? validateStrongPassword(String? v, AppLocalizations loc) {
  if (v == null || v.length < 8) return loc.auth_password_min;
  if (!RegExp(r'[A-Za-zÀ-ɏЀ-ӿ]').hasMatch(v)) return loc.auth_password_min;
  if (!RegExp(r'\d').hasMatch(v)) return loc.auth_password_min;
  return null;
}
