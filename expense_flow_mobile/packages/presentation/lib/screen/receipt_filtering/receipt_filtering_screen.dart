import 'package:domain/model/receipt_filter_params.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../di/di.dart';
import '../receipt_filtering/bloc/receipt_filtering_bloc.dart';
import '../receipt_filtering/bloc/receipt_filtering_event.dart';
import '../receipt_filtering/bloc/receipt_filtering_state.dart';
import '../receipt_filtering/widget/receipt_filtering_action_buttons.dart';
import '../receipt_filtering/widget/receipt_filtering_categories_section.dart';
import '../receipt_filtering/widget/receipt_filtering_date_range_section.dart';
import '../receipt_filtering/widget/receipt_filtering_modal_header.dart';
import '../receipt_filtering/widget/receipt_filtering_search_section.dart';

class ReceiptFilteringScreen extends StatelessWidget {
  final ReceiptFilterParams? initialParams;

  const ReceiptFilteringScreen({
    super.key,
    this.initialParams,
  });

  static Future<ReceiptFilterParams?> show(
    BuildContext context, {
    ReceiptFilterParams? initialParams,
  }) {
    return showModalBottomSheet<ReceiptFilterParams>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => ReceiptFilteringScreen(
        initialParams: initialParams,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => ReceiptFilteringBloc(
            getIt<ReceiptRepository>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(ReceiptFilteringEvent.init(initialParams: initialParams)),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              const ReceiptFilteringModalHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ));

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<ReceiptFilteringBloc, ReceiptFilteringState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Receipts', // TODO: Add to localization
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildFilterList(context, state),
              ),
              const ReceiptFilteringActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterList(BuildContext context, ReceiptFilteringState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReceiptFilteringCategoriesSection(),
          const SizedBox(height: 24),
          const ReceiptFilteringDateRangeSection(),
          const SizedBox(height: 24),
          const ReceiptFilteringSearchSection(),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom > 0 ? 200 : 0,
          ),
        ],
      ),
    );
  }
}
