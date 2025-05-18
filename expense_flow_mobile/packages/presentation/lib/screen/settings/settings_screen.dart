import 'package:domain/use_case/settings/settings_get_savings_use_case.dart';
import 'package:domain/use_case/settings/settings_save_savings_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/animated_square_button.dart';
import '../../core/widget/input_widget.dart';
import '../../di/di.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/settings_event.dart';
import 'bloc/settings_state.dart';

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
          getIt<SettingsGetSavingsUseCase>(),
          getIt<SettingsSaveSavingsUseCase>(),
        )..add(const SettingsEvent.init()),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
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
              child: Column(
                children: [
                  _buildModalHeader(context),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SettingsScreenView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreenView extends StatefulWidget {
  const SettingsScreenView({super.key});

  @override
  State<SettingsScreenView> createState() => _SettingsScreenViewState();
}

class _SettingsScreenViewState extends State<SettingsScreenView> {
  final _savingsAmountController = TextEditingController();
  final _incomeController = TextEditingController();
  final _numberFormat = NumberFormat.decimalPattern();

  @override
  void dispose() {
    _savingsAmountController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        return current.error != null ||
            (previous.isLoading && !current.isLoading);
      },
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }

        if (!state.isLoading &&
            state.savingsAmount > 0 &&
            _savingsAmountController.text.isEmpty) {
          _savingsAmountController.text =
              _numberFormat.format(state.savingsAmount);
        }

        if (!state.isLoading &&
            state.income > 0 &&
            _incomeController.text.isEmpty) {
          _incomeController.text = _numberFormat.format(state.income);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildSettingsContent(context, state);
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context, SettingsState state) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settings,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            InputWidget(
              controller: _savingsAmountController,
              onDescriptionChanged: (value) {
                context.read<SettingsBloc>().add(
                      SettingsEvent.savingsAmountChanged(
                          _parseNumberInput(value)),
                    );
              },
              labelText: l10n.savingsAmount,
              hintText: l10n.savingsAmountHint,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 24),
            InputWidget(
              controller: _incomeController,
              onDescriptionChanged: (value) {
                context.read<SettingsBloc>().add(
                      SettingsEvent.incomeChanged(_parseNumberInput(value)),
                    );
              },
              labelText: l10n.income,
              hintText: l10n.incomeHint,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: Center(
            child: AnimatedSquareButton(
              isProcessing: state.isSaving,
              onPressed: () {
                context.read<SettingsBloc>().add(
                      const SettingsEvent.saveSettings(),
                    );
                Navigator.of(context).pop();
              },
              icon: SvgPicture.asset(
                'packages/presentation/assets/icon_tick.svg',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _parseNumberInput(String value) {
    // Remove formatting characters for processing
    final locale = Localizations.localeOf(context);
    final format = NumberFormat.decimalPattern(locale.toString());
    final decimalSeparator = format.symbols.DECIMAL_SEP;
    final groupSeparator = format.symbols.GROUP_SEP;

    String normalizedValue = value.replaceAll(groupSeparator, '');
    if (decimalSeparator != '.') {
      normalizedValue = normalizedValue.replaceAll(decimalSeparator, '.');
    }

    return normalizedValue;
  }
}
