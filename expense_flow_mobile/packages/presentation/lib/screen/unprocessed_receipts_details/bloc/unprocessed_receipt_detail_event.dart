import 'package:freezed_annotation/freezed_annotation.dart';

part 'unprocessed_receipt_detail_event.freezed.dart';

@freezed
class UnprocessedReceiptDetailEvent with _$UnprocessedReceiptDetailEvent {
  const factory UnprocessedReceiptDetailEvent.deleteReceipt(String receiptId) =
      DeleteUnprocessedReceiptEvent;
}
