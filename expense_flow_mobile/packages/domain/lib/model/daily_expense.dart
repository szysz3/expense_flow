// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_expense.freezed.dart';
part 'daily_expense.g.dart';

@freezed
class DailyExpense with _$DailyExpense {
  const factory DailyExpense({
    @JsonKey(defaultValue: 0) required int day,
    @JsonKey(defaultValue: 0) required double total,
    @JsonKey(name: 'transaction_datetime')
    required DateTime transactionDatetime,
  }) = _DailyExpense;

  factory DailyExpense.fromJson(Map<String, dynamic> json) =>
      _$DailyExpenseFromJson(json);
}
