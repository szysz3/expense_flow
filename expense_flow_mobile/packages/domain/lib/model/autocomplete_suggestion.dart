import 'package:freezed_annotation/freezed_annotation.dart';

part 'autocomplete_suggestion.freezed.dart';
part 'autocomplete_suggestion.g.dart';

@freezed
class AutocompleteSuggestion with _$AutocompleteSuggestion {
  const factory AutocompleteSuggestion({
    required String description,
    required String category,
    required double score,
  }) = _AutocompleteSuggestion;

  factory AutocompleteSuggestion.fromJson(Map<String, dynamic> json) =>
      _$AutocompleteSuggestionFromJson(json);
}
