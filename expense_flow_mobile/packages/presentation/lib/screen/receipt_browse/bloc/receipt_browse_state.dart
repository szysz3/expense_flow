import 'package:domain/model/filtered_receipt_item.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_filter_params.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'receipt_browse_state.freezed.dart';

@freezed
class ReceiptBrowseState with _$ReceiptBrowseState {
  const factory ReceiptBrowseState({
    // Original fields
    @Default([]) List<Receipt> receipts,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMoreReceipts,
    @Default(0) int totalCount,
    @Default(false) bool isDeleted,
    @Default('') String deleteReceiptId,
    AppError? error,

    // New fields for filtering
    @Default(false) bool isFiltered,
    @Default(ReceiptFilterParams()) ReceiptFilterParams filterParams,
    @Default([]) List<FilteredReceiptItem> filteredItems,
    @Default(0.0) double filteredTotalAmount,
  }) = _ReceiptBrowseState;
}
