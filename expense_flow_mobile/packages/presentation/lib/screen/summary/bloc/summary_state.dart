import 'package:freezed_annotation/freezed_annotation.dart';

import '../model/month_summary.dart';

part 'summary_state.freezed.dart';

@freezed
class SummaryState with _$SummaryState {
  const factory SummaryState({
    @Default([]) List<MonthSummary> months,
    @Default(false) bool isLoading,
  }) = _SummaryState;
}
