import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/widget/animated_square_button.dart';
import '../../../../core/widget/loading_indicator_widget.dart';
import '../../model/camera_preview_state.dart';
import '../action_bar/action_bar.dart';
import '../preview_container.dart';
import 'camera_preview_controller.dart';
import 'camera_preview_widget_state.dart';

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
            _buildLoadingIndicator(context),
          if ([
            CameraPreviewState.idle,
            CameraPreviewState.cameraPreview,
            CameraPreviewState.photoProcessing
          ].contains(state.previewState))
            _buildCameraButton(),
        ],
      );

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: LoadingIndicatorWidget(
        isSuccess: state.previewState == CameraPreviewState.uploadSuccess,
        sizeFactor: 0.5,
      ),
    );
  }

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
        bottom: 20,
        left: 0,
        right: 0,
        child: AnimatedSquareButton.square(
          isProcessing:
              state.previewState == CameraPreviewState.photoProcessing,
          onPressed: controller.onCameraButtonPressed,
          icon: SvgPicture.asset(
            _shouldShowScanIcon(state.previewState)
                ? 'packages/presentation/assets/icon_scan_receipt.svg'
                : 'packages/presentation/assets/icon_photo.svg',
            width: 40,
            height: 40,
            key: ValueKey(
                state.previewState == CameraPreviewState.cameraPreview),
          ),
          size: 64,
          iconSize: 40,
        ),
      );
}

bool _shouldShowScanIcon(CameraPreviewState state) {
  return [
    CameraPreviewState.cameraPreview,
    CameraPreviewState.photoProcessing,
  ].contains(state);
}
