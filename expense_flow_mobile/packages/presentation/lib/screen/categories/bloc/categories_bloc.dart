import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/category.dart';
import '../models/category_item.dart';
import 'categories_events.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final GetCategoriesUseCase _getCategoriesUseCase;

  CategoriesBloc({
    required GetCategoriesUseCase getCategoriesUseCase,
  })  : _getCategoriesUseCase = getCategoriesUseCase,
        super(const CategoriesState()) {
    on<InitEvent>(_handleInit);
    on<ToggleCategoryEvent>(_handleToggleCategory);
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final result = await _getCategoriesUseCase(const NoParams());

      result.fold(
        (failure) {
          // Handle failure case - you might want to add an error state
          emit(state.copyWith(isLoading: false));
        },
        (categories) {
          // Convert CategoryWithItems to Category presentation model
          final presentationCategories = categories.map((categoryWithItems) {
            return Category(
              id: categoryWithItems.id,
              name: categoryWithItems.name,
              iconName: categoryWithItems.iconName,
              items: categoryWithItems.items
                  .map((item) => CategoryItem(
                        id: item.id,
                        name: item.name,
                        amount: item.amount,
                      ))
                  .toList(),
            );
          }).toList();

          emit(state.copyWith(
            categories: presentationCategories,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _handleToggleCategory(
    ToggleCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) {
    final updatedCategories = state.categories.map((category) {
      if (category.id == event.categoryId) {
        return category.copyWith(isExpanded: !category.isExpanded);
      }
      return category;
    }).toList();

    emit(state.copyWith(categories: updatedCategories));
  }
}
