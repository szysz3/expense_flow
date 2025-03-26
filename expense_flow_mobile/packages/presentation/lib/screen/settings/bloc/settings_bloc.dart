import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Logger _errorLogger;
  final LocalizationService _localizationService;

  SettingsBloc(
    this._errorLogger,
    this._localizationService,
  ) : super(const SettingsState()) {
    on<InitEvent>(_handleInit);
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      // Initialize settings

      emit(state.copyWith(isLoading: false, error: null));
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in SettingsBloc.handleInit',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(e,
            onRetry: () => add(const SettingsEvent.init()),
            localizationService: _localizationService),
      ));
    }
  }
}
