import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:presentation/screen/categories/models/category.dart';

import '../../../core/error/app_error.dart';

part 'categories_state.freezed.dart';

@freezed
class CategoriesState with _$CategoriesState {
  const factory CategoriesState({
    @Default([]) List<Category> categories,
    @Default(false) bool isLoading,
    AppError? error,
  }) = _CategoriesState;
}
