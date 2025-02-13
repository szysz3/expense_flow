import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/standing_orders/widget/square_icon_button.dart';
import 'package:presentation/screen/standing_orders/widget/standing_order_item.dart';
import 'bloc/standing_orders_bloc.dart';
import 'bloc/standing_orders_events.dart';
import 'bloc/standing_orders_state.dart';

class StandingOrdersScreen extends StatelessWidget {
  const StandingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => StandingOrdersBloc(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const StandingOrdersView(),
        ),
      );
}

class StandingOrdersView extends StatelessWidget {
  const StandingOrdersView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StandingOrdersBloc, StandingOrdersState>(
        builder: (context, state) => ListView.builder(
          itemCount: state.orders.length + 1,
          itemBuilder: (context, index) {
            if (index == state.orders.length) {
              final hasUnconfirmedOrders =
                  state.orders.any((order) => !order.isConfirmed);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 28),
                  ListTile(
                    leading: SquareIconButton(
                      isProcessing: hasUnconfirmedOrders,
                      onPressed: () => context.read<StandingOrdersBloc>().add(
                          const StandingOrdersEvent.addNewOrderRequested()),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              );
            }

            final order = state.orders[index];
            final isEditing = !order.isConfirmed;

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
      );
}
