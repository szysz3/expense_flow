import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';
import 'bloc/receipt_browse_bloc.dart';
import 'bloc/receipt_browse_event.dart';
import 'bloc/receipt_browse_state.dart';

class ReceiptBrowseScreen extends StatelessWidget {
  const ReceiptBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => ReceiptBrowseBloc(
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const ReceiptBrowseEvent.init()),
      child: Stack(children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'packages/presentation/assets/background_unprocessed.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: ReceiptBrowseView(),
        ),
      ]));
}

class ReceiptBrowseView extends StatelessWidget {
  const ReceiptBrowseView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceiptBrowseBloc, ReceiptBrowseState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!.message)),
          );
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

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'packages/presentation/assets/icon_scan.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).appBarBrowseReceiptsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Browse your receipts here',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
