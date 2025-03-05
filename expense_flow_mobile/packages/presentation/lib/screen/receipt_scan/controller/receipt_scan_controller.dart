import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_bloc.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_events.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_controller.dart';

class ReceiptScanController implements CameraPreviewController {
  final BuildContext context;

  ReceiptScanController(this.context);

  @override
  void handleFocusTap(TapUpDetails details, Size size) {
    final point = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    context.read<ReceiptScanBloc>().add(SetFocusPointEvent(point));
  }

  @override
  void onCameraButtonPressed() {
    context.read<ReceiptScanBloc>().add(CameraButtonPressedEvent());
  }

  @override
  void onPhotoRejectButtonPressed() {
    context.read<ReceiptScanBloc>().add(PhotoRejectedEvent());
  }

  @override
  void onPhotoAcceptedButtonPressed() {
    context.read<ReceiptScanBloc>().add(PhotoAcceptedEvent());
  }

  @override
  void onErrorDismissed() {
    context.read<ReceiptScanBloc>().add(DismissErrorEvent());
  }
}
