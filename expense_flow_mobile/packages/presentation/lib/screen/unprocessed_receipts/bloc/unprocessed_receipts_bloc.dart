import 'dart:async';

import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'unprocessed_receipts_event.dart';
import 'unprocessed_receipts_state.dart';

class UnprocessedReceiptsBloc
    extends Bloc<UnprocessedReceiptsEvent, UnprocessedReceiptsState> {
  final ReceiptRepository _repository;

  UnprocessedReceiptsBloc({
    required ReceiptRepository repository,
  })  : _repository = repository,
        super(const UnprocessedReceiptsState()) {
    on<InitEvent>(_handleInit);
    on<RefreshEvent>(_handleRefresh);
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<UnprocessedReceiptsState> emit,
  ) async {
    await _loadReceipts(emit);
  }

  Future<void> _handleRefresh(
    RefreshEvent event,
    Emitter<UnprocessedReceiptsState> emit,
  ) async {
    await _loadReceipts(emit);
  }

  Future<void> _loadReceipts(Emitter<UnprocessedReceiptsState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));

      final result = await _repository.getUnprocessedReceipts();

      result.fold(
        (failure) {
          emit(state.copyWith(
            isLoading: false,
            error: failure.message,
          ));
        },
        (response) {
          emit(state.copyWith(
            receipts: response.receipts,
            isLoading: false,
            error: null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> refresh() async {
    add(const UnprocessedReceiptsEvent.refresh());
    return _refreshCompleter?.future;
  }

  Completer<void>? _refreshCompleter;
}
