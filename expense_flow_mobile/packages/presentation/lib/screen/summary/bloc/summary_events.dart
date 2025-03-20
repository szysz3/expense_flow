import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_events.freezed.dart';

@freezed
class SummaryEvent with _$SummaryEvent {
  const factory SummaryEvent.init() = InitEvent;

  const factory SummaryEvent.toggleMonth(String monthId) = ToggleMonthEvent;

  const factory SummaryEvent.displayList() = DisplayListEvent;

  const factory SummaryEvent.displayPieChart() = DisplayPieChartEvent;

  const factory SummaryEvent.displayBarChart() = DisplayBarChartEvent;
}
