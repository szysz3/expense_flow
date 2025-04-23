import 'package:domain/model/category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'add_item_state.freezed.dart';

@freezed
class AddItemState with _$AddItemState {
  const factory AddItemState({
    @Default('') String description,
    @Default(1.0) double quantity,
    @Default(0.0) double totalPrice,
    @Default(Category.defaultCategory) String selectedCategory,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    @Default([]) List<String> suggestions,
    @Default(false) bool isLoadingSuggestions,
    AppError? error,
  }) = _AddItemState;

  const AddItemState._();

  bool get isValid => description.isNotEmpty && totalPrice > 0;
}
