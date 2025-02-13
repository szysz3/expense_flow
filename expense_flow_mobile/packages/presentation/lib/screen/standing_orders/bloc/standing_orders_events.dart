import 'package:freezed_annotation/freezed_annotation.dart';

part 'standing_orders_events.freezed.dart';

@freezed
class StandingOrdersEvent with _$StandingOrdersEvent {
  const factory StandingOrdersEvent.addNewOrderRequested() =
      AddNewOrderRequested;

  const factory StandingOrdersEvent.orderNameChanged({
    required String orderId,
    required String name,
  }) = OrderNameChanged;

  const factory StandingOrdersEvent.orderAmountChanged({
    required String orderId,
    required String amount,
  }) = OrderAmountChanged;

  const factory StandingOrdersEvent.orderDeleted({
    required String orderId,
  }) = OrderDeleted;

  const factory StandingOrdersEvent.orderConfirmed({
    required String orderId,
  }) = OrderConfirmed;
}
