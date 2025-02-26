import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'expandable_header_data.dart';
import 'expandable_item_count_badge.dart';
import 'expandable_item_data.dart';

class ExpandableListItem<T extends ExpandableHeaderData,
    I extends ExpandableItemData> extends StatefulWidget {
  final T headerData;
  final List<I> items;
  final VoidCallback onToggle;
  final Widget Function(T data)? headerTrailing;
  final Widget Function(I item)? itemLeading;
  final Widget Function(I item)? itemTrailing;
  final EdgeInsets headerPadding;
  final EdgeInsets itemPadding;

  const ExpandableListItem({
    super.key,
    required this.headerData,
    required this.items,
    required this.onToggle,
    this.headerTrailing,
    this.itemLeading,
    this.itemTrailing,
    this.headerPadding = const EdgeInsets.only(left: 16),
    this.itemPadding = const EdgeInsets.fromLTRB(32, 0, 16, 0),
  });

  @override
  State<ExpandableListItem<T, I>> createState() =>
      _ExpandableListItemState<T, I>();
}

class _ExpandableListItemState<T extends ExpandableHeaderData,
        I extends ExpandableItemData> extends State<ExpandableListItem<T, I>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  String get _currencySymbol => NumberFormat.currency(
        locale: Localizations.localeOf(context).toString(),
      ).currencySymbol;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(ExpandableListItem<T, I> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.headerData.isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildItemsList(),
          crossFadeState: widget.headerData.isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: widget.onToggle,
      child: Container(
        height: 60,
        padding: widget.headerPadding,
        child: Row(
          children: [
            if (widget.headerData.iconPath != null) ...[
              SvgPicture.asset(
                widget.headerData.iconPath!,
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                widget.headerData.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.headerTrailing != null)
              widget.headerTrailing!(widget.headerData),
            Text(
              '$_currencySymbol ${widget.headerData.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            RotationTransition(
              turns: _rotationAnimation,
              child: SvgPicture.asset(
                'packages/presentation/assets/icon_right_chevron.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return _buildItemRow(item);
      },
    );
  }

  Widget _buildItemRow(I item) {
    final textColor = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    return Container(
      height: 50,
      padding: widget.itemPadding,
      child: Row(
        children: [
          if (widget.itemLeading != null) widget.itemLeading!(item),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: textColor),
                  ),
                ),
                item.count > 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ExpandableItemCountBadge(count: item.count))
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          if (widget.itemTrailing != null) widget.itemTrailing!(item),
          Text(
            '$_currencySymbol ${item.amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ],
      ),
    );
  }
}
