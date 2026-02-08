import 'package:domain/use_case/receipt/receipt_analyze_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/service/camera/camera_service.dart';
import '../../core/widget/full_screen_loading_overlay.dart';
import '../../core/widget/loading_indicator_widget.dart';
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
            getIt<ReceiptAnalyzeUseCase>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const ReceiptScanEvent.initializeCamera()),
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'packages/presentation/assets/background_receipt_scanning.svg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(
                left: 16.0, right: 16.0, bottom: 16.0, top: 8.0),
            child: ReceiptScanView(),
          ),
        ],
      ));
}

class ReceiptScanView extends StatefulWidget {
  const ReceiptScanView({super.key});

  @override
  State<ReceiptScanView> createState() => _ReceiptScanViewState();
}

class _ReceiptScanViewState extends State<ReceiptScanView> {
  final _loadingOverlay = FullScreenLoadingOverlay();

  @override
  void dispose() {
    _loadingOverlay.dispose();
    super.dispose();
  }

  void _onPreviewStateChanged(CameraPreviewState previewState) {
    final isLoadingState = [
      CameraPreviewState.loading,
      CameraPreviewState.uploadFailure,
      CameraPreviewState.uploadSuccess,
    ].contains(previewState);

    if (isLoadingState) {
      _loadingOverlay.update(
        isSuccess: previewState == CameraPreviewState.uploadSuccess,
      );
      if (!_loadingOverlay.isShowing) {
        _loadingOverlay.show(context);
      }
    } else {
      _loadingOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ReceiptScanBloc, BaseReceiptScanState>(
        listener: (context, state) {
          if (state is ReceiptScanState) {
            _onPreviewStateChanged(state.cameraPreviewState);
          }
          if (state is ReceiptScanState && state.error != null) {
            ErrorUtils.showErrorSnackBar(context, state.error!);
          }
        },
        builder: (context, state) {
          if (state is ReceiptScanInitState) {
            return const Center(
                child: LoadingIndicatorWidget(sizeFactor: 0.15));
          } else if (state is ReceiptScanState) {
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
