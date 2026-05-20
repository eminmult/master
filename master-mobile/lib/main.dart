import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/app.dart';
import 'package:master_mobile/features/addresses/data/active_address_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
    child: const MasterApp(),
  ));
}
