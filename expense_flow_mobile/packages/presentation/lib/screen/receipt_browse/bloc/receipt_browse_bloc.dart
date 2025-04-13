import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'receipt_browse_event.dart';
import 'receipt_browse_state.dart';

class ReceiptBrowseBloc extends Bloc<ReceiptBrowseEvent, ReceiptBrowseState> {
  final Logger _logger;
  final LocalizationService _localizationService;

  ReceiptBrowseBloc(
    this._logger,
    this._localizationService,
  ) : super(const ReceiptBrowseState()) {
    on<InitEvent>(_onInit);
    on<RefreshEvent>(_onRefresh);
  }

  Future<void> _onInit(
    InitEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      await Future.delayed(const Duration(milliseconds: 500));

      emit(state.copyWith(
        isLoading: false,
      ));
    } catch (e, stackTrace) {
      _logger.e(
        'Exception in ReceiptBrowseBloc.onInit',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(const ReceiptBrowseEvent.init()),
          localizationService: _localizationService,
        ),
      ));
    }
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    try {
      emit(state.copyWith(isRefreshing: true, error: null));

      await Future.delayed(const Duration(milliseconds: 500));

      emit(state.copyWith(
        isRefreshing: false,
      ));
    } catch (e, stackTrace) {
      _logger.e(
        'Exception in ReceiptBrowseBloc.onRefresh',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isRefreshing: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(const ReceiptBrowseEvent.refresh()),
          localizationService: _localizationService,
        ),
      ));
    }
  }
}
