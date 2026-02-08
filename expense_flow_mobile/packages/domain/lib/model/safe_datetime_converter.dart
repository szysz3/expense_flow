import 'package:json_annotation/json_annotation.dart';

/// A JSON converter that safely parses DateTime values.
/// Returns null for invalid or unparseable date strings instead of throwing.
class SafeDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const SafeDateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is! String) return null;
    if (json.isEmpty) return null;

    try {
      return DateTime.parse(json);
    } catch (_) {
      return null;
    }
  }

  @override
  dynamic toJson(DateTime? object) {
    return object?.toIso8601String();
  }
}
