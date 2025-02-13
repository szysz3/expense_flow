import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/standing_orders/bloc/standing_orders_bloc.dart';
import 'package:presentation/screen/standing_orders/bloc/standing_orders_state.dart';

class StandingOrdersScreen extends StatelessWidget {
  const StandingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => StandingOrdersBloc(StandingOrderState()),
        child: const StandingOrdersView(),
      );
}

class StandingOrdersView extends StatelessWidget {
  const StandingOrdersView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StandingOrdersBloc, BaseStandingOrdersState>(
          builder: (context, state) => switch (state) {
                _ => SizedBox.expand(
                    child: Center(child: Text('Standing orders screen')))
              });
}
