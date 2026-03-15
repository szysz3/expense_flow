// ignore_for_file: invalid_annotation_target
import 'package:domain/model/receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_get_response.freezed.dart';
part 'receipt_get_response.g.dart';

@freezed
class ReceiptGetResponse with _$ReceiptGetResponse {
  const factory ReceiptGetResponse({
    required List<Receipt> receipts,
    @JsonKey(defaultValue: 0) required int totalCount,
  }) = _ReceiptGetResponse;

  factory ReceiptGetResponse.fromJson(Map<String, dynamic> json) =>
      _$ReceiptGetResponseFromJson(json);
}
