import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:presentation/core/utils/currency_text_formatter.dart';
import 'package:presentation/core/widget/glass_container.dart';

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
  final List<Widget> Function(T data)? headerColumns;
  final Widget Function(I item)? itemContent;

  const ExpandableListItem({
    super.key,
    required this.headerData,
    required this.items,
    required this.onToggle,
    this.headerTrailing,
    this.itemLeading,
    this.itemTrailing,
    this.headerColumns,
    this.itemContent,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.itemPadding = const EdgeInsets.fromLTRB(32, 8, 16, 8),
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
    const radius = 14.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: widget.onToggle,
        child: GlassContainer(
          blur: 14,
          tintOpacity: 0.45,
          borderRadius: BorderRadius.circular(radius),
          padding: widget.headerPadding,
          child: SizedBox(
            height: 60,
            child: widget.headerData.useVerticalLayout
                ? _buildVerticalHeader()
                : _buildHorizontalHeader(),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalHeader() {
    final List<Widget> baseColumns = [
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ];

    final List<Widget> customColumns = widget.headerColumns != null
        ? widget.headerColumns!(widget.headerData)
        : [];

    final List<Widget> finalColumns = [
      if (widget.headerTrailing != null)
        widget.headerTrailing!(widget.headerData),
      RotationTransition(
        turns: _rotationAnimation,
        child: SvgPicture.asset(
          'packages/presentation/assets/icon_right_chevron.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
      ),
    ];

    return Row(
      children: [...baseColumns, ...customColumns, ...finalColumns],
    );
  }

  Widget _buildVerticalHeader() {
    final List<Widget> baseColumns = [
      if (widget.headerData.iconPath != null) ...[
        SvgPicture.asset(
          widget.headerData.iconPath!,
          width: 32,
          height: 32,
        ),
        const SizedBox(width: 16),
      ],
      Expanded(
        flex: 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.headerData.monthName ?? widget.headerData.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.headerData.yearName != null)
              Text(
                widget.headerData.yearName!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    ];

    final List<Widget> customColumns = widget.headerColumns != null
        ? widget.headerColumns!(widget.headerData)
        : [];

    final List<Widget> finalColumns = [
      if (widget.headerTrailing != null)
        widget.headerTrailing!(widget.headerData),
      RotationTransition(
        turns: _rotationAnimation,
        child: SvgPicture.asset(
          'packages/presentation/assets/icon_right_chevron.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
      ),
    ];

    return Row(
      children: [...baseColumns, ...customColumns, ...finalColumns],
    );
  }

  Widget _buildItemsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.items.length,
      itemBuilder: (context, index) => _buildItemRow(widget.items[index]),
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Divider(
          height: 1,
          color:
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildItemRow(I item) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    if (widget.itemContent != null) {
      return widget.itemContent!(item);
    }

    final textColor = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    return Padding(
      padding: widget.itemPadding,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            if (widget.itemLeading != null) widget.itemLeading!(item),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.name.toLowerCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                  item.count > 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ExpandableItemCountBadge(count: item.count))
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            if (widget.itemTrailing != null) widget.itemTrailing!(item),
            Text(
              currencyFormatter.formatCurrency(item.amount),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
