import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:domain/use_case/settings/get_month_savings_settings_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/summary/widget/chart/summary_bar_chart.dart';
import 'package:presentation/screen/summary/widget/chart/summary_pie_chart.dart';
import 'package:presentation/screen/summary/widget/speed_dial/speed_dial_menu.dart';
import 'package:presentation/screen/summary/widget/speed_dial/speed_dial_menu_data.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/error_display_widget.dart';
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
            getIt<GetMonthSavingsSettingsUseCase>(),
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
          return const Center(child: CircularProgressIndicator());
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
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 16.0, bottom: 112),
          child: _buildContent(context, state),
        ),
        if (state.displayType == SummaryDisplayType.list)
          _buildBottomSavingsPanel(context, state),
        _buildSpeedDialMenu(context),
      ],
    );
  }

  Widget _buildBottomSavingsPanel(BuildContext context, SummaryState state) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(50),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Savings",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    state.totalSavings.toStringAsFixed(2),
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: ExpenseFlowColors.chartMutedPurple),
                  ),
                ],
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
      return RefreshIndicator(
        onRefresh: () => context.read<SummaryBloc>().refresh(),
        child: ListView.builder(
          itemCount: state.months.length,
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
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).noMonthlyData,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).addExpensesToSeeMonthly,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 24),
        AnimatedSquareButton(
          isProcessing: false,
          onPressed: () {
            context.read<SummaryBloc>().add(const SummaryEvent.init());
          },
          width: 100.0,
          height: 52.0,
          iconSize: 20.0,
          borderColor: Colors.white,
          backgroundColor: Colors.black,
          icon: Text(
            AppLocalizations.of(context).refresh,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        )
      ],
    ),
  );
}
