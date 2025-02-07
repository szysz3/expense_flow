import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
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
    return BlocBuilder<ReceiptScanBloc, ReceiptScanState>(
      builder: (context, state) {
        return switch (state) {
          PhotoTaken() => Center(child: Image.file(File(state.imagePath))),
          CameraInitialized() => _CameraPreview(state),
          ReceiptScanError() => Center(child: Text(state.message)),
          _ => const SizedBox.shrink()
        };
      },
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraInitialized state;

  const _CameraPreview(this.state);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!state.isBlurred) _buildPreview(context),
        _buildCameraButton(context),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final controller = state.controller;

    return Transform.scale(
        scale: _getImageZoom(MediaQuery.of(context), controller),
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Transform.rotate(
              angle: _getCameraRotation(),
              child: CameraPreview(controller),
            ),
          ),
        ));
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
    final sensorOrientation = state.controller.description.sensorOrientation;
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
          child: Icon(state.isBlurred ? Icons.visibility : Icons.camera),
        ),
      ),
    );
  }
}
