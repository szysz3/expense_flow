import 'package:flutter/widgets.dart';

abstract class CameraPreviewController {
  void handleFocusTap(TapUpDetails details, Size size);

  void onCameraButtonPressed();

  void onPhotoRejectButtonPressed();

  void onPhotoAcceptedButtonPressed();

  void onErrorDismissed();
}
