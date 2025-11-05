import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';

import '../../../core/widget/input_widget.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import 'settings_date_button.dart';

class SettingsPeriodCard extends StatelessWidget {
  final SettingsPeriodForm period;
  final TextEditingController incomeController;
  final TextEditingController savingsController;
  final String Function(BuildContext, int, int) formatMonthYear;
  final String Function(String) parseNumberInput;
  final VoidCallback onStartDatePress;
  final VoidCallback onEndDatePress;

  const SettingsPeriodCard({
    super.key,
    required this.period,
    required this.incomeController,
    required this.savingsController,
    required this.formatMonthYear,
    required this.parseNumberInput,
    required this.onStartDatePress,
    required this.onEndDatePress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SettingsDateButton(
                  label: l10n.settingsStartDateLabel,
                  value: formatMonthYear(
                    context,
                    period.startMonth,
                    period.startYear,
                  ),
                  onPressed: onStartDatePress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SettingsDateButton(
                  label: l10n.settingsEndDateLabel,
                  value: period.isOpenEnded
                      ? l10n.settingsOpenEndedLabel
                      : formatMonthYear(
                          context,
                          period.endMonth ?? period.startMonth,
                          period.endYear ?? period.startYear,
                        ),
                  onPressed: period.isOpenEnded ? null : onEndDatePress,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                splashRadius: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                tooltip: l10n.delete,
                onPressed: () {
                  context
                      .read<SettingsBloc>()
                      .add(SettingsEvent.periodRemoved(period.id));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                l10n.settingsOpenEnded,
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Switch(
                value: period.isOpenEnded,
                onChanged: (_) {
                  context
                      .read<SettingsBloc>()
                      .add(SettingsEvent.toggleOpenEnded(period.id));
                },
                activeColor: theme.colorScheme.primary,
                activeTrackColor:
                    theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InputWidget(
                  controller: incomeController,
                  onDescriptionChanged: (value) {
                    context.read<SettingsBloc>().add(
                          SettingsEvent.periodIncomeChanged(
                            id: period.id,
                            income: parseNumberInput(value),
                          ),
                        );
                  },
                  labelText: l10n.income,
                  hintText: l10n.incomeHint,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputWidget(
                  controller: savingsController,
                  onDescriptionChanged: (value) {
                    context.read<SettingsBloc>().add(
                          SettingsEvent.periodSavingsChanged(
                            id: period.id,
                            savings: parseNumberInput(value),
                          ),
                        );
                  },
                  labelText: l10n.savingsAmount,
                  hintText: l10n.savingsAmountHint,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
