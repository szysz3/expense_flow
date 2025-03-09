import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/receipt_scan_bloc.dart';
import '../bloc/receipt_scan_events.dart';
import '../widget/camera_preview/camera_preview_controller.dart';

class ReceiptScanController implements CameraPreviewController {
  final BuildContext context;

  ReceiptScanController(this.context);

  @override
  void handleFocusTap(TapUpDetails details, Size size) {
    final point = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    context.read<ReceiptScanBloc>().add(ReceiptScanEvent.setFocusPoint(point));
  }

  @override
  void onCameraButtonPressed() {
    context
        .read<ReceiptScanBloc>()
        .add(const ReceiptScanEvent.cameraButtonPressed());
  }

  @override
  void onPhotoRejectButtonPressed() {
    context.read<ReceiptScanBloc>().add(const ReceiptScanEvent.photoRejected());
  }

  @override
  void onPhotoAcceptedButtonPressed() {
    context.read<ReceiptScanBloc>().add(const ReceiptScanEvent.photoAccepted());
  }

  @override
  void onErrorDismissed() {
    context.read<ReceiptScanBloc>().add(const ReceiptScanEvent.dismissError());
  }
}
