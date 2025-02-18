import 'dart:async';

import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/category_summary.dart';
import '../model/month_summary.dart';
import 'summary_events.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final GetMonthsSummaryUseCase _getMonthsSummaryUseCase;

  SummaryBloc({
    required GetMonthsSummaryUseCase getMonthsSummaryUseCase,
  })  : _getMonthsSummaryUseCase = getMonthsSummaryUseCase,
        super(const SummaryState()) {
    on<InitEvent>(_handleInit);
    on<ToggleMonthEvent>(_handleToggleMonth);
  }

  Completer<void>? _refreshCompleter;

  Future<void> refresh() async {
    add(const SummaryEvent.init());
    return _refreshCompleter?.future;
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<SummaryState> emit,
  ) async {
    try {
      _refreshCompleter = Completer<void>();
      emit(state.copyWith(isLoading: true));

      final result = await _getMonthsSummaryUseCase(const NoParams());

      result.fold(
        (failure) {
          emit(state.copyWith(isLoading: false));
          _refreshCompleter?.complete();
        },
        (monthsSummary) {
          final presentationMonths = monthsSummary.map((month) {
            return MonthSummary(
              id: month.id,
              month: month.month,
              previousMonthTotal: month.previousMonthTotal,
              categories: month.categories
                  .map((category) => CategorySummary(
                        id: category.id,
                        name: category.name,
                        iconName: category.iconName,
                        amount: category.amount,
                        previousMonthAmount: category.previousMonthAmount,
                      ))
                  .toList(),
            );
          }).toList();

          emit(state.copyWith(
            months: presentationMonths,
            isLoading: false,
          ));
          _refreshCompleter?.complete();
        },
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _refreshCompleter?.complete();
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
