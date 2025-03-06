import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/summary/bloc/summary_bloc.dart';
import 'package:presentation/screen/summary/bloc/summary_events.dart';
import 'package:presentation/screen/summary/bloc/summary_state.dart';
import 'package:presentation/screen/summary/widget/summary_item_widget.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => SummaryBloc(
          getIt<GetMonthsSummaryUseCase>(),
          getIt<Logger>(),
          getIt<LocalizationService>(),
        )..add(const SummaryEvent.init()),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: SummaryScreenView(),
        ),
      );
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
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<SummaryBloc>().add(const SummaryEvent.init());
            },
            child: Text(AppLocalizations.of(context).refresh),
          ),
        ],
      ),
    );
  }
}
