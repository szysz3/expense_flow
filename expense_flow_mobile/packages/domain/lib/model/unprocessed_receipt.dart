// ignore_for_file: invalid_annotation_target
import 'package:domain/model/raw_receipt_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unprocessed_receipt.freezed.dart';
part 'unprocessed_receipt.g.dart';

enum UnprocessedReceiptStatus { pending, processing, error }

@freezed
class UnprocessedReceipt with _$UnprocessedReceipt {
  const factory UnprocessedReceipt({
    required String id,
    @JsonKey(name: "raw_data") required RawReceiptData rawData,
    required UnprocessedReceiptStatus status,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "error_message") String? errorMessage,
  }) = _UnprocessedReceipt;

  factory UnprocessedReceipt.fromJson(Map<String, dynamic> json) =>
      _$UnprocessedReceiptFromJson(json);
}

@freezed
class UnprocessedReceiptsResponse with _$UnprocessedReceiptsResponse {
  const factory UnprocessedReceiptsResponse({
    @Default([]) List<UnprocessedReceipt> receipts,
    @Default(0) int totalCount,
  }) = _UnprocessedReceiptsResponse;

  factory UnprocessedReceiptsResponse.fromJson(Map<String, dynamic> json) =>
      _$UnprocessedReceiptsResponseFromJson(json);
}
