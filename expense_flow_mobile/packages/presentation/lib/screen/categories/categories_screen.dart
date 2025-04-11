import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:domain/use_case/get_daily_expenses_use_case.dart';
import 'package:domain/use_case/settings/get_savings_settings_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';
import '../../theme/expense_flow_colors.dart';
import '../summary/widget/speed_dial/speed_dial_menu.dart';
import '../summary/widget/speed_dial/speed_dial_menu_data.dart';
import 'bloc/categories_bloc.dart';
import 'bloc/categories_events.dart';
import 'bloc/categories_state.dart';
import 'models/category_display_type.dart';
import 'widget/category_list_item.dart';
import 'widget/savings_bar_chart.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => CategoriesBloc(
            getIt<GetCategoriesUseCase>(),
            getIt<GetSavingsSettingsUseCase>(),
            getIt<GetDailyExpensesUseCase>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const CategoriesEvent.init()),
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'packages/presentation/assets/background_categories.svg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          CategoriesScreenView(),
        ],
      ));
}

class CategoriesScreenView extends StatelessWidget {
  const CategoriesScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state.error != null && state.categories.isNotEmpty) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.categories.isEmpty) {
          return ErrorDisplayWidget(
            error: state.error!,
            isFullScreen: true,
          );
        }

        if (state.categories.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, CategoriesState state) {
    final colorScheme = Theme.of(context).colorScheme;
    var toSpend = ((state.income - state.savingsAmount) - state.totalExpenses);
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 16.0, bottom: 112),
          child: _buildDisplayContent(context, state),
        ),
        if (state.displayType == CategoryDisplayType.list)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shadow part
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                ),
                // Border part
                Container(
                  height: 112,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withAlpha(50),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).balance,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          toSpend.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: toSpend < 0
                                ? ExpenseFlowColors.chartMutedRed
                                : ExpenseFlowColors.chartMutedGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Positioned(
          right: 24,
          bottom: 24,
          child: SpeedDialMenu(
            options: [
              SpeedDialMenuData(
                label: AppLocalizations.of(context).savingsChart,
                svgPath: 'packages/presentation/assets/icon_bar_chart.svg',
                onPressed: () {
                  context.read<CategoriesBloc>().add(
                        const CategoriesEvent.displaySavingsChart(),
                      );
                },
              ),
              SpeedDialMenuData(
                label: AppLocalizations.of(context).categories,
                svgPath: 'packages/presentation/assets/icon_categories.svg',
                onPressed: () {
                  context.read<CategoriesBloc>().add(
                        const CategoriesEvent.displayList(),
                      );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayContent(BuildContext context, CategoriesState state) {
    switch (state.displayType) {
      case CategoryDisplayType.savingsChart:
        return _buildDailyExpenses(context, state);
      case CategoryDisplayType.list:
        return _buildCategoryList(context, state);
    }
  }

  Widget _buildDailyExpenses(BuildContext context, CategoriesState state) {
    if (state.dailyExpenses.isEmpty && state.isLoadingDailyExpenses) {
      return const Center(child: CircularProgressIndicator());
    }

    return SavingsBarChart(
      dailyExpenses: state.dailyExpenses,
      income: state.income,
      savingsAmount: state.savingsAmount,
      cumulativeExpenses: state.cumulativeExpenses,
      totalExpenses: state.totalExpenses,
    );
  }

  Widget _buildCategoryList(BuildContext context, CategoriesState state) {
    return RefreshIndicator(
      onRefresh: () => context.read<CategoriesBloc>().refresh(),
      child: ListView.builder(
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final category = state.categories[index];
          return CategoryListItem(
            category: category,
            onToggle: () => context.read<CategoriesBloc>().add(
                  CategoriesEvent.toggleCategory(category.id),
                ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noCategories,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).addExpensesToSeeCategories,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<CategoriesBloc>().add(const CategoriesEvent.init());
            },
            child: Text(AppLocalizations.of(context).refresh),
          ),
        ],
      ),
    );
  }
}
