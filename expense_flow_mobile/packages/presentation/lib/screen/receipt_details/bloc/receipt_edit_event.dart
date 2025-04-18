import 'package:domain/model/merchant.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_edit_event.freezed.dart';

@freezed
class ReceiptEditEvent with _$ReceiptEditEvent {
  const factory ReceiptEditEvent.toggleEditMode() = ToggleEditModeEvent;

  const factory ReceiptEditEvent.updateMerchant(Merchant merchant) =
      UpdateMerchantEvent;

  const factory ReceiptEditEvent.updateItems(List<ReceiptItem> items) =
      UpdateItemsEvent;

  const factory ReceiptEditEvent.updateTransactionDateTime(DateTime dateTime) =
      UpdateTransactionDateTimeEvent;

  const factory ReceiptEditEvent.saveChanges() = SaveChangesEvent;

  const factory ReceiptEditEvent.cancelEdit() = CancelEditEvent;

  const factory ReceiptEditEvent.updateTotal(double total) = UpdateTotalEvent;
}
