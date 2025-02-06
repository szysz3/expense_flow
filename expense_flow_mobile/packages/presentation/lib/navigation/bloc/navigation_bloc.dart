import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_event.dart';
import 'package:presentation/navigation/bloc/navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigateToIndex>(_onNavigateToIndex);
  }

  void _onNavigateToIndex(
      NavigateToIndex event, Emitter<NavigationState> emit) {
    emit(state.copyWith(currentIndex: event.index));
  }
}
