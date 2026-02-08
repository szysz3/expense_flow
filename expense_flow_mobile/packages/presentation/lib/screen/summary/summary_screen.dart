import 'package:domain/use_case/calculate_total_savings_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:domain/use_case/settings/settings_get_month_savings_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/core/utils/currency_text_formatter.dart';
import 'package:presentation/core/widget/animated_square_button.dart';
import 'package:presentation/screen/summary/widget/chart/summary_bar_chart.dart';
import 'package:presentation/screen/summary/widget/chart/summary_pie_chart.dart';
import 'package:presentation/screen/summary/widget/speed_dial/speed_dial_menu.dart';
import 'package:presentation/screen/summary/widget/speed_dial/speed_dial_menu_data.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
import '../../core/widget/glass_container.dart';
import '../../core/widget/loading_indicator_widget.dart';
import '../../core/widget/app_spacing.dart';
import '../../core/widget/fading_edge.dart';
import '../../di/di.dart';
import 'bloc/summary_bloc.dart';
import 'bloc/summary_events.dart';
import 'bloc/summary_state.dart';
import 'model/summary_display_type.dart';
import 'widget/summary_item_widget.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => SummaryBloc(
            getIt<GetMonthsSummaryUseCase>(),
            getIt<SettingsGetMonthSavingsUseCase>(),
            getIt<CalculateTotalSavingsUseCase>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const SummaryEvent.init()),
      child: Stack(children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'packages/presentation/assets/background_summary.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SummaryScreenView(),
      ]));
}

class SummaryScreenView extends StatelessWidget {
  const SummaryScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SummaryBloc, SummaryState>(
      listener: (context, state) {
        if (state.error != null && state.months.isNotEmpty) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.months.isEmpty) {
          return const Center(child: LoadingIndicatorWidget(sizeFactor: 0.15));
        }

        if (state.error != null && state.months.isEmpty) {
          return ErrorDisplayWidget(
            error: state.error!,
            isFullScreen: true,
          );
        }

        if (state.months.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildMainContent(context, state);
      },
    );
  }

  Widget _buildMainContent(BuildContext context, SummaryState state) {
    final bottomPadding =
        state.displayType == SummaryDisplayType.list ? 112.0 : AppSpacing.lg;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: bottomPadding,
          ),
          child: _buildContent(context, state),
        ),
        if (state.displayType == SummaryDisplayType.list)
          _buildBottomSavingsPanel(context, state),
        _buildSpeedDialMenu(context),
      ],
    );
  }

  Widget _buildBottomSavingsPanel(BuildContext context, SummaryState state) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    return Align(
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
                      AppLocalizations.of(context).savingsTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.formatCurrency(state.totalSavings),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: ExpenseFlowColors.chartMutedPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialMenu(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: SpeedDialMenu(
        options: [
          SpeedDialMenuData(
            label: AppLocalizations.of(context).barChart,
            svgPath: 'packages/presentation/assets/icon_bar_chart.svg',
            onPressed: () {
              context.read<SummaryBloc>().add(
                    const SummaryEvent.displayBarChart(),
                  );
            },
          ),
          SpeedDialMenuData(
            label: AppLocalizations.of(context).pieChart,
            svgPath: 'packages/presentation/assets/icon_pie_chart.svg',
            onPressed: () {
              context.read<SummaryBloc>().add(
                    const SummaryEvent.displayPieChart(),
                  );
            },
          ),
          SpeedDialMenuData(
            label: AppLocalizations.of(context).summary,
            svgPath: 'packages/presentation/assets/icon_summary.svg',
            onPressed: () {
              context.read<SummaryBloc>().add(
                    const SummaryEvent.displayList(),
                  );
            },
          )
        ],
      ),
    );
  }
}

Widget _buildContent(BuildContext context, SummaryState state) {
  switch (state.displayType) {
    case SummaryDisplayType.barChart:
      return SummaryBarChart(months: state.months);
    case SummaryDisplayType.pieChart:
      return SummaryPieChart(months: state.months);
    case SummaryDisplayType.list:
      return FadingEdge(
        child: RefreshIndicator(
          onRefresh: () => context.read<SummaryBloc>().refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            itemCount: state.months.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final month = state.months[index];
              return SummaryItemWidget(
                month: month,
                onToggle: () => context.read<SummaryBloc>().add(
                      SummaryEvent.toggleMonth(month.id),
                    ),
              );
            },
          ),
        ),
      );
  }
}

Widget _buildEmptyState(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'packages/presentation/assets/icon_summary.svg',
          width: 64,
          height: 64,
        ),
                    const SizedBox(height: AppSpacing.md),
        Text(
          AppLocalizations.of(context).noMonthlyData,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context).addExpensesToSeeMonthly,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSquareButton(
          isProcessing: false,
          onPressed: () {
            context.read<SummaryBloc>().add(const SummaryEvent.init());
          },
          width: 124.0,
          height: 52.0,
          iconSize: 20.0,
          borderColor: Theme.of(context).colorScheme.outline,
          backgroundColor: Theme.of(context).colorScheme.surface,
          icon: Text(
            AppLocalizations.of(context).refresh,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        )
      ],
    ),
  );
}
