import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_browse_event.freezed.dart';

@freezed
class ReceiptBrowseEvent with _$ReceiptBrowseEvent {
  const factory ReceiptBrowseEvent.init() = InitEvent;

  const factory ReceiptBrowseEvent.refresh() = RefreshEvent;

  const factory ReceiptBrowseEvent.loadMore() = LoadMoreEvent;

  const factory ReceiptBrowseEvent.deleteReceipt(String receiptId) =
      DeleteReceiptEvent;

  const factory ReceiptBrowseEvent.notifyReceiptDeleted(String receiptId) =
      NotifyReceiptDeletedEvent;

  const factory ReceiptBrowseEvent.resetDeletedState() = ResetDeletedStateEvent;
}
