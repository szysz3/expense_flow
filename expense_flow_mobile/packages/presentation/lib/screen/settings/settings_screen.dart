import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
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
        )..add(const SettingsEvent.init()),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreenView extends StatelessWidget {
  const SettingsScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return ErrorDisplayWidget(
            error: state.error!,
            isFullScreen: true,
          );
        }

        return _buildSettingsContent(context, state);
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context, SettingsState state) {
    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputWidget(
                  controller: TextEditingController(),
                  onDescriptionChanged: (value) {},
                  labelText: AppLocalizations.of(context).savingsAmount,
                  hintText: AppLocalizations.of(context).savingsAmountHint,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  )),
              const SizedBox(height: 24),
              InputWidget(
                  controller: TextEditingController(),
                  onDescriptionChanged: (value) {},
                  labelText: AppLocalizations.of(context).income,
                  hintText: AppLocalizations.of(context).incomeHint,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  )),
            ],
          ),
        ));
  }
}
