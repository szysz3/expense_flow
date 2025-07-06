import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:localization/app_localizations.dart';

import '../bloc/receipt_filtering_bloc.dart';
import '../bloc/receipt_filtering_event.dart';
import '../bloc/receipt_filtering_state.dart';

class ReceiptFilteringDateRangeSection extends StatelessWidget {
  const ReceiptFilteringDateRangeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dateRangeLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<ReceiptFilteringBloc, ReceiptFilteringState>(
          builder: (context, state) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DateField(
                          label: l10n.fromDateLabel,
                          hint: l10n.selectStartDateHint,
                          selectedDate: state.filterParams.startDate,
                          onTap: () => _selectDate(context,
                              isStartDate: true,
                              currentDate: state.filterParams.startDate),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DateField(
                          label: l10n.toDateLabel,
                          hint: l10n.selectEndDateHint,
                          selectedDate: state.filterParams.endDate,
                          onTap: () => _selectDate(context,
                              isStartDate: false,
                              currentDate: state.filterParams.endDate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  QuickDateOptions(
                    selectedRange: state.selectedQuickRange,
                    onRangeSelected: (rangeType) {
                      context.read<ReceiptFilteringBloc>().add(
                            ReceiptFilteringEvent.setQuickDateRange(rangeType),
                          );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
    DateTime? currentDate,
  }) async {
    final now = DateTime.now();
    final initialDate = currentDate ?? now;
    final firstDate = DateTime(now.year - 5);
    final lastDate = now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.white,
                  onPrimary: Colors.black,
                  surface: Colors.grey[900],
                  onSurface: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && context.mounted) {
      if (isStartDate) {
        context.read<ReceiptFilteringBloc>().add(
              ReceiptFilteringEvent.setStartDate(selectedDate),
            );
      } else {
        context.read<ReceiptFilteringBloc>().add(
              ReceiptFilteringEvent.setEndDate(selectedDate),
            );
      }
    }
  }
}

class DateField extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? selectedDate;
  final VoidCallback onTap;

  static final _dateFormat = DateFormat('d/M/yyyy');

  const DateField({
    super.key,
    required this.label,
    required this.hint,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _dateFormat.format(selectedDate!)
                        : hint,
                    style: TextStyle(
                      color: selectedDate != null
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuickDateOptions extends StatelessWidget {
  final QuickDateRangeType? selectedRange;
  final Function(QuickDateRangeType) onRangeSelected;

  const QuickDateOptions({
    super.key,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final quickOptions = [
      (QuickDateRangeType.thisMonth, l10n.thisMonthOption),
      (QuickDateRangeType.lastMonth, l10n.lastMonthOption),
      (QuickDateRangeType.last3Months, l10n.last3MonthsOption),
      (QuickDateRangeType.last6Months, l10n.last6MonthsOption),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: quickOptions.map((option) {
          final isSelected = selectedRange == option.$1;

          return ActionChip(
            label: Text(
              option.$2,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
            onPressed: () => onRangeSelected(option.$1),
            backgroundColor: isSelected
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.transparent,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }).toList(),
      ),
    );
  }
}
