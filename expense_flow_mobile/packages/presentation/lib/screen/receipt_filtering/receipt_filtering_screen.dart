import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../di/di.dart';
import 'bloc/receipt_filtering_bloc.dart';
import 'bloc/receipt_filtering_event.dart';
import 'bloc/receipt_filtering_state.dart';

class ReceiptFilteringScreen extends StatelessWidget {
  const ReceiptFilteringScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReceiptFilteringScreen(),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => ReceiptFilteringBloc(
            getIt<ReceiptRepository>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const ReceiptFilteringEvent.init()),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              _buildModalHeader(context),
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

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<ReceiptFilteringBloc, ReceiptFilteringState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        return SizedBox(
          width: double.infinity, // Ensure full width
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterList(BuildContext context, ReceiptFilteringState state) {
    return SizedBox.shrink();
  }
}
