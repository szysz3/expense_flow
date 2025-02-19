import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_item_event.dart';
import 'add_item_state.dart';

class AddItemBloc extends Bloc<AddItemEvent, AddItemState> {
  AddItemBloc() : super(const AddItemState()) {
    on<DescriptionChanged>(_handleDescriptionChanged);
    on<QuantityChanged>(_handleQuantityChanged);
    on<PriceChanged>(_handlePriceChanged);
    on<CategorySelected>(_handleCategorySelected);
    on<Submitted>(_handleSubmitted);
  }

  void _handleDescriptionChanged(
    DescriptionChanged event,
    Emitter<AddItemState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _handleQuantityChanged(
    QuantityChanged event,
    Emitter<AddItemState> emit,
  ) {
    final quantity = double.tryParse(event.quantity) ?? state.quantity;
    if (quantity > 0) {
      emit(state.copyWith(quantity: quantity));
    }
  }

  void _handlePriceChanged(
    PriceChanged event,
    Emitter<AddItemState> emit,
  ) {
    final price = double.tryParse(event.price) ?? state.totalPrice;
    emit(state.copyWith(totalPrice: price));
  }

  void _handleCategorySelected(
    CategorySelected event,
    Emitter<AddItemState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  Future<void> _handleSubmitted(
    Submitted event,
    Emitter<AddItemState> emit,
  ) async {
    if (!state.isValid) return;

    emit(state.copyWith(isSubmitting: true));

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!emit.isDone) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      ));
    }

    // Reset form after success
    await Future.delayed(const Duration(milliseconds: 2000));

    emit(const AddItemState());
  }
}
