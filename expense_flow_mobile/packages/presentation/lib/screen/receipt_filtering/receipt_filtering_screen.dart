import 'package:domain/model/category.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/core/utils/category_utils.dart';

import '../../core/error/error_utils.dart';
import '../../di/di.dart';
import 'bloc/receipt_filtering_bloc.dart';
import 'bloc/receipt_filtering_event.dart';
import 'bloc/receipt_filtering_state.dart';

class ReceiptFilteringScreen extends StatelessWidget {
  const ReceiptFilteringScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => const ReceiptFilteringScreen(),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => ReceiptFilteringBloc(
            getIt<ReceiptRepository>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const ReceiptFilteringEvent.init()),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              _buildModalHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ));

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<ReceiptFilteringBloc, ReceiptFilteringState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Receipts', // TODO: Add to localization
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildFilterList(context, state),
              ),
              // Wrap action buttons with keyboard padding
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterList(BuildContext context, ReceiptFilteringState state) {
    return SingleChildScrollView(
      // Add keyboard padding to scroll view
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoriesSection(context),
          const SizedBox(height: 24),
          _buildDateRangeSection(context),
          const SizedBox(height: 24),
          _buildSearchSection(context),
          // Add extra space at bottom when keyboard is visible
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom > 0 ? 200 : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search', // TODO: Add to localization
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.4),
          ),
          child: TextField(
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              labelText: 'Search receipts',
              // TODO: Add to localization
              hintText: 'Enter description or store name',
              // TODO: Add to localization
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  // TODO: Add bloc event to clear search
                },
              ),
            ),
            onChanged: (value) {
              // TODO: Add bloc event
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories', // TODO: Add to localization
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _buildCategoryChips(context),
      ],
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final selectedCategories = <String>{}; // TODO: Get from state

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Category.all.map((categoryId) {
        final isSelected = selectedCategories.contains(categoryId);
        final displayName = CategoryUtils.getDisplayName(categoryId, context);

        return FilterChip(
          selected: isSelected,
          label: Text(
            displayName,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          onSelected: (selected) {
            // TODO: Add bloc event
          },
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          selectedColor: Colors.white.withValues(alpha: 0.9),
          checkmarkColor: Colors.black,
          side: BorderSide(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
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
        _buildDateRangeFields(context),
      ],
    );
  }

  Widget _buildDateRangeFields(BuildContext context) {
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
                child: _buildDateField(
                  context,
                  label: 'From', // TODO: Add to localization
                  hint: 'Select start date', // TODO: Add to localization
                  onTap: () => _selectDate(context, isStartDate: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  context,
                  label: 'To', // TODO: Add to localization
                  hint: 'Select end date', // TODO: Add to localization
                  onTap: () => _selectDate(context, isStartDate: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuickDateOptions(context),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
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

  Widget _buildQuickDateOptions(BuildContext context) {
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Add clear filters logic
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Clear All', // TODO: Add to localization
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add apply filters logic
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Apply Filters', // TODO: Add to localization
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
