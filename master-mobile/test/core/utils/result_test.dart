import 'package:flutter_test/flutter_test.dart';
import 'package:master_mobile/core/utils/result.dart';

void main() {
  group('Result<T, E>', () {
    test('Ok carries value, no error', () {
      const r = Ok<int, String>(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.errorOrNull, isNull);
    });

    test('Err carries error, no value', () {
      const r = Err<int, String>('boom');
      expect(r.isOk, isFalse);
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.errorOrNull, 'boom');
    });

    test('map transforms Ok, leaves Err untouched', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('x');
      expect(ok.map((v) => v * 10).valueOrNull, 20);
      expect(err.map((v) => v * 10).errorOrNull, 'x');
    });

    test('mapError transforms Err, leaves Ok untouched', () {
      const Result<int, String> ok = Ok(2);
      const Result<int, String> err = Err('boom');
      expect(ok.mapError((e) => e.length).valueOrNull, 2);
      expect(err.mapError((e) => e.length).errorOrNull, 4);
    });

    test('fold dispatches to ok/err callbacks', () {
      const Result<int, String> ok = Ok(7);
      const Result<int, String> err = Err('nope');
      expect(ok.fold(ok: (v) => 'v=$v', err: (e) => 'e=$e'), 'v=7');
      expect(err.fold(ok: (v) => 'v=$v', err: (e) => 'e=$e'), 'e=nope');
    });

    test('runCatching wraps a throwing async block', () async {
      final ok = await runCatching<int, String>(() async => 10, onError: (e, _) => e.toString());
      expect(ok.valueOrNull, 10);

      final err = await runCatching<int, String>(
        () async => throw Exception('boom'),
        onError: (e, _) => e.toString(),
      );
      expect(err.errorOrNull, contains('boom'));
    });

    test('Ok/Err equality + hashCode', () {
      expect(const Ok<int, String>(1), const Ok<int, String>(1));
      expect(const Err<int, String>('a'), const Err<int, String>('a'));
      expect(const Ok<int, String>(1).hashCode, const Ok<int, String>(1).hashCode);
    });
  });
}
