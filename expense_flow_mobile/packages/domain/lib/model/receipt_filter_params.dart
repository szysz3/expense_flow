import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_filter_params.freezed.dart';

@freezed
class ReceiptFilterParams with _$ReceiptFilterParams {
  const factory ReceiptFilterParams({
    @Default([]) List<String> categories,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) = _ReceiptFilterParams;

  const ReceiptFilterParams._();

  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);
}
