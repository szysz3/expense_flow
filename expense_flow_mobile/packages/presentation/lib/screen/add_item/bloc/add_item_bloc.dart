import 'dart:async';

import 'package:domain/model/receipt_item.dart';
import 'package:domain/use_case/create_receipt_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/app_error.dart';
import 'add_item_event.dart';
import 'add_item_state.dart';

class AddItemBloc extends Bloc<AddItemEvent, AddItemState> {
  final CreateReceiptUseCase _createReceiptUseCase;
  final Logger _errorLogger;
  final LocalizationService _localizationService;

  AddItemBloc(
    this._createReceiptUseCase,
    this._errorLogger,
    this._localizationService,
  ) : super(const AddItemState()) {
    on<DescriptionChanged>(_handleDescriptionChanged);
    on<QuantityChanged>(_handleQuantityChanged);
    on<PriceChanged>(_handlePriceChanged);
    on<CategorySelected>(_handleCategorySelected);
    on<Submitted>(_handleSubmitted);
    on<Reset>(_handleReset);
    on<ClearError>(_handleClearError);
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
    try {
      if (event.quantity.isEmpty) {
        emit(state.copyWith(quantity: 0));
        return;
      }

      final quantity = double.tryParse(event.quantity);

      if (quantity != null) {
        emit(state.copyWith(quantity: quantity));
      }
    } catch (e) {
      _errorLogger.w('Error parsing quantity: ${event.quantity}', error: e);
    }
  }

  void _handlePriceChanged(
    PriceChanged event,
    Emitter<AddItemState> emit,
  ) {
    try {
      if (event.price.isEmpty) {
        emit(state.copyWith(totalPrice: 0));
        return;
      }

      final price = double.tryParse(event.price);
      if (price != null) {
        emit(state.copyWith(totalPrice: price));
      }
    } catch (e) {
      _errorLogger.w('Error parsing price: ${event.price}', error: e);
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

  void _handleClearError(ClearError event, Emitter<AddItemState> emit) {
    emit(state.copyWith(error: null));
  }

  Future<void> _handleSubmitted(
    Submitted event,
    Emitter<AddItemState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(
        error: AppError(
          message: _localizationService.localizations.invalidData,
          details: _localizationService.localizations.fillAllRequiredFields,
          isRetryable: false,
        ),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, error: null));

    try {
      final params = ReceiptItem(
        description: state.description,
        quantity: state.quantity,
        totalPrice: state.totalPrice,
        category: state.selectedCategory,
      );

      final result = await _createReceiptUseCase(params);

      result.fold(
        (failure) {
          _errorLogger.e(
            'Failed to create receipt item',
            error: failure,
          );

          emit(state.copyWith(
            isSubmitting: false,
            error: AppError.fromFailure(failure,
                localizationService: _localizationService),
          ));
        },
        (receipt) {
          _errorLogger.i('Receipt item created successfully: ${receipt.id}');

          emit(state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            error: null,
          ));

          Future.delayed(const Duration(seconds: 2), () {
            add(const AddItemEvent.reset());
          });
        },
      );
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception during item creation',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isSubmitting: false,
        error: AppError.fromException(e,
            localizationService: _localizationService),
      ));
    }
  }
}
