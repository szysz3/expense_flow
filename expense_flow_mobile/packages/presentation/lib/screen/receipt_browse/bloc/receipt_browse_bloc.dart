import 'dart:async';

import 'package:domain/model/receipt.dart';
import 'package:domain/use_case/delete_use_case.dart';
import 'package:domain/use_case/get_receipts_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_error.dart';
import 'receipt_browse_event.dart';
import 'receipt_browse_state.dart';

class ReceiptBrowseBloc extends Bloc<ReceiptBrowseEvent, ReceiptBrowseState> {
  final Logger _logger;
  final LocalizationService _localizationService;
  final GetReceiptsUseCase _getReceiptsUseCase;
  final DeleteReceiptUseCase _deleteReceiptUseCase;

  int _currentPage = 1;
  static const int _pageSize = 10;
  Completer<void>? _refreshCompleter;

  ReceiptBrowseBloc(
    this._logger,
    this._localizationService,
    this._getReceiptsUseCase,
    this._deleteReceiptUseCase,
  ) : super(const ReceiptBrowseState()) {
    on<InitEvent>(_onInit);
    on<RefreshEvent>(_onRefresh);
    on<LoadMoreEvent>(_onLoadMore);
    on<DeleteReceiptEvent>(_onDeleteReceipt);
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
        GetReceiptsParams(page: _currentPage, pageSize: _pageSize),
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
          _refreshCompleter?.complete();
        },
        (receiptResponse) {
          emit(state.copyWith(
            isLoading: false,
            receipts: receiptResponse.receipts,
            hasMoreReceipts: receiptResponse.totalCount > _pageSize,
            totalCount: receiptResponse.totalCount,
          ));
          _refreshCompleter?.complete();
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
      _refreshCompleter?.complete();
    }
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    add(const ReceiptBrowseEvent.init());
    return _refreshCompleter?.future;
  }

  Future<void> _onLoadMore(
    LoadMoreEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMoreReceipts) {
      return;
    }

    try {
      emit(state.copyWith(isLoadingMore: true));

      _currentPage++;

      final result = await _getReceiptsUseCase(
        GetReceiptsParams(page: _currentPage, pageSize: _pageSize),
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

  Future<void> _onDeleteReceipt(
    DeleteReceiptEvent event,
    Emitter<ReceiptBrowseState> emit,
  ) async {
    emit(state.copyWith(
        isDeleting: true,
        isDeleted: false,
        deleteReceiptId: event.receiptId,
        error: null));

    try {
      final result = await _deleteReceiptUseCase(
        DeleteReceiptParams(id: event.receiptId),
      );

      result.fold(
        (failure) {
          _logger.e(
            'Failed to delete receipt',
            error: failure,
          );

          emit(state.copyWith(
            isDeleting: false,
            error: AppError.fromFailure(
              failure,
              onRetry: () =>
                  add(ReceiptBrowseEvent.deleteReceipt(event.receiptId)),
              localizationService: _localizationService,
            ),
          ));
        },
        (success) {
          final updatedReceipts = state.receipts
              .where((receipt) => receipt.id != event.receiptId)
              .toList();

          emit(state.copyWith(
            isDeleting: false,
            isDeleted: true,
            receipts: updatedReceipts,
            totalCount: state.totalCount - 1,
          ));

          Future.delayed(const Duration(seconds: 2), () {
            emit(state.copyWith(
              isDeleted: false,
              deleteReceiptId: '',
            ));
          });
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Exception in ReceiptBrowseBloc.onDeleteReceipt',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        isDeleting: false,
        error: AppError.fromException(
          e,
          onRetry: () => add(ReceiptBrowseEvent.deleteReceipt(event.receiptId)),
          localizationService: _localizationService,
        ),
      ));
    }
  }

  Future<void> refresh() async {
    add(const ReceiptBrowseEvent.refresh());
    return _refreshCompleter?.future;
  }
}
