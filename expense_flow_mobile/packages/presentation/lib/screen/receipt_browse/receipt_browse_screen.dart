import 'package:domain/model/receipt.dart';
import 'package:domain/use_case/get_receipts_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';
import '../receipt_details/receipt_details_screen.dart';
import 'bloc/receipt_browse_bloc.dart';
import 'bloc/receipt_browse_event.dart';
import 'bloc/receipt_browse_state.dart';
import 'widget/receipt_header_widget.dart';

class ReceiptBrowseScreen extends StatelessWidget {
  const ReceiptBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => ReceiptBrowseBloc(
            getIt<Logger>(),
            getIt<LocalizationService>(),
            getIt<GetReceiptsUseCase>(),
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
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: ReceiptBrowseView(),
        ),
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

        if (state.isDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).receiptDeleted),
              backgroundColor: Colors.green,
            ),
          );
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

        return _buildReceiptsList(context, state);
      },
    );
  }

  Widget _buildReceiptsList(BuildContext context, ReceiptBrowseState state) {
    return RefreshIndicator(
      onRefresh: () => context.read<ReceiptBrowseBloc>().refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent * 0.8 &&
              !state.isLoadingMore &&
              state.hasMoreReceipts) {
            context
                .read<ReceiptBrowseBloc>()
                .add(const ReceiptBrowseEvent.loadMore());
          }
          return false;
        },
        child: ListView.builder(
          itemCount: state.receipts.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.receipts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final receipt = state.receipts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ReceiptHeaderWidget(
                receipt: receipt,
                onTap: () => _navigateToReceiptDetail(context, receipt),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToReceiptDetail(BuildContext context, Receipt receipt) {
    ReceiptDetailScreen.show(context, receipt);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'packages/presentation/assets/icon_scan.svg',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).appBarBrowseReceiptsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).noReceiptsFound,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<ReceiptBrowseBloc>().add(
                    const ReceiptBrowseEvent.refresh(),
                  );
            },
            child: Text(AppLocalizations.of(context).refresh),
          ),
        ],
      ),
    );
  }
}
