import 'package:domain/model/raw_receipt_data.dart';
import 'package:domain/model/unprocessed_receipt.dart';
import 'package:domain/use_case/unprocessed_receipt/unprocessed_receipt_update_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'unprocessed_receipt_edit_event.dart';
import 'unprocessed_receipt_edit_state.dart';

class UnprocessedReceiptEditBloc
    extends Bloc<UnprocessedReceiptEditEvent, UnprocessedReceiptEditState> {
  final Logger _logger;
  final LocalizationService _localizationService;
  final UnprocessedReceiptUpdateUseCase _updateUnprocessedReceiptUseCase;

  UnprocessedReceiptEditBloc(
    this._logger,
    this._localizationService,
    this._updateUnprocessedReceiptUseCase,
    UnprocessedReceipt initialReceipt,
  ) : super(UnprocessedReceiptEditState(
          receipt: initialReceipt,
          originalReceipt: initialReceipt,
        )) {
    on<ToggleEditModeEvent>(_onToggleEditMode);
    on<UpdateMerchantEvent>(_onUpdateMerchant);
    on<UpdateItemsEvent>(_onUpdateItems);
    on<UpdateTransactionDateTimeEvent>(_onUpdateTransactionDateTime);
    on<SaveChangesEvent>(_onSaveChanges);
    on<CancelEditEvent>(_onCancelEdit);
    on<UpdateTotalEvent>(_onUpdateTotal);
  }

  void _onToggleEditMode(
      ToggleEditModeEvent event, Emitter<UnprocessedReceiptEditState> emit) {
    emit(state.copyWith(isEditMode: !state.isEditMode));
  }

  void _onUpdateMerchant(
      UpdateMerchantEvent event, Emitter<UnprocessedReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(
        rawData: state.receipt!.rawData.copyWith(merchant: event.merchant),
      ),
    ));
  }

  void _onUpdateItems(
      UpdateItemsEvent event, Emitter<UnprocessedReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(
        rawData: state.receipt!.rawData.copyWith(items: event.items),
      ),
    ));
  }

  void _onUpdateTransactionDateTime(UpdateTransactionDateTimeEvent event,
      Emitter<UnprocessedReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(
        rawData: state.receipt!.rawData
            .copyWith(transactionDatetime: event.dateTime),
      ),
    ));
  }

  void _onUpdateTotal(
      UpdateTotalEvent event, Emitter<UnprocessedReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(
        rawData: state.receipt!.rawData.copyWith(total: event.total),
      ),
    ));
  }

  void _onCancelEdit(
      CancelEditEvent event, Emitter<UnprocessedReceiptEditState> emit) {
    if (state.originalReceipt == null) return;

    emit(state.copyWith(
      isEditMode: false,
      receipt: state.originalReceipt,
      error: null,
    ));
  }

  Future<void> _onSaveChanges(
      SaveChangesEvent event, Emitter<UnprocessedReceiptEditState> emit) async {
    if (state.receipt == null) return;

    emit(state.copyWith(isSaving: true, error: null));

    try {
      final result = await _updateUnprocessedReceiptUseCase(state.receipt!);

      result.fold(
        (failure) {
          _logger.e('Failed to update unprocessed receipt', error: failure);
          emit(state.copyWith(
            isSaving: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () =>
                  add(const UnprocessedReceiptEditEvent.saveChanges()),
              localizationService: _localizationService,
            ),
          ));
        },
        (updatedReceipt) {
          _logger.i(
              'Unprocessed receipt updated successfully: ${updatedReceipt.id}');
          emit(state.copyWith(
            isSaving: false,
            isSaved: true,
            isEditMode: false,
            receipt: updatedReceipt,
            originalReceipt: updatedReceipt,
            error: null,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Exception updating unprocessed receipt',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isSaving: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(const UnprocessedReceiptEditEvent.saveChanges()),
          localizationService: _localizationService,
        ),
      ));
    }
  }
}
