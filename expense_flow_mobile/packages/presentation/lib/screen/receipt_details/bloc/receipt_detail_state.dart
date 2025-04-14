import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/app_error.dart';

part 'receipt_detail_state.freezed.dart';

@freezed
class ReceiptDetailState with _$ReceiptDetailState {
  const factory ReceiptDetailState({
    @Default(false) bool isDeleting,
    @Default(false) bool isDeleted,
    AppError? error,
  }) = _ReceiptDetailState;
}
