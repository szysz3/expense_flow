import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_query.freezed.dart';
part 'receipt_query.g.dart';

@freezed
class ReceiptQuery with _$ReceiptQuery {
  const factory ReceiptQuery({
    String? merchantName,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    String? itemDescription,
  }) = _ReceiptQuery;

  factory ReceiptQuery.fromJson(Map<String, dynamic> json) =>
      _$ReceiptQueryFromJson(json);
}
