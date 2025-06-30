import 'dart:async';

import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_filter_params.dart';
import 'package:domain/use_case/receipt/receipt_filter_use_case.dart';
import 'package:domain/use_case/receipt/receipt_get_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'receipt_browse_event.dart';
import 'receipt_browse_state.dart';

class ReceiptBrowseBloc extends Bloc<ReceiptBrowseEvent, ReceiptBrowseState> {
  final Logger _logger;
  final LocalizationService _localizationService;
  final ReceiptGetUseCase _getReceiptsUseCase;
  final ReceiptFilterUseCase _filterReceiptsUseCase;

  int _currentPage = 1;
  static const int _pageSize = 10;
  Completer<void>? _refreshCompleter;
  Timer? _resetDeletedStateTimer;

  ReceiptBrowseBloc(
    this._logger,
    this._localizationService,
    this._getReceiptsUseCase,
    this._filterReceiptsUseCase,
  ) : super(const ReceiptBrowseState()) {
    on<InitEvent>(_onInit);
    on<RefreshEvent>(_onRefresh);
    on<LoadMoreEvent>(_onLoadMore);
    on<NotifyReceiptDeletedEvent>(_onNotifyReceiptDeleted);
    on<ResetDeletedStateEvent>(_onResetDeletedState);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<ClearFiltersEvent>(_onClearFilters);
  }

  void _onNotifyReceiptDeleted(
    NotifyReceiptDeletedEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) {
    if (state.isFiltered) {
      // If filtered, remove items from that receipt
      final updatedItems = state.filteredItems
          .where((item) => item.parentReceipt.id != event.receiptId)
          .toList();

      final totalAmount = updatedItems.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );

      emit(state.copyWith(
        filteredItems: updatedItems,
        filteredTotalAmount: totalAmount,
        isDeleted: true,
        deleteReceiptId: event.receiptId,
      ));
    } else {
      // Original logic for non-filtered view
      final updatedReceipts = state.receipts
          .where((receipt) => receipt.id != event.receiptId)
          .toList();

      emit(state.copyWith(
        receipts: updatedReceipts,
        totalCount: state.totalCount - 1,
        isDeleted: true,
        deleteReceiptId: event.receiptId,
      ));
    }

    _resetDeletedStateTimer?.cancel();
    _resetDeletedStateTimer = Timer(
      const Duration(seconds: 2),
      () => add(const ReceiptBrowseEvent.resetDeletedState()),
    );
  }

  void _onResetDeletedState(
    ResetDeletedStateEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) {
    emit(state.copyWith(
      isDeleted: false,
      deleteReceiptId: '',
    ));
  }

  Future<void> _onInit(
    InitEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    try {
      _refreshCompleter = Completer<void>();

      emit(state.copyWith(isLoading: true));
      _currentPage = 1;

      final result = await _getReceiptsUseCase(
        ReceiptGetParams(page: _currentPage, pageSize: _pageSize),
      );

      result.fold(
        (failure) {
          _logger.e(
            'Exception in ReceiptBrowseBloc.onInit',
            error: failure,
          );

          emit(state.copyWith(
            isLoading: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(const ReceiptBrowseEvent.init()),
              localizationService: _localizationService,
            ),
          ));
        },
        (receiptResponse) {
          emit(state.copyWith(
              isLoading: false,
              receipts: receiptResponse.receipts,
              hasMoreReceipts: receiptResponse.totalCount > _pageSize,
              totalCount: receiptResponse.totalCount,
              error: null));
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Exception in ReceiptBrowseBloc.onInit',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(const ReceiptBrowseEvent.init()),
          localizationService: _localizationService,
        ),
      ));
    } finally {
      _safeComplete(_refreshCompleter);
    }
  }

  void _safeComplete(Completer<void>? completer) {
    if (completer == null) return;

    try {
      completer.complete();
    } catch (e) {
      // Completer was already completed, ignore the error
    }
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    if (state.isFiltered) {
      // Re-apply filters
      add(ReceiptBrowseEvent.applyFilters(state.filterParams));
    } else {
      add(const ReceiptBrowseEvent.init());
    }
    return _refreshCompleter?.future;
  }

  Future<void> _onLoadMore(
    LoadMoreEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    if (state.isFiltered) {
      // No pagination for filtered view yet
      return;
    }

    if (state.isLoadingMore || !state.hasMoreReceipts) {
      return;
    }

    try {
      emit(state.copyWith(isLoadingMore: true));

      _currentPage++;

      final result = await _getReceiptsUseCase(
        ReceiptGetParams(page: _currentPage, pageSize: _pageSize),
      );

      result.fold(
        (failure) {
          _logger.e(
            'Failed to load more receipts',
            error: failure,
          );

          emit(state.copyWith(
            isLoadingMore: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () => add(const ReceiptBrowseEvent.loadMore()),
              localizationService: _localizationService,
            ),
          ));
        },
        (receiptResponse) {
          final List<Receipt> updatedReceipts = [
            ...state.receipts,
            ...receiptResponse.receipts,
          ];

          emit(state.copyWith(
            isLoadingMore: false,
            error: null,
            receipts: updatedReceipts,
            hasMoreReceipts:
                updatedReceipts.length < receiptResponse.totalCount,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Exception in ReceiptBrowseBloc.onLoadMore',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoadingMore: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(const ReceiptBrowseEvent.loadMore()),
          localizationService: _localizationService,
        ),
      ));
    }
  }

  Future<void> _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    try {
      _refreshCompleter = Completer<void>();

      // Add debug logging
      _logger.d('Applying filters: ${event.filterParams.categories}, '
          'startDate: ${event.filterParams.startDate}, '
          'endDate: ${event.filterParams.endDate}');

      emit(state.copyWith(isLoading: true));

      final result = await _filterReceiptsUseCase(event.filterParams);

      result.fold(
        (failure) {
          _logger.e(
            'Failed to apply filters',
            error: failure,
          );

          emit(state.copyWith(
            isLoading: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () =>
                  add(ReceiptBrowseEvent.applyFilters(event.filterParams)),
              localizationService: _localizationService,
            ),
          ));
        },
        (filterResponse) {
          // Add debug logging
          _logger.d('Filter response: ${filterResponse.items.length} items, '
              'total: ${filterResponse.totalAmount}');

          emit(state.copyWith(
            isLoading: false,
            isFiltered: true,
            filterParams: event.filterParams,
            filteredItems: filterResponse.items,
            filteredTotalAmount: filterResponse.totalAmount,
            error: null,
          ));
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Exception in ReceiptBrowseBloc.onApplyFilters',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isLoading: false,
        error: AppError.fromException(
          e,
          onRetry: () =>
              add(ReceiptBrowseEvent.applyFilters(event.filterParams)),
          localizationService: _localizationService,
        ),
      ));
    } finally {
      _safeComplete(_refreshCompleter);
    }
  }

  void _onClearFilters(
    ClearFiltersEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) {
    emit(state.copyWith(
      isFiltered: false,
      filterParams: const ReceiptFilterParams(),
      filteredItems: [],
      filteredTotalAmount: 0,
    ));

    add(const ReceiptBrowseEvent.init());
  }

  Future<void> refresh() async {
    add(const ReceiptBrowseEvent.refresh());
    return _refreshCompleter?.future;
  }

  @override
  Future<void> close() {
    _resetDeletedStateTimer?.cancel();
    return super.close();
  }
}
