import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/error_display_widget.dart';
import '../../core/widget/glass_container.dart';
import '../../core/widget/loading_indicator_widget.dart';
import '../../core/widget/staggered_slide_fade.dart';
import '../../core/widget/app_spacing.dart';
import '../../di/di.dart';
import '../unprocessed_receipts_details/unprocessed_receipt_detail_screen.dart';
import 'bloc/unprocessed_receipts_bloc.dart';
import 'bloc/unprocessed_receipts_event.dart';
import 'bloc/unprocessed_receipts_state.dart';
import 'widget/unprocessed_receipt_item.dart';

class UnprocessedReceiptsScreen extends StatelessWidget {
  const UnprocessedReceiptsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UnprocessedReceiptsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => UnprocessedReceiptsBloc(
            getIt<ReceiptRepository>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const UnprocessedReceiptsEvent.init()),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: GlassContainer(
          height: MediaQuery.of(context).size.height * 0.6,
          blur: 24,
          tintOpacity: 0.75,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Column(
            children: [
              _buildModalHeader(context),
              Expanded(
                child: Padding(
                  padding: AppSpacing.page,
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ));

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            width: 46,
            height: 6,
            blur: 10,
            tintOpacity: 0.4,
            borderRadius: BorderRadius.circular(10),
            padding: EdgeInsets.zero,
            child: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<UnprocessedReceiptsBloc, UnprocessedReceiptsState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appBarUnprocessedReceiptsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _buildReceiptsList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptsList(
      BuildContext context, UnprocessedReceiptsState state) {
    if (state.isLoading && state.receipts.isEmpty) {
      return const Center(child: LoadingIndicatorWidget(sizeFactor: 0.12));
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
          return StaggeredSlideFade(
            index: index,
            child: UnprocessedReceiptItem(
              receipt: receipt,
              onTap: () => _navigateToUnprocessedReceiptDetail(context, receipt),
            ),
          );
        },
      ),
    );
  }

  void _navigateToUnprocessedReceiptDetail(BuildContext context, receipt) {
    UnprocessedReceiptDetailScreen.show(context, receipt);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'packages/presentation/assets/icon_unprocessed.svg',
            width: 64,
            height: 64,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context).noUnprocessedReceipts,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).allReceiptsProcessed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSquareButton(
            isProcessing: false,
            onPressed: () {
              context.read<UnprocessedReceiptsBloc>().add(
                    const UnprocessedReceiptsEvent.refresh(),
                  );
            },
            width: 124.0,
            height: 52.0,
            iconSize: 20.0,
            borderColor: Theme.of(context).colorScheme.outline,
            backgroundColor: Theme.of(context).colorScheme.surface,
            icon: Text(
              AppLocalizations.of(context).refresh,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
    );
  }
}
