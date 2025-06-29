import 'dart:async';

import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import 'receipt_filtering_event.dart';
import 'receipt_filtering_state.dart';

class ReceiptFilteringBloc
    extends Bloc<ReceiptFilteringEvent, ReceiptFilteringState> {
  final ReceiptRepository _repository;
  final Logger _errorLogger;
  final LocalizationService _localizationService;

  ReceiptFilteringBloc(
      this._repository, this._errorLogger, this._localizationService)
      : super(const ReceiptFilteringState()) {
    on<InitEvent>(_handleInit);
  }

  Future<void> _handleInit(
    InitEvent event,
    Emitter<ReceiptFilteringState> emit,
  ) async {}

  Future<void> refresh() async {
    add(const ReceiptFilteringEvent.refresh());
    return _refreshCompleter?.future;
  }

  Completer<void>? _refreshCompleter;
}
