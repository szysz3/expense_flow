import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/categories/service/mock_data_service.dart';
import 'categories_events.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesDataService _dataService;

  CategoriesBloc({
    CategoriesDataService? dataService,
  })  : _dataService = dataService ?? MockCategoriesDataService(),
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
      final categories = await _dataService.getCategories();
      emit(state.copyWith(
        categories: categories,
        isLoading: false,
      ));
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
