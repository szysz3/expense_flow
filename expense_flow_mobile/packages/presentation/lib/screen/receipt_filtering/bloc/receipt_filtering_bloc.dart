import 'dart:async';

import 'package:domain/model/receipt_filter_params.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'receipt_filtering_event.dart';
import 'receipt_filtering_state.dart';

class ReceiptFilteringBloc
    extends Bloc<ReceiptFilteringEvent, ReceiptFilteringState> {
  ReceiptFilteringBloc() : super(const ReceiptFilteringState()) {
    on<InitEvent>(_onInit);
    on<RefreshEvent>(_onRefresh);
    on<ToggleCategoryEvent>(_onToggleCategory);
    on<SetStartDateEvent>(_onSetStartDate);
    on<SetEndDateEvent>(_onSetEndDate);
    on<SetQuickDateRangeEvent>(_onSetQuickDateRange);
    on<SetSearchQueryEvent>(_onSetSearchQuery);
    on<ClearFiltersEvent>(_onClearFilters);
    on<ApplyFiltersEvent>(_onApplyFilters);
  }

  Future<void> _onInit(
    InitEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) async {
    emit(state.copyWith(
      filterParams: event.initialParams ?? const ReceiptFilterParams(),
      selectedQuickRange: _getQuickRangeFromDates(
        event.initialParams?.startDate,
        event.initialParams?.endDate,
      ),
    ));
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) async {
    // Implement if needed
  }

  void _onToggleCategory(
    ToggleCategoryEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) {
    final categories = List<String>.from(state.filterParams.categories);
    if (categories.contains(event.category)) {
      categories.remove(event.category);
    } else {
      categories.add(event.category);
    }

    emit(state.copyWith(
      filterParams: state.filterParams.copyWith(categories: categories),
    ));
  }

  void _onSetStartDate(
    SetStartDateEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) {
    emit(state.copyWith(
      filterParams: state.filterParams.copyWith(startDate: event.date),
      selectedQuickRange: null,
    ));
  }

  void _onSetEndDate(
    SetEndDateEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) {
    emit(state.copyWith(
      filterParams: state.filterParams.copyWith(endDate: event.date),
      selectedQuickRange: null,
    ));
  }

  void _onSetQuickDateRange(
    SetQuickDateRangeEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (event.rangeType) {
      case QuickDateRangeType.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case QuickDateRangeType.lastMonth:
        final lastMonth = now.month == 1
            ? DateTime(now.year - 1, 12, 1)
            : DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(
            lastMonth.year, lastMonth.month + 1, 0); // Last day of last month
        break;
      case QuickDateRangeType.last3Months:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case QuickDateRangeType.last6Months:
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
    }

    emit(state.copyWith(
      filterParams: state.filterParams.copyWith(
        startDate: startDate,
        endDate: endDate,
      ),
      selectedQuickRange: event.rangeType,
    ));
  }

  void _onSetSearchQuery(
    SetSearchQueryEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) {
    emit(state.copyWith(
      filterParams: state.filterParams.copyWith(searchQuery: event.query),
    ));
  }

  void _onClearFilters(
    ClearFiltersEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) {
    emit(state.copyWith(
      filterParams: const ReceiptFilterParams(),
      selectedQuickRange: null,
    ));
  }

  void _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) {
    // The actual filtering will be handled by the browse screen
    // This just closes the modal with the current filter params
  }

  QuickDateRangeType? _getQuickRangeFromDates(
      DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return null;

    final now = DateTime.now();

    if (startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == 1 &&
        _isSameDay(endDate, now)) {
      return QuickDateRangeType.thisMonth;
    }

    return null;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
