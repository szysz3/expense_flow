import 'package:domain/use_case/receipt/receipt_filter_use_case.dart';
import 'package:domain/use_case/receipt/receipt_get_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
import '../../core/widget/loading_indicator_widget.dart';
import '../../di/di.dart';
import 'bloc/receipt_browse_bloc.dart';
import 'bloc/receipt_browse_event.dart';
import 'bloc/receipt_browse_state.dart';
import 'widget/receipt_browse_content.dart';
import 'widget/receipt_browse_empty_states.dart';

class ReceiptBrowseScreen extends StatelessWidget {
  const ReceiptBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => ReceiptBrowseBloc(
            getIt<Logger>(),
            getIt<LocalizationService>(),
            getIt<ReceiptGetUseCase>(),
            getIt<ReceiptFilterUseCase>(),
          )..add(const ReceiptBrowseEvent.init()),
      child: Stack(children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'packages/presentation/assets/background_unprocessed.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const ReceiptBrowseView(),
      ]));
}

class ReceiptBrowseView extends StatelessWidget {
  const ReceiptBrowseView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceiptBrowseBloc, ReceiptBrowseState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        if (state.isLoading &&
            state.receipts.isEmpty &&
            state.filteredItems.isEmpty) {
          return const Center(child: LoadingIndicatorWidget(sizeFactor: 0.15));
        }

        if (state.error != null &&
            state.receipts.isEmpty &&
            state.filteredItems.isEmpty) {
          return ErrorDisplayWidget(
            error: state.error!,
            isFullScreen: true,
          );
        }

        if (!state.isFiltered && state.receipts.isEmpty) {
          return ReceiptBrowseEmptyState(state: state);
        }

        if (state.isFiltered &&
            state.filteredItems.isEmpty &&
            !state.isLoading) {
          return ReceiptBrowseEmptyFilteredState(state: state);
        }

        return ReceiptBrowseContent(state: state);
      },
    );
  }
}
