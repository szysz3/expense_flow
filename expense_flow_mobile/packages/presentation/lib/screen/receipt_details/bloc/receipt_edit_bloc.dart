import 'package:domain/model/receipt.dart';
import 'package:domain/use_case/receipt/receipt_update_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'receipt_edit_event.dart';
import 'receipt_edit_state.dart';

class ReceiptEditBloc extends Bloc<ReceiptEditEvent, ReceiptEditState> {
  final Logger _logger;
  final LocalizationService _localizationService;
  final ReceiptUpdateUseCase _updateReceiptUseCase;

  ReceiptEditBloc(
    this._logger,
    this._localizationService,
    this._updateReceiptUseCase,
    Receipt initialReceipt,
  ) : super(ReceiptEditState(
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
      ToggleEditModeEvent event, Emitter<ReceiptEditState> emit) {
    emit(state.copyWith(isEditMode: !state.isEditMode));
  }

  void _onUpdateMerchant(
      UpdateMerchantEvent event, Emitter<ReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(merchant: event.merchant),
    ));
  }

  void _onUpdateItems(UpdateItemsEvent event, Emitter<ReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(items: event.items),
    ));
  }

  void _onUpdateTransactionDateTime(
      UpdateTransactionDateTimeEvent event, Emitter<ReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(transactionDateTime: event.dateTime),
    ));
  }

  void _onUpdateTotal(UpdateTotalEvent event, Emitter<ReceiptEditState> emit) {
    if (state.receipt == null) return;

    emit(state.copyWith(
      receipt: state.receipt!.copyWith(total: event.total),
    ));
  }

  void _onCancelEdit(CancelEditEvent event, Emitter<ReceiptEditState> emit) {
    if (state.originalReceipt == null) return;

    emit(state.copyWith(
      isEditMode: false,
      receipt: state.originalReceipt,
      error: null,
    ));
  }

  Future<void> _onSaveChanges(
      SaveChangesEvent event, Emitter<ReceiptEditState> emit) async {
    if (state.receipt == null) return;

    emit(state.copyWith(isSaving: true, error: null));

    try {
      final result = await _updateReceiptUseCase(state.receipt!);

      result.fold(
        (failure) {
          _logger.e('Failed to update receipt', error: failure);
          emit(state.copyWith(
            isSaving: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(const ReceiptEditEvent.saveChanges()),
              localizationService: _localizationService,
            ),
          ));
        },
        (updatedReceipt) {
          _logger.i('Receipt updated successfully: ${updatedReceipt.id}');
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
        'Exception updating receipt',
        error: e,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(
        isSaving: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(const ReceiptEditEvent.saveChanges()),
          localizationService: _localizationService,
        ),
      ));
    }
  }
}
