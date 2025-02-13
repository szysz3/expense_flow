import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/standing_order.dart';
import 'standing_orders_events.dart';
import 'standing_orders_state.dart';

class StandingOrdersBloc
    extends Bloc<StandingOrdersEvent, StandingOrdersState> {
  final _uuid = const Uuid();

  StandingOrdersBloc() : super(const StandingOrdersState()) {
    on<StandingOrdersEvent>((event, emit) {
      event.map(
        addNewOrderRequested: (event) => _handleAddNewOrder(event, emit),
        orderNameChanged: (event) => _handleOrderNameChanged(event, emit),
        orderAmountChanged: (event) => _handleOrderAmountChanged(event, emit),
        orderDeleted: (event) => _handleOrderDeleted(event, emit),
        orderConfirmed: (event) => _handleOrderConfirmed(event, emit),
      );
    });
  }

  void _handleAddNewOrder(
    AddNewOrderRequested event,
    Emitter<StandingOrdersState> emit,
  ) {
    final newOrder = StandingOrder(
      id: _uuid.v4(),
      name: '',
      amount: 0,
    );

    emit(state.copyWith(
      orders: [...state.orders, newOrder],
      isAddingNew: true,
    ));
  }

  void _handleOrderNameChanged(
    OrderNameChanged event,
    Emitter<StandingOrdersState> emit,
  ) {
    final updatedOrders = state.orders.map((order) {
      if (order.id == event.orderId) {
        return order.copyWith(name: _sanitizeName(event.name));
      }
      return order;
    }).toList();

    emit(state.copyWith(orders: updatedOrders));
  }

  void _handleOrderAmountChanged(
    OrderAmountChanged event,
    Emitter<StandingOrdersState> emit,
  ) {
    final amount = double.tryParse(event.amount) ?? 0;
    final updatedOrders = state.orders.map((order) {
      if (order.id == event.orderId) {
        return order.copyWith(amount: amount);
      }
      return order;
    }).toList();

    emit(state.copyWith(orders: updatedOrders));
  }

  void _handleOrderDeleted(
    OrderDeleted event,
    Emitter<StandingOrdersState> emit,
  ) {
    final updatedOrders =
        state.orders.where((order) => order.id != event.orderId).toList();

    emit(state.copyWith(orders: updatedOrders));
  }

  void _handleOrderConfirmed(
    OrderConfirmed event,
    Emitter<StandingOrdersState> emit,
  ) {
    emit(state.copyWith(isAddingNew: false));
  }

  String _sanitizeName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-.,]'), '')
        .trim()
        .substring(0, name.length > 50 ? 50 : name.length);
  }
}
