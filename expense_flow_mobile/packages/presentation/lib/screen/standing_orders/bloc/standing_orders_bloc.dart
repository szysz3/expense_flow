import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/standing_orders/bloc/standing_orders_events.dart';
import 'package:presentation/screen/standing_orders/bloc/standing_orders_state.dart';

class StandingOrdersBloc
    extends Bloc<StandingOrdersEvent, BaseStandingOrdersState> {
  StandingOrdersBloc(super.initialState) {}
}
