import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_detail_event.freezed.dart';

@freezed
class ReceiptDetailEvent with _$ReceiptDetailEvent {
  const factory ReceiptDetailEvent.deleteReceipt(String receiptId) =
      DeleteReceiptEvent;
}
