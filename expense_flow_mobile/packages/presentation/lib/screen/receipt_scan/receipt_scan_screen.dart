import 'dart:io';
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
          ReceiptScanBloc(CameraService())..add(InitializeCameraEvent()),
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
              state.isPhotoPreviewActive,
              state.isProcessing),
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
  final bool isProcessing;

  const _CameraPreview(
    this.cameraController,
    this.isCameraPreviewActive,
    this.photoPath,
    this.isPhotoPreviewActive,
    this.isProcessing,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isCameraPreviewActive == true || isPhotoPreviewActive == true)
          _wrappedContent(context),
        if (photoPath == null) _buildCameraButton(context),
      ],
    );
  }

  Widget _wrappedContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.yellow),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: _getContent(),
          ),
        ),
        SizedBox(
          height: 80,
          child: Center(
            child: AnimatedOpacity(
              opacity: isPhotoPreviewActive == true ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSlide(
                offset: Offset(0, isPhotoPreviewActive == true ? 0 : 0.5),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      'packages/presentation/assets/icon_back.svg',
                      () => {},
                    ),
                    _buildActionButton(
                      'packages/presentation/assets/icon_tick.svg',
                      () => {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String assetPath, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: onTap,
          child: SvgPicture.asset(
            assetPath,
            width: 48,
            height: 48,
          ),
        ),
      ),
    );
  }

  Widget _getContent() {
    if (isCameraPreviewActive == true) {
      return CameraPreview(cameraController);
    }
    if (isPhotoPreviewActive == true) {
      return Image.file(
        File(photoPath!),
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCameraButton(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: FloatingActionButton(
            onPressed: isProcessing
                ? null
                : () => context
                    .read<ReceiptScanBloc>()
                    .add(CameraButtonPressedEvent()),
            child: Icon(isCameraPreviewActive == false
                ? Icons.visibility
                : Icons.camera),
          ),
        ),
      ),
    );
  }
}
