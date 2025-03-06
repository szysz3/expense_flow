import 'package:domain/use_case/create_receipt_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/localization.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/add_item/bloc/add_item_bloc.dart';
import 'package:presentation/screen/add_item/bloc/add_item_event.dart';
import 'package:presentation/screen/add_item/bloc/add_item_state.dart';
import 'package:presentation/screen/add_item/widget/category_button.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/loading_indicator_widget.dart';
import '../../di/di.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => AddItemBloc(
            getIt<CreateReceiptUseCase>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          ),
      child: const AddItemView());
}

class AddItemView extends StatefulWidget {
  const AddItemView({super.key});

  @override
  State<AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AddItemBloc, AddItemState>(
        listener: (context, state) {
          if (state == const AddItemState()) {
            _descriptionController.clear();
            _quantityController.clear();
            _priceController.clear();
          }

          if (state.error != null) {
            ErrorUtils.showErrorSnackBar(context, state.error!);
            context.read<AddItemBloc>().add(const AddItemEvent.clearError());
          }
        },
        builder: (context, state) => GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: double.infinity),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCategorySection(state),
                                const SizedBox(height: 12),
                                _buildDescriptionSection(context),
                                const SizedBox(height: 12),
                                _buildQuantityAndPriceSection(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Center(
                        child: AnimatedSquareButton.square(
                          isProcessing: !state.isValid || state.isSubmitting,
                          onPressed: () => context.read<AddItemBloc>().add(
                                const AddItemEvent.submitted(),
                              ),
                          icon: SvgPicture.asset(
                            'packages/presentation/assets/icon_add.svg',
                            width: 40,
                            height: 40,
                          ),
                          size: 64,
                          iconSize: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Loading or success overlay
              if (state.isSubmitting || state.isSuccess)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: LoadingIndicatorWidget(
                      isSuccess: state.isSuccess,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildDescriptionSection(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.4),
        ),
        child: TextField(
          controller: _descriptionController,
          onChanged: (value) => context.read<AddItemBloc>().add(
                AddItemEvent.descriptionChanged(value),
              ),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).description,
            hintText: AppLocalizations.of(context).enterItemDescription,
            border: InputBorder.none,
          ),
        ),
      );

  Widget _buildQuantityAndPriceSection(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                onChanged: (value) => context.read<AddItemBloc>().add(
                      AddItemEvent.quantityChanged(value),
                    ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).quantity,
                  hintText: AppLocalizations.of(context).enterQuantity,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _priceController,
                onChanged: (value) {
                  final locale = Localizations.localeOf(context);
                  final format = NumberFormat.decimalPattern(locale.toString());
                  final decimalSeparator = format.symbols.DECIMAL_SEP;
                  String normalizedValue = value;
                  if (decimalSeparator != '.') {
                    normalizedValue = value.replaceAll(decimalSeparator, '.');
                  }

                  context.read<AddItemBloc>().add(
                        AddItemEvent.priceChanged(normalizedValue),
                      );
                },
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).totalPrice,
                  hintText: AppLocalizations.of(context).enterPrice,
                  border: InputBorder.none,
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final locale = Localizations.localeOf(context);
                    final format =
                        NumberFormat.decimalPattern(locale.toString());
                    final decimalSeparator = format.symbols.DECIMAL_SEP;
                    final regExp = RegExp('[0-9.,]');

                    String filtered = newValue.text
                        .split('')
                        .where((char) => regExp.hasMatch(char))
                        .join();

                    if (filtered.contains('.') || filtered.contains(',')) {
                      filtered = filtered
                          .replaceAll(',', decimalSeparator)
                          .replaceAll('.', decimalSeparator);

                      final parts = filtered.split(decimalSeparator);
                      if (parts.length > 2) {
                        filtered = parts[0] +
                            decimalSeparator +
                            parts.sublist(1).join('');
                      }
                    }

                    return newValue.copyWith(
                      text: filtered,
                      selection:
                          TextSelection.collapsed(offset: filtered.length),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildCategorySection(AddItemState state) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).category,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
              children: ItemCategory.values.map((category) {
                final isSelected = state.selectedCategory == category;
                return CategoryButton(
                  icon:
                      'packages/presentation/assets/icon_${category.name}.svg',
                  label: _getCategoryLabel(category),
                  isSelected: isSelected,
                  onPressed: () => context.read<AddItemBloc>().add(
                        AddItemEvent.categorySelected(category),
                      ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  String _getCategoryLabel(ItemCategory category) {
    switch (category) {
      case ItemCategory.groceries:
        return AppLocalizations.of(context).groceries;
      case ItemCategory.alcoholic_beverages:
        return AppLocalizations.of(context).alcohol;
      case ItemCategory.personal_care:
        return AppLocalizations.of(context).personalCare;
      case ItemCategory.household:
        return AppLocalizations.of(context).household;
      case ItemCategory.clothing:
        return AppLocalizations.of(context).clothing;
      case ItemCategory.entertainment:
        return AppLocalizations.of(context).entertainment;
      case ItemCategory.transportation:
        return AppLocalizations.of(context).transportation;
      case ItemCategory.pet:
        return AppLocalizations.of(context).pet;
      case ItemCategory.other:
        return AppLocalizations.of(context).other;
      case ItemCategory.standing_orders:
        return AppLocalizations.of(context).standingOrders;
    }
  }
}
