import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/settings/get_savings_settings_use_case.dart';
import 'package:domain/use_case/settings/save_savings_settings_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Logger _logger;
  final LocalizationService _localizationService;
  final GetSavingsSettingsUseCase _getSavingsSettingsUseCase;
  final SaveSavingsSettingsUseCase _saveSavingsSettingsUseCase;

  SettingsBloc(
    this._logger,
    this._localizationService,
    this._getSavingsSettingsUseCase,
    this._saveSavingsSettingsUseCase,
  ) : super(const SettingsState()) {
    on<InitEvent>(_onInit);
    on<SavingsAmountChangedEvent>(_onSavingsAmountChanged);
    on<IncomeChangedEvent>(_onIncomeChanged);
    on<SaveSettingsEvent>(_onSaveSettings);
  }

  void _onInit(InitEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final currentMonthResult =
          await _getSavingsSettingsUseCase(const NoParams());

      currentMonthResult.fold(
        (failure) {
          _logger.e('Failed to load current month settings', error: failure);
          emit(state.copyWith(
            isLoading: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(const SettingsEvent.init()),
              localizationService: _localizationService,
            ),
          ));
        },
        (savingsSettings) {
          emit(state.copyWith(
            isLoading: false,
            savingsAmount: savingsSettings.savingsAmount,
            income: savingsSettings.income,
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

  void _onSavingsAmountChanged(
      SavingsAmountChangedEvent event, Emitter<SettingsState> emit) {
    final amount = double.tryParse(event.amount) ?? 0.0;
    emit(state.copyWith(savingsAmount: amount));
  }

  void _onIncomeChanged(IncomeChangedEvent event, Emitter<SettingsState> emit) {
    final income = double.tryParse(event.income) ?? 0.0;
    emit(state.copyWith(income: income));
  }

  void _onSaveSettings(
      SaveSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));

    try {
      final currentMonthSettings = state.toSavingsSettings();
      final result = await _saveSavingsSettingsUseCase(currentMonthSettings);

      result.fold(
        (failure) {
          _logger.e('Failed to save settings', error: failure);
          emit(state.copyWith(
            isSaving: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(const SettingsEvent.saveSettings()),
              localizationService: _localizationService,
            ),
          ));
        },
        (settings) {
          emit(state.copyWith(
            isSaving: false,
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
}
