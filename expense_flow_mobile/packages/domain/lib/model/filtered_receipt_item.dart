import 'package:freezed_annotation/freezed_annotation.dart';

import 'receipt.dart';
import 'receipt_item.dart';

part 'filtered_receipt_item.freezed.dart';

@freezed
class FilteredReceiptItem with _$FilteredReceiptItem {
  const factory FilteredReceiptItem({
    required ReceiptItem item,
    required Receipt parentReceipt,
  }) = _FilteredReceiptItem;

  const FilteredReceiptItem._();

  double get amount => item.totalPrice;

  String get name => item.description;

  String? get category => item.category;

  DateTime get date => parentReceipt.transactionDateTime;

  String get merchantName => parentReceipt.merchant.name;
}
