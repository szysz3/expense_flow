// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_item.freezed.dart';
part 'receipt_item.g.dart';

@freezed
class ReceiptItem with _$ReceiptItem {
  const factory ReceiptItem({
    required String description,
    @JsonKey(defaultValue: 0) required double quantity,
    @JsonKey(name: 'total_price', defaultValue: 0) required double totalPrice,
    String? category,
  }) = _ReceiptItem;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);
}
