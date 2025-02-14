import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_events.freezed.dart';

@freezed
class SummaryEvent with _$SummaryEvent {
  const factory SummaryEvent.init() = InitEvent;

  const factory SummaryEvent.toggleMonth(String monthId) = ToggleMonthEvent;
}
