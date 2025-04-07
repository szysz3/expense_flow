import 'dart:async';

import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:domain/use_case/settings/get_savings_settings_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/app_error.dart';
import '../models/category.dart';
import '../models/category_display_type.dart';
import '../models/category_item.dart';
import 'categories_events.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetSavingsSettingsUseCase _getSavingsSettingsUseCase;
  final Logger _errorLogger;
  final LocalizationService _localizationService;

  CategoriesBloc(
    this._getCategoriesUseCase,
    this._getSavingsSettingsUseCase,
    this._errorLogger,
    this._localizationService,
  ) : super(const CategoriesState()) {
    on<InitEvent>(_handleInit);
    on<ToggleCategoryEvent>(_handleToggleCategory);
    on<DisplayListEvent>(_handleDisplayList);
    on<DisplaySavingsChartEvent>(_handleDisplaySavingsChart);
  }

  Completer<void>? _refreshCompleter;

  Future<void> refresh() async {
    add(const CategoriesEvent.init());
    return _refreshCompleter?.future;
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      _refreshCompleter = Completer<void>();

      if (state.categories.isEmpty) {
        emit(state.copyWith(isLoading: true, error: null));
      } else {
        emit(state.copyWith(error: null));
      }

      // Load savings settings
      final savingsResult = await _getSavingsSettingsUseCase(const NoParams());

      // Load categories
      final categoriesResult = await _getCategoriesUseCase(const NoParams());

      // Handle results
      savingsResult.fold(
        (failure) {
          _errorLogger.e('Failed to get savings settings', error: failure);
          // Continue with categories data, default savings values will be used
        },
        (savingsSettings) {
          emit(state.copyWith(
            savingsAmount: savingsSettings.savingsAmount,
            income: savingsSettings.income,
          ));
        },
      );

      categoriesResult.fold(
        (failure) {
          _errorLogger.e('Failed to get categories', error: failure);

          emit(state.copyWith(
            isLoading: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(const CategoriesEvent.init()),
              localizationService: _localizationService,
            ),
          ));
          _refreshCompleter?.complete();
        },
        (categories) {
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
                        count: item.count,
                      ))
                  .toList(),
            );
          }).toList();

          emit(state.copyWith(
            categories: presentationCategories,
            isLoading: false,
            error: null,
          ));
          _refreshCompleter?.complete();
        },
      );
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in CategoriesBloc.handleInit',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(e,
            onRetry: () => add(const CategoriesEvent.init()),
            localizationService: _localizationService),
      ));
      _refreshCompleter?.complete();
    }
  }

  void _handleToggleCategory(
    ToggleCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) {
    try {
      final updatedCategories = state.categories.map((category) {
        if (category.id == event.categoryId) {
          return category.copyWith(isExpanded: !category.isExpanded);
        }
        return category;
      }).toList();

      emit(state.copyWith(categories: updatedCategories));
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in CategoriesBloc.handleToggleCategory',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleDisplayList(
    DisplayListEvent event,
    Emitter<CategoriesState> emit,
  ) {
    emit(state.copyWith(displayType: CategoryDisplayType.list));
  }

  void _handleDisplaySavingsChart(
    DisplaySavingsChartEvent event,
    Emitter<CategoriesState> emit,
  ) {
    emit(state.copyWith(displayType: CategoryDisplayType.savingsChart));
  }
}
