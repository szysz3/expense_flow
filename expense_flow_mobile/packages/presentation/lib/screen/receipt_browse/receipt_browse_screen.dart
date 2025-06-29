import 'package:domain/model/receipt.dart';
import 'package:domain/use_case/receipt/receipt_get_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';
import '../receipt_details/receipt_details_screen.dart';
import '../receipt_filtering/receipt_filtering_screen.dart';
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
            getIt<ReceiptGetUseCase>(),
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

        if (state.isDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).receiptDeleted),
              backgroundColor: ExpenseFlowColors.chartMutedGreen,
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
          return _buildEmptyState(context, state);
        }

        return _buildMainContent(context, state);
      },
    );
  }

  Widget _buildMainContent(BuildContext context, ReceiptBrowseState state) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 16.0, bottom: 112),
          child: _buildReceiptsList(context, state),
        ),
        _buildBottomPanel(context, state),
        _buildSpeedDialMenu(context),
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context, ReceiptBrowseState state) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(50),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.only(left: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Empty for now - can be populated later
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialMenu(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: AnimatedSquareButton.square(
        isProcessing: false,
        onPressed: () {
          ReceiptFilteringScreen.show(context);
        },
        borderColor: Colors.white,
        backgroundColor: Colors.black,
        icon: SvgPicture.asset(
          'packages/presentation/assets/icon_search.svg',
          width: 40,
          height: 40,
        ),
        size: 64,
        iconSize: 40,
      ),
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

  Widget _buildEmptyState(BuildContext context, ReceiptBrowseState state) {
    return Stack(
      children: [
        Center(
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),
              AnimatedSquareButton(
                isProcessing: false,
                onPressed: () {
                  context.read<ReceiptBrowseBloc>().add(
                        const ReceiptBrowseEvent.refresh(),
                      );
                },
                width: 124.0,
                height: 52.0,
                iconSize: 20.0,
                borderColor: Colors.white,
                backgroundColor: Colors.black,
                icon: Text(
                  AppLocalizations.of(context).refresh,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),
        _buildBottomPanel(context, state),
        _buildSpeedDialMenu(context),
      ],
    );
  }
}
