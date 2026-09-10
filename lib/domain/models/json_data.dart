typedef Json = Map<String, Object?>;

Json jsonObject(Object? value) => Map<String, Object?>.from(value as Map);

List<Object?> jsonList(Object? value) => List<Object?>.from(value as List);

Json immutableJson(Json value) => Map.unmodifiable({
  for (final entry in value.entries) entry.key: _freeze(entry.value),
});

Object? _freeze(Object? value) => switch (value) {
  Map() => immutableJson(jsonObject(value)),
  List() => List<Object?>.unmodifiable(value.map(_freeze)),
  null || String() || bool() || num() => value,
  _ => throw ArgumentError('Expected JSON data'),
};

int nonNegative(Object? value, [int fallback = 0]) {
  final result = value == null ? fallback : value as int;
  if (result < 0) throw const FormatException('Negative counter');
  return result;
}

DateTime? dateFromJson(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

String? dateToJson(DateTime? value) => value?.toUtc().toIso8601String();
