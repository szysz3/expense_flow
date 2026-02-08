import 'package:domain/use_case/get_autocomplete_suggestions_use_case.dart';
import 'package:domain/use_case/receipt/receipt_create_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/add_item/widget/description_autocomplete_widget.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/full_screen_loading_overlay.dart';
import '../../core/widget/app_spacing.dart';
import '../../di/di.dart';
import 'bloc/add_item_bloc.dart';
import 'bloc/add_item_event.dart';
import 'bloc/add_item_state.dart';
import 'widget/category_section.dart';
import 'widget/quantity_price_section.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => AddItemBloc(
            getIt<ReceiptCreateUseCase>(),
            getIt<GetAutocompleteSuggestionsUseCase>(),
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
  final _loadingOverlay = FullScreenLoadingOverlay();

  @override
  void dispose() {
    _loadingOverlay.dispose();
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

    if (state.isSubmitting || state.isSuccess) {
      _loadingOverlay.update(isSuccess: state.isSuccess);
      if (!_loadingOverlay.isShowing) {
        _loadingOverlay.show(context);
      }
    } else {
      _loadingOverlay.hide();
    }

    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
      context.read<AddItemBloc>().add(const AddItemEvent.clearError());
    }
  }

  Widget _buildContent(BuildContext context, AddItemState state) =>
      GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            children: [
              Expanded(
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
                        const SizedBox(height: AppSpacing.lg),
                        DescriptionAutocompleteWidget(
                          controller: _descriptionController,
                          onTextChanged: (value) {
                            context.read<AddItemBloc>().add(
                                  AddItemEvent.descriptionChanged(value),
                                );
                          },
                          labelText:
                              AppLocalizations.of(context).description,
                          hintText: AppLocalizations.of(context)
                              .enterItemDescription,
                          suggestions: state.suggestions,
                          isLoadingSuggestions: state.isLoadingSuggestions,
                          onSuggestionSelected: (suggestion) {
                            context.read<AddItemBloc>().add(
                                  const AddItemEvent.clearSuggestions(),
                                );

                            context.read<AddItemBloc>().add(
                                  AddItemEvent.descriptionChanged(
                                      suggestion),
                                );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
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
              _buildAddButton(state, context),
            ],
          ),
        ),
      );

  Widget _buildAddButton(AddItemState state, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
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
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            size: 64,
            iconSize: 40,
          ),
        ),
      );
}
