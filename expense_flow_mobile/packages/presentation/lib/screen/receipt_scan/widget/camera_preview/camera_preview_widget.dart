import 'package:flutter/widgets.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:presentation/screen/receipt_scan/widget/action_bar/action_bar.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_button.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_controller.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_state.dart';
import 'package:presentation/screen/receipt_scan/widget/loading_indicator_widget.dart';
import 'package:presentation/screen/receipt_scan/widget/preview_container.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraPreviewController controller;
  final CameraPreviewWidgetState state;

  const CameraPreviewWidget({
    required this.controller,
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          if ([
            CameraPreviewState.cameraPreview,
            CameraPreviewState.photoPreview,
            CameraPreviewState.photoProcessing
          ].contains(state.previewState))
            _buildMainContent(context),
          if ([
            CameraPreviewState.loading,
            CameraPreviewState.uploadFailure,
            CameraPreviewState.uploadSuccess
          ].contains(state.previewState))
            _buildLoadingIndicator(),
          if ([
            CameraPreviewState.idle,
            CameraPreviewState.cameraPreview,
            CameraPreviewState.photoProcessing
          ].contains(state.previewState))
            _buildCameraButton(),
        ],
      );

  Widget _buildLoadingIndicator() => Center(
        child: LoadingIndicatorWidget(
          isSuccess: state.previewState == CameraPreviewState.uploadSuccess,
          sizeFactor: 0.5,
        ),
      );

  Widget _buildMainContent(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PreviewContainer(
            state: state,
            onFocusTap: (details, size) =>
                controller.handleFocusTap(details, size),
          ),
          ActionBar(
            isPhotoPreviewActive:
                state.previewState == CameraPreviewState.photoPreview,
            onBackPressed: controller.onPhotoRejectButtonPressed,
            onConfirmPressed: controller.onPhotoAcceptedButtonPressed,
          ),
        ],
      );

  Widget _buildCameraButton() => Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: CameraButton(
          isProcessing:
              state.previewState == CameraPreviewState.photoProcessing,
          isCameraPreviewActive:
              state.previewState == CameraPreviewState.cameraPreview,
          onPressed: controller.onCameraButtonPressed,
        ),
      );
}
