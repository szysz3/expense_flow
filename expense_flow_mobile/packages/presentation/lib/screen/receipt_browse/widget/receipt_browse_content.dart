import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/widget/animated_square_button.dart';
import '../../receipt_details/receipt_details_screen.dart';
import '../../receipt_filtering/receipt_filtering_screen.dart';
import '../../receipt_filtering/widget/filtered_receipt_item_widget.dart';
import '../bloc/receipt_browse_bloc.dart';
import '../bloc/receipt_browse_event.dart';
import '../bloc/receipt_browse_state.dart';
import '../widget/receipt_header_widget.dart';
import 'receipt_browse_bottom_panel.dart';

class ReceiptBrowseContent extends StatelessWidget {
  final ReceiptBrowseState state;

  const ReceiptBrowseContent({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 16.0, bottom: 112),
          child: state.isFiltered
              ? _buildFilteredItemsList(context)
              : _buildReceiptsList(context),
        ),
        ReceiptBrowseBottomPanel(state: state),
        _buildSearchButton(context),
      ],
    );
  }

  Widget _buildFilteredItemsList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<ReceiptBrowseBloc>().refresh(),
      child: ListView.builder(
        itemCount: state.filteredItems.length,
        itemBuilder: (context, index) {
          final item = state.filteredItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: FilteredReceiptItemWidget(item: item),
          );
        },
      ),
    );
  }

  Widget _buildReceiptsList(BuildContext context) {
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

  Widget _buildSearchButton(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: AnimatedSquareButton.square(
        isProcessing: false,
        onPressed: () => _onFilterPressed(context),
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

  Future<void> _onFilterPressed(BuildContext context) async {
    final filterParams = await ReceiptFilteringScreen.show(
      context,
      initialParams: state.filterParams,
    );

    if (filterParams != null && context.mounted) {
      if (filterParams.hasActiveFilters) {
        context.read<ReceiptBrowseBloc>().add(
              ReceiptBrowseEvent.applyFilters(filterParams),
            );
      } else {
        context.read<ReceiptBrowseBloc>().add(
              const ReceiptBrowseEvent.clearFilters(),
            );
      }
    }
  }
}
