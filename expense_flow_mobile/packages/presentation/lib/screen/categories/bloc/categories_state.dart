import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:presentation/screen/categories/models/category.dart';
import 'package:presentation/screen/categories/models/category_display_type.dart';

import '../../../core/error/app_error.dart';

part 'categories_state.freezed.dart';

@freezed
class CategoriesState with _$CategoriesState {
  const factory CategoriesState({
    @Default([]) List<Category> categories,
    @Default(false) bool isLoading,
    @Default(0.0) double savingsAmount,
    @Default(0.0) double income,
    @Default(CategoryDisplayType.list) CategoryDisplayType displayType,
    AppError? error,
  }) = _CategoriesState;
}
