import 'package:domain/use_case/receipt/receipt_delete_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/app_error.dart';
import 'receipt_detail_event.dart';
import 'receipt_detail_state.dart';

class ReceiptDetailBloc extends Bloc<ReceiptDetailEvent, ReceiptDetailState> {
  final ReceiptDeleteUseCase _deleteReceiptUseCase;
  final Logger _logger;
  final LocalizationService _localizationService;

  ReceiptDetailBloc(
    this._deleteReceiptUseCase,
    this._logger,
    this._localizationService,
  ) : super(const ReceiptDetailState()) {
    on<DeleteReceiptEvent>(_onDeleteReceipt);
  }

  Future<void> _onDeleteReceipt(
    DeleteReceiptEvent event,
    Emitter<ReceiptDetailState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, isDeleted: false, error: null));

    try {
      final result = await _deleteReceiptUseCase(
        ReceiptDeleteParams(id: event.receiptId),
      );

      result.fold(
        (failure) {
          _logger.e(
            'Failed to delete receipt',
            error: failure,
          );

          emit(state.copyWith(
            isDeleting: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () =>
                  add(ReceiptDetailEvent.deleteReceipt(event.receiptId)),
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
        'Exception in ReceiptDetailBloc._onDeleteReceipt',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isDeleting: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(ReceiptDetailEvent.deleteReceipt(event.receiptId)),
          localizationService: _localizationService,
        ),
      ));
    }
  }
}
