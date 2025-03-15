import 'package:domain/use_case/create_receipt_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/localization.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/loading_indicator_widget.dart';
import '../../di/di.dart';
import 'bloc/add_item_bloc.dart';
import 'bloc/add_item_event.dart';
import 'bloc/add_item_state.dart';
import 'widget/category_section.dart';
import 'widget/description_section.dart';
import 'widget/quantity_price_section.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => AddItemBloc(
            getIt<CreateReceiptUseCase>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          ),
      child: Stack(children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'packages/presentation/assets/background_add_item.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const AddItemView(),
      ]));
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
        listener: _handleStateChanges,
        builder: _buildContent,
      );

  void _handleStateChanges(BuildContext context, AddItemState state) {
    if (state == const AddItemState()) {
      _descriptionController.clear();
      _quantityController.clear();
      _priceController.clear();
    }

    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
      context.read<AddItemBloc>().add(const AddItemEvent.clearError());
    }
  }

  Widget _buildContent(BuildContext context, AddItemState state) =>
      GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
                              CategorySection(
                                selectedCategory: state.selectedCategory,
                                onCategorySelected: (category) {
                                  context.read<AddItemBloc>().add(
                                        AddItemEvent.categorySelected(category),
                                      );
                                },
                              ),
                              const SizedBox(height: 12),
                              DescriptionSection(
                                controller: _descriptionController,
                                onDescriptionChanged: (value) {
                                  context.read<AddItemBloc>().add(
                                        AddItemEvent.descriptionChanged(value),
                                      );
                                },
                              ),
                              const SizedBox(height: 12),
                              QuantityPriceSection(
                                quantityController: _quantityController,
                                priceController: _priceController,
                                onQuantityChanged: (value) {
                                  context.read<AddItemBloc>().add(
                                        AddItemEvent.quantityChanged(value),
                                      );
                                },
                                onPriceChanged: (value) {
                                  context.read<AddItemBloc>().add(
                                        AddItemEvent.priceChanged(value),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildAddButton(state, context),
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
      );

  // Add button at the bottom
  Widget _buildAddButton(AddItemState state, BuildContext context) => Padding(
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
      );
}
