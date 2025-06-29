import 'package:flutter/material.dart';

class ReceiptFilteringDateRangeSection extends StatelessWidget {
  const ReceiptFilteringDateRangeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range', // TODO: Add to localization
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        const DateRangeFields(),
      ],
    );
  }
}

class DateRangeFields extends StatelessWidget {
  const DateRangeFields({super.key});

  @override
  Widget build(BuildContext context) {
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
                  label: 'From', // TODO: Add to localization
                  hint: 'Select start date', // TODO: Add to localization
                  onTap: () => _selectDate(context, isStartDate: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DateField(
                  label: 'To', // TODO: Add to localization
                  hint: 'Select end date', // TODO: Add to localization
                  onTap: () => _selectDate(context, isStartDate: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const QuickDateOptions(),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final now = DateTime.now();
    final initialDate = now;
    final firstDate = DateTime(now.year - 5);
    final lastDate = now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
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

    if (selectedDate != null) {
      // TODO: Add bloc event to update date
    }
  }
}

class DateField extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;

  const DateField({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDate = null; // TODO: Get from state

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
                        ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}' // TODO: Format properly
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
  const QuickDateOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final quickOptions = [
      'This Month', // TODO: Add to localization
      'Last Month', // TODO: Add to localization
      'Last 3 Months', // TODO: Add to localization
      'Last 6 Months', // TODO: Add to localization
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: quickOptions.map((option) {
          final isSelected = false; // TODO: Get from state

          return ActionChip(
            label: Text(
              option,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
            onPressed: () {
              // TODO: Add bloc event
            },
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
