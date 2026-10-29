/// Small helpers for turning PostgREST JSON into Dart values.
///
/// Supabase returns JSON, so numerics arrive as `num` or as `String` for
/// `numeric` columns, and timestamps arrive as ISO-8601 strings.
library;

typedef Json = Map<String, dynamic>;

String asString(Object? value, [String fallback = '']) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

String? asStringOrNull(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

double? asDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double asDouble(Object? value, [double fallback = 0]) =>
    asDoubleOrNull(value) ?? fallback;

int? asIntOrNull(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}

int asInt(Object? value, [int fallback = 0]) => asIntOrNull(value) ?? fallback;

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

DateTime? asDateOrNull(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value)?.toLocal();
  return null;
}

DateTime asDate(Object? value) =>
    asDateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
