import 'package:domain/model/receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'receipt_filtering_state.freezed.dart';

@freezed
class ReceiptFilteringState with _$ReceiptFilteringState {
  const factory ReceiptFilteringState({
    AppError? error,
  }) = _ReceiptFilteringState;
}
