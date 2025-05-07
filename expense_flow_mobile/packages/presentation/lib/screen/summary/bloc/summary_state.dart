import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';
import '../model/month_summary.dart';
import '../model/summary_display_type.dart';

part 'summary_state.freezed.dart';

@freezed
class SummaryState with _$SummaryState {
  const factory SummaryState({
    @Default([]) List<MonthSummary> months,
    @Default(false) bool isLoading,
    @Default(SummaryDisplayType.list) SummaryDisplayType displayType,
    @Default(0.0) double totalSavings,
    AppError? error,
  }) = _SummaryState;
}
