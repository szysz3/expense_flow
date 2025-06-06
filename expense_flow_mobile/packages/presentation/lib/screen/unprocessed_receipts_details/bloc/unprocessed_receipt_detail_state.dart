import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/app_error.dart';

part 'unprocessed_receipt_detail_state.freezed.dart';

@freezed
class UnprocessedReceiptDetailState with _$UnprocessedReceiptDetailState {
  const factory UnprocessedReceiptDetailState({
    @Default(false) bool isDeleting,
    @Default(false) bool isDeleted,
    AppError? error,
  }) = _UnprocessedReceiptDetailState;
}
