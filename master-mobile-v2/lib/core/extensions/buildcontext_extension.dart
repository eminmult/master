import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  bool get isLightTheme => Theme.of(this).brightness == Brightness.light;
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;

  Size get screen => MediaQuery.sizeOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
