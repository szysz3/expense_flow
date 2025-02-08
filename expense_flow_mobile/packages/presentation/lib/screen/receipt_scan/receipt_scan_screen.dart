import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/svg.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_bloc.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_events.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:presentation/screen/receipt_scan/service/camera_service.dart';

class ReceiptScanScreen extends StatelessWidget {
  const ReceiptScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReceiptScanBloc(CameraService.instance)..add(InitializeCameraEvent()),
      child: const _ReceiptScanView(),
    );
  }
}

class _ReceiptScanView extends StatelessWidget {
  const _ReceiptScanView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptScanBloc, BaseReceiptScanState>(
      builder: (context, state) {
        return switch (state) {
          ReceiptScanState() => _CameraPreview(
              state.controller,
              state.isCameraPreviewActive,
              state.photoPath,
              state.isPhotoPreviewActive),
          ReceiptScanErrorState() => Center(child: Text(state.message)),
          _ => const SizedBox.shrink()
        };
      },
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraController cameraController;
  final bool? isCameraPreviewActive;
  final bool? isPhotoPreviewActive;
  final String? photoPath;

  const _CameraPreview(this.cameraController, this.isCameraPreviewActive,
      this.photoPath, this.isPhotoPreviewActive);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isCameraPreviewActive == true || isPhotoPreviewActive == true)
          _wrappedContent(),
        if (photoPath == null) _buildCameraButton(context),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Transform.scale(
        scale: 1, //_getImageZoom(MediaQuery.of(context), cameraController),
        child: Center(
            child: AspectRatio(
          aspectRatio: cameraController.value.aspectRatio,
          child: _wrappedContent(), //_getContent(),
        )));
  }

  Widget _wrappedContent() {
    return Center(
      child: Column(
        children: [
          Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.yellow)),
              child: AspectRatio(
                aspectRatio: cameraController.value.aspectRatio,
                child: _getContent(), //_getContent(),
              )),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: SvgPicture.asset(
                    'packages/presentation/assets/icon_back.svg',
                    width: 48, // customize size
                    height: 48,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: SvgPicture.asset(
                    'packages/presentation/assets/icon_tick.svg',
                    width: 48, // customize size
                    height: 48,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _getContent() {
    if (isCameraPreviewActive == true) {
      return Transform.rotate(
          angle: _getCameraRotation(), child: CameraPreview(cameraController));
    }

    if (isPhotoPreviewActive == true) {
      return Image.file(File(photoPath!));
    }

    return SizedBox.shrink();
  }

  double _getImageZoom(MediaQueryData data, CameraController controller) {
    final double logicalWidth = data.size.width;
    final double logicalHeight = controller.value.aspectRatio * logicalWidth;

    final EdgeInsets padding = data.padding;
    final double maxLogicalHeight =
        data.size.height - padding.top - padding.bottom;

    return maxLogicalHeight / logicalHeight;
  }

  double _getCameraRotation() {
    final sensorOrientation = cameraController.description.sensorOrientation;
    return sensorOrientation * pi / 180;
  }

  Widget _buildCameraButton(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          onPressed: () =>
              context.read<ReceiptScanBloc>().add(CameraButtonPressedEvent()),
          child: Icon(
              isCameraPreviewActive == false ? Icons.visibility : Icons.camera),
        ),
      ),
    );
  }
}
