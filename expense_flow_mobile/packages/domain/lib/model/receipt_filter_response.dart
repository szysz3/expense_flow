import 'package:freezed_annotation/freezed_annotation.dart';

import 'filtered_receipt_item.dart';

part 'receipt_filter_response.freezed.dart';

@freezed
class ReceiptFilterResponse with _$ReceiptFilterResponse {
  const factory ReceiptFilterResponse({
    required List<FilteredReceiptItem> items,
    required double totalAmount,
    required int totalCount,
  }) = _ReceiptFilterResponse;
}
