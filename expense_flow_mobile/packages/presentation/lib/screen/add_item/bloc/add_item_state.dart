// add_item/bloc/add_item_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_item_state.freezed.dart';

enum ItemCategory {
  groceries,
  alcoholic_beverages,
  personal_care,
  household,
  clothing,
  entertainment,
  transportation,
  pet,
  other,
  standing_orders
}

@freezed
class AddItemState with _$AddItemState {
  const factory AddItemState({
    @Default('') String description,
    @Default(1.0) double quantity,
    @Default(0.0) double totalPrice,
    @Default(ItemCategory.groceries) ItemCategory selectedCategory,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? error,
  }) = _AddItemState;

  const AddItemState._();

  bool get isValid => description.isNotEmpty && totalPrice > 0;
}
