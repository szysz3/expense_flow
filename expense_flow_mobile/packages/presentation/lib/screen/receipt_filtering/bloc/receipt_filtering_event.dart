import 'package:domain/model/receipt_filter_params.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_filtering_event.freezed.dart';

enum QuickDateRangeType {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
}

@freezed
class ReceiptFilteringEvent with _$ReceiptFilteringEvent {
  const factory ReceiptFilteringEvent.init({
    ReceiptFilterParams? initialParams,
  }) = InitEvent;

  const factory ReceiptFilteringEvent.refresh() = RefreshEvent;

  const factory ReceiptFilteringEvent.toggleCategory(String category) =
      ToggleCategoryEvent;

  const factory ReceiptFilteringEvent.setStartDate(DateTime? date) =
      SetStartDateEvent;

  const factory ReceiptFilteringEvent.setEndDate(DateTime? date) =
      SetEndDateEvent;

  const factory ReceiptFilteringEvent.setQuickDateRange(
    QuickDateRangeType rangeType,
  ) = SetQuickDateRangeEvent;

  const factory ReceiptFilteringEvent.setSearchQuery(String query) =
      SetSearchQueryEvent;

  const factory ReceiptFilteringEvent.clearFilters() = ClearFiltersEvent;

  const factory ReceiptFilteringEvent.applyFilters() = ApplyFiltersEvent;
}
