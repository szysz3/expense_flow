import 'dart:async';

import 'package:domain/model/receipt_item.dart';
import 'package:domain/use_case/create_receipt_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_item_event.dart';
import 'add_item_state.dart';

class AddItemBloc extends Bloc<AddItemEvent, AddItemState> {
  final CreateReceiptUseCase _createReceiptUseCase;

  AddItemBloc(this._createReceiptUseCase) : super(const AddItemState()) {
    on<DescriptionChanged>(_handleDescriptionChanged);
    on<QuantityChanged>(_handleQuantityChanged);
    on<PriceChanged>(_handlePriceChanged);
    on<CategorySelected>(_handleCategorySelected);
    on<Submitted>(_handleSubmitted);
    on<Reset>(_handleReset);
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
    if (event.quantity.isEmpty) {
      emit(state.copyWith(quantity: 0));
      return;
    }

    final quantity = double.tryParse(event.quantity);

    if (quantity != null) {
      emit(state.copyWith(quantity: quantity));
    }
  }

  void _handlePriceChanged(
    PriceChanged event,
    Emitter<AddItemState> emit,
  ) {
    if (event.price.isEmpty) {
      emit(state.copyWith(totalPrice: 0));
      return;
    }

    final price = double.tryParse(event.price);
    if (price != null) {
      emit(state.copyWith(totalPrice: price));
    }
  }

  void _handleCategorySelected(
    CategorySelected event,
    Emitter<AddItemState> emit,
  ) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  void _handleReset(Reset event, Emitter<AddItemState> emit) {
    emit(const AddItemState());
  }

  Future<void> _handleSubmitted(
    Submitted event,
    Emitter<AddItemState> emit,
  ) async {
    if (!state.isValid) return;

    emit(state.copyWith(isSubmitting: true));

    final params = ReceiptItem(
      description: state.description,
      quantity: state.quantity,
      totalPrice: state.totalPrice,
      category: state.selectedCategory.name,
    );

    final result = await _createReceiptUseCase(params);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          error: failure.message,
        ));
      },
      (receipt) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
        add(Reset());
      },
    );
  }
}
