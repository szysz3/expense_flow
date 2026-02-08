import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:domain/use_case/get_daily_expenses_use_case.dart';
import 'package:domain/use_case/settings/settings_get_savings_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/utils/currency_text_formatter.dart';
import '../../core/widget/error_display_widget.dart';
import '../../core/widget/glass_container.dart';
import '../../core/widget/loading_indicator_widget.dart';
import '../../core/widget/app_spacing.dart';
import '../../core/widget/fading_edge.dart';
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
            getIt<SettingsGetSavingsUseCase>(),
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
          return const Center(child: LoadingIndicatorWidget(sizeFactor: 0.15));
        }

        if (state.error != null && state.categories.isEmpty) {
          return ErrorDisplayWidget(
            error: state.error!,
            isFullScreen: true,
          );
        }

        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, CategoriesState state) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    var toSpend = ((state.income - state.savingsAmount) - state.totalExpenses);
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 112),
          child: _buildDisplayContent(context, state),
        ),
        if (state.displayType == CategoryDisplayType.list)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: GlassContainer(
                      width: double.infinity,
                      height: 100,
                      blur: 20,
                      tintOpacity: 0.55,
                      borderRadius: BorderRadius.circular(24),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context).balance,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.formatCurrency(toSpend),
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
      return const Center(child: LoadingIndicatorWidget(sizeFactor: 0.15));
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
    return FadingEdge(
      child: RefreshIndicator(
        onRefresh: () => context.read<CategoriesBloc>().refresh(),
        child: ListView.separated(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          itemCount: state.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      ),
    );
  }
}
