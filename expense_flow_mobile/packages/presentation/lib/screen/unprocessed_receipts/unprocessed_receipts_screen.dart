import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return BlocBuilder<UnprocessedReceiptsBloc, UnprocessedReceiptsState>(
      builder: (context, state) {
        if (state.isLoading && state.receipts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.receipts.isEmpty) {
          return Center(
            child: Text(
              'Error: ${state.error}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          );
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
}
