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
}
