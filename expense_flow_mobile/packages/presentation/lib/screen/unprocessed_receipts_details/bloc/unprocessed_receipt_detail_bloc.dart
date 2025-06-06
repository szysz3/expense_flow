import 'package:domain/use_case/unprocessed_receipt/unprocessed_receipt_delete_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/app_error.dart';
import 'unprocessed_receipt_detail_event.dart';
import 'unprocessed_receipt_detail_state.dart';

class UnprocessedReceiptDetailBloc
    extends Bloc<UnprocessedReceiptDetailEvent, UnprocessedReceiptDetailState> {
  final UnprocessedReceiptDeleteUseCase _deleteUnprocessedReceiptUseCase;
  final Logger _logger;
  final LocalizationService _localizationService;

  UnprocessedReceiptDetailBloc(
    this._deleteUnprocessedReceiptUseCase,
    this._logger,
    this._localizationService,
  ) : super(const UnprocessedReceiptDetailState()) {
    on<DeleteUnprocessedReceiptEvent>(_onDeleteUnprocessedReceipt);
  }

  Future<void> _onDeleteUnprocessedReceipt(
    DeleteUnprocessedReceiptEvent event,
    Emitter<UnprocessedReceiptDetailState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, isDeleted: false, error: null));

    try {
      final result = await _deleteUnprocessedReceiptUseCase(
        UnprocessedReceiptDeleteParams(id: event.receiptId),
      );

      result.fold(
        (failure) {
          _logger.e(
            'Failed to delete unprocessed receipt',
            error: failure,
          );

          emit(state.copyWith(
            isDeleting: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(
                  UnprocessedReceiptDetailEvent.deleteReceipt(event.receiptId)),
              localizationService: _localizationService,
            ),
          ));
        },
        (success) {
          emit(state.copyWith(
            isDeleting: false,
            isDeleted: true,
            error: null,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Exception in UnprocessedReceiptDetailBloc._onDeleteUnprocessedReceipt',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isDeleting: false,
        error: AppError.fromException(
          e,
          onRetry: () =>
              add(UnprocessedReceiptDetailEvent.deleteReceipt(event.receiptId)),
          localizationService: _localizationService,
        ),
      ));
    }
  }
}
