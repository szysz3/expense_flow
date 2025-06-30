import 'package:domain/model/receipt_filter_params.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';
import 'receipt_filtering_event.dart';

part 'receipt_filtering_state.freezed.dart';

@freezed
class ReceiptFilteringState with _$ReceiptFilteringState {
  const factory ReceiptFilteringState({
    @Default(ReceiptFilterParams()) ReceiptFilterParams filterParams,
    QuickDateRangeType? selectedQuickRange,
    AppError? error,
  }) = _ReceiptFilteringState;
}
