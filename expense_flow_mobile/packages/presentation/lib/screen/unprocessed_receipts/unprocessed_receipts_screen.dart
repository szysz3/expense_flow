import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';
import 'bloc/unprocessed_receipts_bloc.dart';
import 'bloc/unprocessed_receipts_event.dart';
import 'bloc/unprocessed_receipts_state.dart';
import 'widget/unprocessed_receipt_item.dart';

class UnprocessedReceiptsScreen extends StatelessWidget {
  const UnprocessedReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => UnprocessedReceiptsBloc(
          repository: getIt<ReceiptRepository>(),
          errorLogger: getIt<Logger>(),
        )..add(const UnprocessedReceiptsEvent.init()),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: UnprocessedReceiptsView(),
        ),
      );
}

class UnprocessedReceiptsView extends StatelessWidget {
  const UnprocessedReceiptsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UnprocessedReceiptsBloc, UnprocessedReceiptsState>(
      listener: (context, state) {
        if (state.error != null && state.receipts.isNotEmpty) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.receipts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.receipts.isEmpty) {
          return ErrorDisplayWidget(
            error: state.error!,
            isFullScreen: true,
          );
        }

        if (state.receipts.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => context.read<UnprocessedReceiptsBloc>().refresh(),
          child: ListView.separated(
            itemCount: state.receipts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final receipt = state.receipts[index];
              return UnprocessedReceiptItem(receipt: receipt);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Unprocessed Receipts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'All receipts have been processed',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Refresh data
              context.read<UnprocessedReceiptsBloc>().add(
                    const UnprocessedReceiptsEvent.refresh(),
                  );
            },
            child: const Text('Check Again'),
          ),
        ],
      ),
    );
  }
}
