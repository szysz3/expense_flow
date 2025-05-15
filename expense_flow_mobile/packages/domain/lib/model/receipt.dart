// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import 'merchant.dart';
import 'receipt_item.dart';

part 'receipt.freezed.dart';
part 'receipt.g.dart';

@freezed
class Receipt with _$Receipt {
  const factory Receipt({
    String? id,
    required Merchant merchant,
    required List<ReceiptItem> items,
    required double total,
    @JsonKey(name: 'transaction_datetime')
    required DateTime transactionDateTime,
    @JsonKey(name: 'added_datetime') required DateTime addedDateTime,
  }) = _Receipt;

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);
}
