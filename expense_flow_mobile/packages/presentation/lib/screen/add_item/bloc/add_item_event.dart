import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_item_event.freezed.dart';

@freezed
class AddItemEvent with _$AddItemEvent {
  const factory AddItemEvent.descriptionChanged(String description) =
      DescriptionChanged;

  const factory AddItemEvent.quantityChanged(String quantity) = QuantityChanged;

  const factory AddItemEvent.priceChanged(String price) = PriceChanged;

  const factory AddItemEvent.categorySelected(String category) =
      CategorySelected;

  const factory AddItemEvent.submitted() = Submitted;

  const factory AddItemEvent.reset() = Reset;

  const factory AddItemEvent.clearError() = ClearError;
}
