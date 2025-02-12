import 'package:flutter/widgets.dart';
import 'package:presentation/screen/receipt_scan/widget/action_bar/action_bar.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_button.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_controller.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_state.dart';
import 'package:presentation/screen/receipt_scan/widget/loading_indicator_widget.dart';
import 'package:presentation/screen/receipt_scan/widget/preview_container.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraPreviewController controller;
  final CameraPreviewState state;

  const CameraPreviewWidget({
    required this.controller,
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          if (state.isCameraPreviewActive || state.isPhotoPreviewActive)
            _buildMainContent(context),
          // TODO: temporarily
          Center(
            child: LoadingIndicatorWidget(
              isSuccess: state.isPhotoPreviewActive,
              sizeFactor: 0.5,
            ),
          ),
          if (state.photoPath == null) _buildCameraButton(),
        ],
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
            isPhotoPreviewActive: state.isPhotoPreviewActive,
            onBackPressed: controller.onBackButtonPressed,
            onConfirmPressed: controller.onConfirmPressed,
          ),
        ],
      );

  Widget _buildCameraButton() => Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: CameraButton(
          isProcessing: state.isProcessing,
          isCameraPreviewActive: state.isCameraPreviewActive,
          onPressed: controller.onCameraButtonPressed,
        ),
      );
}
