import 'dart:async';

import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/app_error.dart';
import '../model/category_summary.dart';
import '../model/month_summary.dart';
import '../model/summary_display_type.dart';
import 'summary_events.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  final GetMonthsSummaryUseCase _getMonthsSummaryUseCase;
  final Logger _errorLogger;
  final LocalizationService _localizationService;
  Completer<void>? _refreshCompleter;

  SummaryBloc(this._getMonthsSummaryUseCase, this._errorLogger,
      this._localizationService)
      : super(const SummaryState()) {
    on<InitEvent>(_handleInit);
    on<ToggleMonthEvent>(_handleToggleMonth);
    on<DisplayBarChartEvent>(_handleDisplayBarChart);
    on<DisplayPieChartEvent>(_handleDisplayPieChart);
    on<DisplayListEvent>(_handleDisplayList);
  }

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

      emit(state.copyWith(isLoading: true, error: null));

      final result = await _getMonthsSummaryUseCase(const NoParams());

      result.fold(
        (failure) {
          _errorLogger.e(
            'Failed to get months summary',
            error: failure,
          );

          emit(state.copyWith(
            isLoading: false,
            error: AppError.fromFailure(failure,
                onRetry: () => add(const SummaryEvent.init()),
                localizationService: _localizationService),
          ));
          _refreshCompleter?.complete();
        },
        (monthsSummary) {
          final presentationMonths = monthsSummary.map((month) {
            return MonthSummary(
              id: month.id,
              month: month.month,
              previousMonthAmount: month.previousMonthTotal,
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
            error: null,
          ));
          _refreshCompleter?.complete();
        },
      );
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in SummaryBloc',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(e,
            onRetry: () => add(const SummaryEvent.init()),
            localizationService: _localizationService),
      ));
      _refreshCompleter?.complete();
    }
  }

  void _handleToggleMonth(
    ToggleMonthEvent event,
    Emitter<SummaryState> emit,
  ) {
    try {
      final updatedMonths = state.months.map((month) {
        if (month.id == event.monthId) {
          return month.copyWith(isExpanded: !month.isExpanded);
        }
        return month;
      }).toList();

      emit(state.copyWith(months: updatedMonths));
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Error toggling month',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleDisplayBarChart(
    DisplayBarChartEvent event,
    Emitter<SummaryState> emit,
  ) {
    emit(state.copyWith(displayType: SummaryDisplayType.barChart));
  }

  void _handleDisplayPieChart(
    DisplayPieChartEvent event,
    Emitter<SummaryState> emit,
  ) {
    emit(state.copyWith(displayType: SummaryDisplayType.pieChart));
  }

  void _handleDisplayList(
    DisplayListEvent event,
    Emitter<SummaryState> emit,
  ) {
    emit(state.copyWith(displayType: SummaryDisplayType.list));
  }
}
