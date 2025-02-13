import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/standing_orders/widget/standing_order_item.dart';
import 'bloc/standing_orders_bloc.dart';
import 'bloc/standing_orders_events.dart';
import 'bloc/standing_orders_state.dart';

class StandingOrdersScreen extends StatelessWidget {
  const StandingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => StandingOrdersBloc(),
        child: const StandingOrdersView(),
      );
}

class StandingOrdersView extends StatelessWidget {
  const StandingOrdersView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StandingOrdersBloc, StandingOrdersState>(
        builder: (context, state) => Scaffold(
          body: ListView.builder(
            itemCount: state.orders.length + 1,
            itemBuilder: (context, index) {
              if (index == state.orders.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => context
                        .read<StandingOrdersBloc>()
                        .add(const StandingOrdersEvent.addNewOrderRequested()),
                    child: const Text('Add Standing Order'),
                  ),
                );
              }

              final order = state.orders[index];
              final isEditing =
                  state.isAddingNew && index == state.orders.length - 1;

              return StandingOrderItem(
                orderId: order.id,
                name: order.name,
                amount: order.amount,
                isEditing: isEditing,
                onNameChanged: isEditing
                    ? (value) => context.read<StandingOrdersBloc>().add(
                          StandingOrdersEvent.orderNameChanged(
                            orderId: order.id,
                            name: value,
                          ),
                        )
                    : null,
                onAmountChanged: isEditing
                    ? (value) => context.read<StandingOrdersBloc>().add(
                          StandingOrdersEvent.orderAmountChanged(
                            orderId: order.id,
                            amount: value,
                          ),
                        )
                    : null,
                onConfirmed: isEditing
                    ? () => context.read<StandingOrdersBloc>().add(
                          StandingOrdersEvent.orderConfirmed(
                            orderId: order.id,
                          ),
                        )
                    : null,
                onDelete: () => context.read<StandingOrdersBloc>().add(
                      StandingOrdersEvent.orderDeleted(
                        orderId: order.id,
                      ),
                    ),
              );
            },
          ),
        ),
      );
}
