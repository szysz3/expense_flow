import 'package:freezed_annotation/freezed_annotation.dart';

part 'standing_order.freezed.dart';

@freezed
class StandingOrder with _$StandingOrder {
  const factory StandingOrder({
    required String id,
    required String name,
    required double amount,
  }) = _StandingOrder;
}
