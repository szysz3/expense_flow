import 'package:domain/use_case/create_receipt_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:presentation/screen/add_item/bloc/add_item_bloc.dart';
import 'package:presentation/screen/add_item/bloc/add_item_event.dart';
import 'package:presentation/screen/add_item/bloc/add_item_state.dart';
import 'package:presentation/screen/add_item/widget/category_button.dart';

import '../../common/widget/animated_square_button.dart';
import '../../common/widget/loading_indicator_widget.dart';
import '../../di/di.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => AddItemBloc(getIt<CreateReceiptUseCase>()),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: AddItemView(),
      ));
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
        },
        builder: (context, state) => Stack(
          children: [
            Column(
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
                            const SizedBox(height: 16),
                            _buildDescriptionSection(),
                            const SizedBox(height: 16),
                            _buildQuantityAndPriceSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Center(
                    child: AnimatedSquareButton(
                      isProcessing: !state.isValid,
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
      );

  Widget _buildDescriptionSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _descriptionController,
          onChanged: (value) => context.read<AddItemBloc>().add(
                AddItemEvent.descriptionChanged(value),
              ),
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter item description',
            border: InputBorder.none,
          ),
        ),
      );

  Widget _buildQuantityAndPriceSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
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
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter quantity',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _priceController,
                onChanged: (value) => context.read<AddItemBloc>().add(
                      AddItemEvent.priceChanged(value),
                    ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total Price',
                  hintText: 'Enter price',
                  prefixText: '\$',
                  border: InputBorder.none,
                ),
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
            const Text(
              'Category',
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
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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

  Widget _buildSubmitButton(BuildContext context, AddItemState state) =>
      Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: AnimatedSquareButton(
          isProcessing: !state.isValid,
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
      );

  String _getCategoryLabel(ItemCategory category) {
    switch (category) {
      case ItemCategory.groceries:
        return 'Groceries';
      case ItemCategory.alcoholic_beverages:
        return 'Alcohol';
      case ItemCategory.personal_care:
        return 'Personal Care';
      case ItemCategory.household:
        return 'Household';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.entertainment:
        return 'Entertainment';
      case ItemCategory.transportation:
        return 'Transport';
      case ItemCategory.pet:
        return 'Pet';
      case ItemCategory.other:
        return 'Other';
      case ItemCategory.standing_orders:
        return 'Standing Orders';
    }
  }
}
