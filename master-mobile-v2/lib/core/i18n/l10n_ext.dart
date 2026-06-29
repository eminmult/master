import 'package:flutter/widgets.dart';
import 'package:itez_mobile/l10n/generated/app_localizations.dart';

/// `context.l10n.smart_find` — точно как в оригинале master-mobile.
extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
