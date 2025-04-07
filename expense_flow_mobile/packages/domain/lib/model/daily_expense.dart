import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_expense.freezed.dart';
part 'daily_expense.g.dart';

@freezed
class DailyExpense with _$DailyExpense {
  const factory DailyExpense({
    required int day,
    required double total,
    @JsonKey(name: 'transaction_datetime')
    required DateTime transactionDatetime,
  }) = _DailyExpense;

  factory DailyExpense.fromJson(Map<String, dynamic> json) =>
      _$DailyExpenseFromJson(json);
}
