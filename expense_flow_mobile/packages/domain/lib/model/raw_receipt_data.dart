// ignore_for_file: invalid_annotation_target
import 'package:domain/model/receipt_item.dart';
import 'package:domain/model/safe_datetime_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'merchant.dart';

part 'raw_receipt_data.freezed.dart';
part 'raw_receipt_data.g.dart';

@freezed
class RawReceiptData with _$RawReceiptData {
  const factory RawReceiptData({
    required Merchant merchant,
    required List<ReceiptItem> items,
    required double total,
    @JsonKey(name: "transaction_datetime")
    @SafeDateTimeConverter()
    DateTime? transactionDatetime,
  }) = _RawReceiptData;

  factory RawReceiptData.fromJson(Map<String, dynamic> json) =>
      _$RawReceiptDataFromJson(json);
}
