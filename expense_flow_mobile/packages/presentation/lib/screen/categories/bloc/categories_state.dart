import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:presentation/screen/categories/models/category.dart';

part 'categories_state.freezed.dart';

@freezed
class CategoriesState with _$CategoriesState {
  const factory CategoriesState({
    @Default([]) List<Category> categories,
    @Default(false) bool isLoading,
  }) = _CategoriesState;
}
