import '../../../core/widget/expandable_list_item/expandable_header_data.dart';
import 'month_summary.dart';

class SummaryItemHeaderData implements ExpandableHeaderData {
  final MonthSummary month;

  SummaryItemHeaderData(this.month);

  @override
  String get title => month.month;

  @override
  String? get iconPath => null;

  @override
  bool get isExpanded => month.isExpanded;

  @override
  double get totalAmount => month.totalAmount;

  @override
  String? get monthName {
    final parts = month.month.split(" ");
    return parts.isNotEmpty ? parts[0] : month.month;
  }

  @override
  String? get yearName {
    final parts = month.month.split(" ");
    return parts.length > 1 ? parts[1] : null;
  }

  @override
  double? get savingsAmount => 123.0;

  @override
  bool get useVerticalLayout => true;
}
