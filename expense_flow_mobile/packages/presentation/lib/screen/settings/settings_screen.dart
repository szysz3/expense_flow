import 'package:domain/use_case/settings/settings_get_all_periods_use_case.dart';
import 'package:domain/use_case/settings/settings_save_savings_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/scroll_boundary_indicator.dart';
import '../../di/di.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/settings_event.dart';
import 'bloc/settings_state.dart';
import 'widget/settings_modal_header.dart';
import 'widget/settings_period_card.dart';
import 'widget/settings_validation_banner.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => SettingsBloc(
          getIt<Logger>(),
          getIt<LocalizationService>(),
          getIt<SettingsGetAllPeriodsUseCase>(),
          getIt<SettingsSaveSavingsUseCase>(),
        )..add(const SettingsEvent.init()),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Column(
                children: [
                  SettingsModalHeader(),
                  Expanded(
                    child: SettingsScreenView(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class SettingsScreenView extends StatefulWidget {
  const SettingsScreenView({super.key});

  @override
  State<SettingsScreenView> createState() => _SettingsScreenViewState();
}

class _SettingsScreenViewState extends State<SettingsScreenView> {
  final _numberFormat = NumberFormat.decimalPattern();
  final Map<String, TextEditingController> _incomeControllers = {};
  final Map<String, TextEditingController> _savingsControllers = {};
  final Map<String, double> _incomeValues = {};
  final Map<String, double> _savingsValues = {};

  // Cached number format for parsing user input
  NumberFormat? _cachedParseFormat;
  String? _cachedLocale;

  @override
  void dispose() {
    for (final controller in _incomeControllers.values) {
      controller.dispose();
    }
    for (final controller in _savingsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
          return;
        }

        if (state.saveSuccessful) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        _syncControllersWithState(state);

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildSettingsContent(context, state);
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context, SettingsState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settings,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              if (state.validationMessage != null) ...[
                SettingsValidationBanner(message: state.validationMessage!),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _buildAddPeriodButton(context, l10n),
                  const SizedBox(width: 12),
                  const Spacer(),
                  AnimatedSquareButton(
                    width: 42,
                    height: 42,
                    isProcessing: state.isSaving,
                    onPressed: () {
                      context
                          .read<SettingsBloc>()
                          .add(const SettingsEvent.saveSettings());
                    },
                    icon: SvgPicture.asset(
                      'packages/presentation/assets/icon_tick.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                itemBuilder: (context, index) {
                  final period = state.periods.reversed.toList()[index];
                  // Only the last (most recent) period can be open-ended.
                  // Since the list is reversed, index 0 represents the last period.
                  final canBeOpenEnded = index == 0;
                  return SettingsPeriodCard(
                    period: period,
                    incomeController: _incomeControllers[period.id]!,
                    savingsController: _savingsControllers[period.id]!,
                    formatMonthYear: _formatMonthYear,
                    parseNumberInput: _parseNumberInput,
                    onStartDatePress: () => _selectStartDate(context, period),
                    onEndDatePress: () => _selectEndDate(context, period),
                    canBeOpenEnded: canBeOpenEnded,
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: state.periods.length,
              ),
              // Top shadow and border
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ScrollBoundaryIndicator.top(),
              ),
              // Bottom shadow and border
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ScrollBoundaryIndicator.bottom(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddPeriodButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add),
      label: Text(l10n.settingsAddPeriod),
      onPressed: () {
        context.read<SettingsBloc>().add(const SettingsEvent.periodAdded());
      },
    );
  }

  Future<void> _selectStartDate(
    BuildContext context,
    SettingsPeriodForm period,
  ) async {
    final l10n = AppLocalizations.of(context);
    final initialDate = DateTime(period.startYear, period.startMonth, 1);
    final firstDate = DateTime(2000, 1, 1);
    final lastDate = DateTime(DateTime.now().year + 5, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: l10n.settingsSelectDate,
    );

    if (picked != null && mounted) {
      this.context.read<SettingsBloc>().add(
            SettingsEvent.periodStartChanged(
              id: period.id,
              month: picked.month,
              year: picked.year,
            ),
          );
    }
  }

  Future<void> _selectEndDate(
    BuildContext context,
    SettingsPeriodForm period,
  ) async {
    final l10n = AppLocalizations.of(context);
    final initialDate = DateTime(
      period.endYear ?? period.startYear,
      period.endMonth ?? period.startMonth,
      1,
    );
    final firstDate = DateTime(period.startYear, period.startMonth, 1);
    final lastDate = DateTime(DateTime.now().year + 5, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: l10n.settingsSelectDate,
    );

    if (picked != null && mounted) {
      this.context.read<SettingsBloc>().add(
            SettingsEvent.periodEndChanged(
              id: period.id,
              month: picked.month,
              year: picked.year,
            ),
          );
    }
  }

  String _formatMonthYear(BuildContext context, int month, int year) {
    return '${_shortMonthLabel(context, month)} $year';
  }

  void _syncControllersWithState(SettingsState state) {
    final periodIds = state.periods.map((period) => period.id).toSet();

    final removedIncomeIds =
        _incomeControllers.keys.where((id) => !periodIds.contains(id)).toList();
    for (final id in removedIncomeIds) {
      _incomeControllers.remove(id)?.dispose();
      _incomeValues.remove(id);
    }

    final removedSavingsIds = _savingsControllers.keys
        .where((id) => !periodIds.contains(id))
        .toList();
    for (final id in removedSavingsIds) {
      _savingsControllers.remove(id)?.dispose();
      _savingsValues.remove(id);
    }

    for (final period in state.periods) {
      final incomeController = _incomeControllers.putIfAbsent(
        period.id,
        () => TextEditingController(),
      );
      final savingsController = _savingsControllers.putIfAbsent(
        period.id,
        () => TextEditingController(),
      );

      final incomeValue = period.income;
      final lastIncomeValue = _incomeValues[period.id];
      if (lastIncomeValue != incomeValue) {
        _incomeValues[period.id] = incomeValue;
        final text = incomeValue > 0 ? _numberFormat.format(incomeValue) : '';
        if (incomeController.text != text) {
          incomeController
            ..text = text
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: incomeController.text.length),
            );
        }
      }

      final savingsValue = period.savingsAmount;
      final lastSavingsValue = _savingsValues[period.id];
      if (lastSavingsValue != savingsValue) {
        _savingsValues[period.id] = savingsValue;
        final text = savingsValue > 0 ? _numberFormat.format(savingsValue) : '';
        if (savingsController.text != text) {
          savingsController
            ..text = text
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: savingsController.text.length),
            );
        }
      }
    }
  }

  String _parseNumberInput(String value) {
    final locale = Localizations.localeOf(context).toString();

    // Cache the format to avoid recreation on every keystroke
    if (_cachedParseFormat == null || _cachedLocale != locale) {
      _cachedLocale = locale;
      _cachedParseFormat = NumberFormat.decimalPattern(locale);
    }

    final format = _cachedParseFormat!;
    final decimalSeparator = format.symbols.DECIMAL_SEP;
    final groupSeparator = format.symbols.GROUP_SEP;

    String normalizedValue = value.replaceAll(groupSeparator, '');
    if (decimalSeparator != '.') {
      normalizedValue = normalizedValue.replaceAll(decimalSeparator, '.');
    }

    return normalizedValue;
  }

  String _shortMonthLabel(BuildContext context, int month) {
    final full = _monthLabel(context, month);
    return full.length <= 3 ? full : full.substring(0, 3);
  }

  String _monthLabel(BuildContext context, int month) {
    final l10n = AppLocalizations.of(context);
    final monthNames = [
      l10n.monthJanuary,
      l10n.monthFebruary,
      l10n.monthMarch,
      l10n.monthApril,
      l10n.monthMay,
      l10n.monthJune,
      l10n.monthJuly,
      l10n.monthAugust,
      l10n.monthSeptember,
      l10n.monthOctober,
      l10n.monthNovember,
      l10n.monthDecember,
    ];

    return monthNames[month - 1];
  }
}
