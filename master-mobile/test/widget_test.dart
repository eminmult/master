// Sanity check that the shared test scaffolding boots a MaterialApp +
// ProviderScope without crashing. New widget tests should follow the same
// shape via `test/helpers/pump_app.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('pumpApp wraps a child without exceptions', (tester) async {
    await pumpApp(tester, child: const Text('hello'));
    expect(find.text('hello'), findsOneWidget);
  });
}
