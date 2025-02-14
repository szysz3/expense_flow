import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/summary/service/summary_data_service.dart';

import 'summary_events.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final SummaryDataService _dataService;

  SummaryBloc({
    SummaryDataService? dataService,
  })  : _dataService = dataService ?? MockSummaryDataService(),
        super(const SummaryState()) {
    on<InitEvent>(_handleInit);
    on<ToggleMonthEvent>(_handleToggleMonth);
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<SummaryState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      final months = await _dataService.getMonthsSummary();
      emit(state.copyWith(
        months: months,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _handleToggleMonth(
    ToggleMonthEvent event,
    Emitter<SummaryState> emit,
  ) {
    final updatedMonths = state.months.map((month) {
      if (month.id == event.monthId) {
        return month.copyWith(isExpanded: !month.isExpanded);
      }
      return month;
    }).toList();

    emit(state.copyWith(months: updatedMonths));
  }
}
