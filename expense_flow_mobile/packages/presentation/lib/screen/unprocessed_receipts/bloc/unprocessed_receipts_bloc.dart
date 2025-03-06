import 'dart:async';

import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/app_error.dart';
import 'unprocessed_receipts_event.dart';
import 'unprocessed_receipts_state.dart';

class UnprocessedReceiptsBloc
    extends Bloc<UnprocessedReceiptsEvent, UnprocessedReceiptsState> {
  final ReceiptRepository _repository;
  final Logger _errorLogger;
  final LocalizationService _localizationService;

  UnprocessedReceiptsBloc(
      this._repository, this._errorLogger, this._localizationService)
      : super(const UnprocessedReceiptsState()) {
    on<InitEvent>(_handleInit);
    on<RefreshEvent>(_handleRefresh);
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<UnprocessedReceiptsState> emit,
  ) async {
    await _loadReceipts(emit);
  }

  Future<void> _handleRefresh(
    RefreshEvent event,
    Emitter<UnprocessedReceiptsState> emit,
  ) async {
    await _loadReceipts(emit);
  }

  Future<void> _loadReceipts(Emitter<UnprocessedReceiptsState> emit) async {
    try {
      _refreshCompleter = Completer<void>();

      if (state.receipts.isEmpty) {
        emit(state.copyWith(isLoading: true, error: null));
      } else {
        emit(state.copyWith(error: null));
      }

      final result = await _repository.getUnprocessedReceipts();

      result.fold(
        (failure) {
          _errorLogger.e(
            'Failed to get unprocessed receipts',
            error: failure,
          );

          emit(state.copyWith(
            isLoading: false,
            error: AppError.fromFailure(failure,
                onRetry: () => add(const UnprocessedReceiptsEvent.refresh()),
                localizationService: _localizationService),
          ));
          _refreshCompleter?.complete();
        },
        (response) {
          emit(state.copyWith(
            receipts: response.receipts,
            isLoading: false,
            error: null,
          ));
          _refreshCompleter?.complete();
        },
      );
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in UnprocessedReceiptsBloc',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(e,
            onRetry: () => add(const UnprocessedReceiptsEvent.refresh()),
            localizationService: _localizationService),
      ));
      _refreshCompleter?.complete();
    }
  }

  Future<void> refresh() async {
    add(const UnprocessedReceiptsEvent.refresh());
    return _refreshCompleter?.future;
  }

  Completer<void>? _refreshCompleter;
}
