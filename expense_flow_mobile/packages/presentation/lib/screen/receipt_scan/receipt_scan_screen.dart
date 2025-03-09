import 'package:domain/use_case/analyze_receipt_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/service/camera/camera_service.dart';
import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';
import 'bloc/receipt_scan_bloc.dart';
import 'bloc/receipt_scan_events.dart';
import 'bloc/receipt_scan_state.dart';
import 'controller/receipt_scan_controller.dart';
import 'model/camera_preview_state.dart';
import 'widget/camera_preview/camera_preview_widget.dart';
import 'widget/camera_preview/camera_preview_widget_state.dart';

class ReceiptScanScreen extends StatelessWidget {
  const ReceiptScanScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ReceiptScanBloc(
          getIt<CameraService>(),
          getIt<AnalyzeReceiptUseCase>(),
          getIt<Logger>(),
          getIt<LocalizationService>(),
        )..add(const ReceiptScanEvent.initializeCamera()),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: ReceiptScanView(),
        ),
      );
}

class ReceiptScanView extends StatelessWidget {
  const ReceiptScanView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ReceiptScanBloc, BaseReceiptScanState>(
        listener: (context, state) {
          if (state is ReceiptScanState && state.error != null) {
            ErrorUtils.showErrorSnackBar(context, state.error!);
          }
        },
        builder: (context, state) {
          if (state is ReceiptScanInitState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReceiptScanState) {
            if (state.error != null &&
                state.cameraPreviewState != CameraPreviewState.cameraPreview &&
                state.cameraPreviewState != CameraPreviewState.photoPreview) {
              return Center(
                child: ErrorDisplayWidget(
                  error: state.error!,
                  isFullScreen: true,
                ),
              );
            }

            if (state.controller != null) {
              return CameraPreviewWidget(
                controller: ReceiptScanController(context),
                state: CameraPreviewWidgetState(
                  previewState: state.cameraPreviewState,
                  photoPath: state.photoPath,
                  cameraController: state.controller!,
                ),
              );
            }
          }

          return const SizedBox.shrink();
        },
      );
}
