import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'receipt_browse_state.freezed.dart';

@freezed
class ReceiptBrowseState with _$ReceiptBrowseState {
  const factory ReceiptBrowseState({
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    AppError? error,
  }) = _ReceiptBrowseState;
}
