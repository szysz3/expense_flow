import 'package:domain/model/merchant.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unprocessed_receipt_edit_event.freezed.dart';

@freezed
class UnprocessedReceiptEditEvent with _$UnprocessedReceiptEditEvent {
  const factory UnprocessedReceiptEditEvent.toggleEditMode() =
      ToggleEditModeEvent;

  const factory UnprocessedReceiptEditEvent.updateMerchant(Merchant merchant) =
      UpdateMerchantEvent;

  const factory UnprocessedReceiptEditEvent.updateItems(
      List<ReceiptItem> items) = UpdateItemsEvent;

  const factory UnprocessedReceiptEditEvent.updateTransactionDateTime(
      DateTime dateTime) = UpdateTransactionDateTimeEvent;

  const factory UnprocessedReceiptEditEvent.saveChanges() = SaveChangesEvent;

  const factory UnprocessedReceiptEditEvent.cancelEdit() = CancelEditEvent;

  const factory UnprocessedReceiptEditEvent.updateTotal(double total) =
      UpdateTotalEvent;
}
