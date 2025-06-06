import 'package:domain/model/unprocessed_receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'unprocessed_receipt_edit_state.freezed.dart';

@freezed
class UnprocessedReceiptEditState with _$UnprocessedReceiptEditState {
  const factory UnprocessedReceiptEditState({
    @Default(false) bool isEditMode,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
    UnprocessedReceipt? receipt,
    UnprocessedReceipt? originalReceipt,
    AppError? error,
  }) = _UnprocessedReceiptEditState;

  const UnprocessedReceiptEditState._();

  bool get hasChanges {
    if (receipt == null || originalReceipt == null) return false;

    if (receipt!.rawData.merchant != originalReceipt!.rawData.merchant)
      return true;

    if (receipt!.rawData.transactionDatetime !=
        originalReceipt!.rawData.transactionDatetime) {
      return true;
    }

    if (receipt!.rawData.total != originalReceipt!.rawData.total) return true;

    if (receipt!.rawData.items.length != originalReceipt!.rawData.items.length)
      return true;

    for (int i = 0; i < receipt!.rawData.items.length; i++) {
      if (receipt!.rawData.items[i] != originalReceipt!.rawData.items[i])
        return true;
    }

    return false;
  }
}
