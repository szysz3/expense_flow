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
    required DateTime transactionDateTime,
    required DateTime addedDateTime,
  }) = _Receipt;

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);
}
