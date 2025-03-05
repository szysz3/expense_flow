import 'package:domain/model/unprocessed_receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'unprocessed_receipts_state.freezed.dart';

@freezed
class UnprocessedReceiptsState with _$UnprocessedReceiptsState {
  const factory UnprocessedReceiptsState({
    @Default([]) List<UnprocessedReceipt> receipts,
    @Default(false) bool isLoading,
    AppError? error,
  }) = _UnprocessedReceiptsState;
}
