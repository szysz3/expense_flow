import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/categories/bloc/categories_events.dart';
import 'package:presentation/screen/categories/bloc/categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc() : super(const CategoriesState()) {
    on<CategoriesEvent>((event, emit) {
      event.map(
        onSomething: (event) => _handleSomething(event, emit),
      );
    });
  }

  void _handleSomething(
    SomethingEvent event,
    Emitter<CategoriesState> emit,
  ) {}
}
