import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/summary/bloc/summary_bloc.dart';
import 'package:presentation/screen/summary/bloc/summary_events.dart';
import 'package:presentation/screen/summary/bloc/summary_state.dart';
import 'package:presentation/screen/summary/widget/summary_item_widget.dart';

import '../../di/di.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => SummaryBloc(
          getMonthsSummaryUseCase: getIt<GetMonthsSummaryUseCase>(),
        )..add(const SummaryEvent.init()),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const SummaryScreenView(),
        ),
      );
}

class SummaryScreenView extends StatelessWidget {
  const SummaryScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SummaryBloc, SummaryState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
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
        );
      },
    );
  }
}
