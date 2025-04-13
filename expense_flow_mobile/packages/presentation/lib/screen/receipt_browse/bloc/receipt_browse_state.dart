import 'package:domain/model/receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'receipt_browse_state.freezed.dart';

@freezed
class ReceiptBrowseState with _$ReceiptBrowseState {
  const factory ReceiptBrowseState({
    @Default([]) List<Receipt> receipts,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMoreReceipts,
    @Default(0) int totalCount,
    AppError? error,
  }) = _ReceiptBrowseState;
}
