import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/use_case/settings/settings_get_all_periods_use_case.dart';
import 'package:domain/use_case/settings/settings_save_savings_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Logger _logger;
  final LocalizationService _localizationService;
  final SettingsGetAllPeriodsUseCase _getAllPeriodsUseCase;
  final SettingsSaveSavingsUseCase _saveSavingsSettingsUseCase;
  int _idCounter = 0;

  SettingsBloc(
    this._logger,
    this._localizationService,
    this._getAllPeriodsUseCase,
    this._saveSavingsSettingsUseCase,
  ) : super(const SettingsState()) {
    on<InitEvent>(_onInit);
    on<PeriodAddedEvent>(_onPeriodAdded);
    on<PeriodRemovedEvent>(_onPeriodRemoved);
    on<PeriodStartChangedEvent>(_onPeriodStartChanged);
    on<PeriodEndChangedEvent>(_onPeriodEndChanged);
    on<PeriodIncomeChangedEvent>(_onPeriodIncomeChanged);
    on<PeriodSavingsChangedEvent>(_onPeriodSavingsChanged);
    on<ToggleOpenEndedEvent>(_onToggleOpenEnded);
    on<SaveSettingsEvent>(_onSaveSettings);
  }

  void _onInit(InitEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      _idCounter = 0;
      final periodsResult = await _getAllPeriodsUseCase(const NoParams());

      periodsResult.fold(
        (failure) {
          _logger.e('Failed to load savings periods', error: failure);
          emit(state.copyWith(
            isLoading: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(const SettingsEvent.init()),
              localizationService: _localizationService,
            ),
          ));
        },
        (periods) {
          final mappedPeriods = periods
              .map((settings) => SettingsPeriodForm.fromSavingsSettings(
                    settings,
                    id: _generateId(),
                  ))
              .toList();

          if (mappedPeriods.isEmpty) {
            mappedPeriods.add(_createInitialPeriod());
          }

          emit(state.copyWith(
            isLoading: false,
            periods: mappedPeriods,
            validationMessage: null,
            error: null,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Exception loading settings', error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(
          e,
          localizationService: _localizationService,
          onRetry: () => add(const SettingsEvent.init()),
        ),
      ));
    }
  }

  void _onPeriodAdded(PeriodAddedEvent event, Emitter<SettingsState> emit) {
    final periods = List<SettingsPeriodForm>.from(state.periods);

    if (periods.isNotEmpty && periods.last.isOpenEnded) {
      emit(state.copyWith(
        validationMessage:
            _localizationService.localizations.settingsCloseOpenPeriodFirst,
      ));
      return;
    }

    final newPeriod = _createNextPeriod(periods);
    periods.add(newPeriod);

    emit(state.copyWith(periods: periods, validationMessage: null));
  }

  void _onPeriodRemoved(PeriodRemovedEvent event, Emitter<SettingsState> emit) {
    final periods =
        state.periods.where((period) => period.id != event.id).toList();

    if (periods.isEmpty) {
      periods.add(_createInitialPeriod());
    }

    emit(state.copyWith(periods: periods, validationMessage: null));
  }

  void _onPeriodStartChanged(
      PeriodStartChangedEvent event, Emitter<SettingsState> emit) {
    final periods = state.periods.map((period) {
      if (period.id != event.id) {
        return period;
      }

      var updated = period.copyWith(
        startMonth: event.month,
        startYear: event.year,
      );

      if (!updated.isOpenEnded &&
          _isEndBeforeStart(
            updated.endYear!,
            updated.endMonth!,
            updated.startYear,
            updated.startMonth,
          )) {
        updated = updated.copyWith(
          endMonth: updated.startMonth,
          endYear: updated.startYear,
        );
      }

      return updated;
    }).toList();

    emit(state.copyWith(periods: periods, validationMessage: null));
  }

  void _onPeriodEndChanged(
      PeriodEndChangedEvent event, Emitter<SettingsState> emit) {
    final periods = state.periods.map((period) {
      if (period.id != event.id) {
        return period;
      }

      if (event.month == null || event.year == null) {
        return period.copyWith(clearEnd: true);
      }

      final adjusted = period.copyWith(
        endMonth: event.month,
        endYear: event.year,
      );

      if (_isEndBeforeStart(
        adjusted.endYear!,
        adjusted.endMonth!,
        adjusted.startYear,
        adjusted.startMonth,
      )) {
        return adjusted.copyWith(
          endMonth: adjusted.startMonth,
          endYear: adjusted.startYear,
        );
      }

      return adjusted;
    }).toList();

    emit(state.copyWith(periods: periods, validationMessage: null));
  }

  void _onPeriodIncomeChanged(
      PeriodIncomeChangedEvent event, Emitter<SettingsState> emit) {
    final periods = state.periods.map((period) {
      if (period.id != event.id) {
        return period;
      }

      return period.copyWith(
        income: double.tryParse(event.income) ?? 0.0,
      );
    }).toList();

    emit(state.copyWith(periods: periods, validationMessage: null));
  }

  void _onPeriodSavingsChanged(
      PeriodSavingsChangedEvent event, Emitter<SettingsState> emit) {
    final periods = state.periods.map((period) {
      if (period.id != event.id) {
        return period;
      }

      return period.copyWith(
        savingsAmount: double.tryParse(event.savings) ?? 0.0,
      );
    }).toList();

    emit(state.copyWith(periods: periods, validationMessage: null));
  }

  void _onToggleOpenEnded(
      ToggleOpenEndedEvent event, Emitter<SettingsState> emit) {
    final periods = List<SettingsPeriodForm>.from(state.periods);
    final index = periods.indexWhere((period) => period.id == event.id);

    if (index == -1) {
      return;
    }

    if (index != periods.length - 1) {
      emit(state.copyWith(
        validationMessage:
            _localizationService.localizations.settingsOnlyLastOpenEnded,
      ));
      return;
    }

    final hasOtherOpenEnded = periods.any(
      (period) => period.id != event.id && period.isOpenEnded,
    );

    if (hasOtherOpenEnded) {
      emit(state.copyWith(
        validationMessage:
            _localizationService.localizations.settingsOnlyLastOpenEnded,
      ));
      return;
    }

    final target = periods[index];
    final updated = target.isOpenEnded
        ? target.copyWith(
            endMonth: target.startMonth,
            endYear: target.startYear,
          )
        : target.copyWith(clearEnd: true);

    periods[index] = updated;

    emit(state.copyWith(periods: periods, validationMessage: null));
  }

  void _onSaveSettings(
      SaveSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isSaving: true, error: null, validationMessage: null));

    try {
      final sortedPeriods = state.periods.toList()
        ..sort((a, b) {
          final yearComparison = a.startYear.compareTo(b.startYear);
          if (yearComparison != 0) {
            return yearComparison;
          }
          return a.startMonth.compareTo(b.startMonth);
        });

      final result = await _saveSavingsSettingsUseCase(
        sortedPeriods.map((period) => period.toSavingsSettings()).toList(),
      );

      result.fold(
        (failure) {
          _logger.e('Failed to save savings periods', error: failure);

          if (failure is ValidationFailure) {
            final message = failure.details.isNotEmpty &&
                    failure.details.first.containsKey('msg')
                ? failure.details.first['msg'] as String
                : _localizationService.localizations.settingsValidationGeneric;

            emit(state.copyWith(
              isSaving: false,
              validationMessage: message,
            ));
          } else {
            emit(state.copyWith(
              isSaving: false,
              error: AppError.fromFailure(
                failure,
                onRetry: () => add(const SettingsEvent.saveSettings()),
                localizationService: _localizationService,
              ),
            ));
          }
        },
        (settings) {
          emit(state.copyWith(
            isSaving: false,
            periods: state.periods,
            validationMessage: null,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Exception saving settings', error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        isSaving: false,
        error: AppError.fromException(
          e,
          localizationService: _localizationService,
          onRetry: () => add(const SettingsEvent.saveSettings()),
        ),
      ));
    }
  }

  SettingsPeriodForm _createInitialPeriod() {
    final now = DateTime.now();
    return SettingsPeriodForm(
      id: _generateId(),
      startMonth: now.month,
      startYear: now.year,
      endMonth: now.month,
      endYear: now.year,
    );
  }

  SettingsPeriodForm _createNextPeriod(List<SettingsPeriodForm> current) {
    if (current.isEmpty) {
      return _createInitialPeriod();
    }

    final last = current.last;

    var nextMonth = last.endMonth ?? last.startMonth;
    var nextYear = last.endYear ?? last.startYear;

    final incremented = _incrementMonth(nextMonth, nextYear);

    return SettingsPeriodForm(
      id: _generateId(),
      startMonth: incremented.$1,
      startYear: incremented.$2,
      endMonth: incremented.$1,
      endYear: incremented.$2,
      income: last.income,
      savingsAmount: last.savingsAmount,
    );
  }

  (int, int) _incrementMonth(int month, int year) {
    if (month == 12) {
      return (1, year + 1);
    }
    return (month + 1, year);
  }

  bool _isEndBeforeStart(
    int endYear,
    int endMonth,
    int startYear,
    int startMonth,
  ) {
    if (endYear < startYear) {
      return true;
    }
    if (endYear == startYear && endMonth < startMonth) {
      return true;
    }
    return false;
  }

  String _generateId() {
    _idCounter += 1;
    return _idCounter.toString();
  }
}
