import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/standing_order.dart';

part 'standing_orders_state.freezed.dart';

abstract class BaseStandingOrdersState {}

@freezed
class StandingOrdersState with _$StandingOrdersState {
  const factory StandingOrdersState({
    @Default([]) List<StandingOrder> orders,
    @Default(false) bool isAddingNew,
  }) = _StandingOrdersState;
}
