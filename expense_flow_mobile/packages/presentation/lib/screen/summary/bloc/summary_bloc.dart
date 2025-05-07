import 'dart:async';

import 'package:domain/model/failure/failures.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:domain/use_case/settings/get_month_savings_settings_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
  final GetMonthSavingsSettingsUseCase _getMonthSavingsSettingsUseCase;
  final Logger _errorLogger;
  final LocalizationService _localizationService;
  Completer<void>? _refreshCompleter;

  SummaryBloc(
      this._getMonthsSummaryUseCase,
      this._getMonthSavingsSettingsUseCase,
      this._errorLogger,
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

  String _getMonthName(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) return 'Unknown';
    final dateTime = DateTime(DateTime.now().year, monthNumber);
    return DateFormat('MMMM').format(dateTime);
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<SummaryState> emit,
  ) async {
    try {
      _refreshCompleter = Completer<void>();
      emit(state.copyWith(isLoading: true, error: null));

      final monthsResult = await _getMonthsSummaryUseCase(const NoParams());
      if (monthsResult.isLeft()) {
        final failure = monthsResult.fold<Failure>(
          (failure) => failure,
          (_) => throw StateError('Unexpected state'),
        );

        _errorLogger.e('Failed to get months summary', error: failure);

        emit(state.copyWith(
          isLoading: false,
          error: AppError.fromFailure(
            failure,
            onRetry: () => add(const SummaryEvent.init()),
            localizationService: _localizationService,
          ),
        ));
        _refreshCompleter?.complete();
        return;
      }

      final domainMonths = monthsResult.fold<List<dynamic>>(
        (_) => [],
        (data) => data,
      );

      final monthYearPairs = domainMonths
          .map<(int, int)>(
              (month) => (month.monthNumber as int, month.year as int))
          .toList();

      final savingsResult = await _getMonthSavingsSettingsUseCase(
          GetMonthSavingsSettingsParams(monthYearPairs: monthYearPairs));

      if (savingsResult.isLeft()) {
        final failure = savingsResult.fold<Failure>(
          (failure) => failure,
          (_) => throw StateError('Unexpected state'),
        );

        _errorLogger.e('Failed to get savings settings', error: failure);

        emit(state.copyWith(
          isLoading: false,
          error: AppError.fromFailure(
            failure,
            onRetry: () => add(const SummaryEvent.init()),
            localizationService: _localizationService,
          ),
        ));
        _refreshCompleter?.complete();
        return;
      }

      final savingsMap = savingsResult.fold<Map<(int, int), dynamic>>(
        (_) => {},
        (data) => data,
      );

      final presentationMonths = domainMonths.map((dynamic month) {
        final monthNumber = month.monthNumber as int;
        final year = month.year as int;
        final monthName = _getMonthName(monthNumber);

        double income = 0.0;
        double expectedSavingsAmount = 0.0;
        final key = (monthNumber, year);
        if (savingsMap.containsKey(key)) {
          income = savingsMap[key]!.income as double;
          expectedSavingsAmount = savingsMap[key]!.savingsAmount as double;
        }

        return MonthSummary(
            id: month.id as String,
            monthNumber: monthNumber,
            monthName: monthName,
            year: year,
            previousMonthAmount: month.previousMonthTotal as double,
            categories: (month.categories as List<dynamic>)
                .map<CategorySummary>((dynamic category) => CategorySummary(
                      id: category.id as String,
                      name: category.name as String,
                      iconName: category.iconName as String,
                      amount: category.amount as double,
                      previousMonthAmount:
                          category.previousMonthAmount as double,
                    ))
                .toList(),
            income: income,
            expectedSavingsAmount: expectedSavingsAmount);
      }).toList();

      final totalSavings = presentationMonths.fold<double>(
        0.0,
        (sum, month) => sum + month.calculateSavings(),
      );

      emit(state.copyWith(
        months: presentationMonths,
        isLoading: false,
        totalSavings: totalSavings,
        error: null,
      ));
      _refreshCompleter?.complete();
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in SummaryBloc',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(const SummaryEvent.init()),
          localizationService: _localizationService,
        ),
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
