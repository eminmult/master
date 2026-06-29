/// Толерантные парсеры для JSON-ответов backend'а.
///
/// Laravel decimal-cast возвращает числа как строки (`"4.64"`, `"40.379"`),
/// `as num` падает на cast → весь fromJson выбрасывает TypeError, BLoC
/// зависает в loading. Эти функции принимают `num | String | bool | null`
/// и нормализуют в нужный тип; для не-парсящегося значения — fallback.
int parseInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is bool) return v ? 1 : 0;
  if (v is String) {
    return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? fallback;
  }
  return fallback;
}

int? parseIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

double parseDouble(Object? v, [double fallback = 0]) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? parseDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool parseBool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

DateTime? parseDate(Object? v) {
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
