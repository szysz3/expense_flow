import 'package:domain/model/receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'receipt_edit_state.freezed.dart';

@freezed
class ReceiptEditState with _$ReceiptEditState {
  const factory ReceiptEditState({
    @Default(false) bool isEditMode,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
    Receipt? receipt,
    Receipt? originalReceipt,
    AppError? error,
  }) = _ReceiptEditState;

  const ReceiptEditState._();

  bool get hasChanges {
    if (receipt == null || originalReceipt == null) return false;

    if (receipt!.merchant != originalReceipt!.merchant) return true;

    if (receipt!.transactionDateTime != originalReceipt!.transactionDateTime) {
      return true;
    }

    if (receipt!.total != originalReceipt!.total) return true;

    if (receipt!.items.length != originalReceipt!.items.length) return true;

    for (int i = 0; i < receipt!.items.length; i++) {
      if (receipt!.items[i] != originalReceipt!.items[i]) return true;
    }

    return false;
  }
}
