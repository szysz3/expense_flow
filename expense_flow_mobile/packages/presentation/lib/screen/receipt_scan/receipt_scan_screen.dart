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
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            ReceiptScanBloc(CameraService())..add(InitializeCameraEvent()),
        child: const _ReceiptScanView(),
      );
}

class _ReceiptScanView extends StatelessWidget {
  const _ReceiptScanView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ReceiptScanBloc, BaseReceiptScanState>(
        builder: (context, state) => switch (state) {
          ReceiptScanState() => _CameraPreview(
              state.controller,
              state.isCameraPreviewActive,
              state.photoPath,
              state.isPhotoPreviewActive,
              state.isProcessing),
          ReceiptScanErrorState() => Center(child: Text(state.message)),
          _ => const SizedBox.shrink()
        },
      );
}

class _CameraPreview extends StatelessWidget {
  static const _animationDuration = Duration(milliseconds: 300);
  static const _buttonAnimationDuration = Duration(milliseconds: 400);
  static const _previewSlideAnimationDuration = Duration(milliseconds: 600);

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
  Widget build(BuildContext context) => Stack(
        children: [
          if (isCameraPreviewActive == true || isPhotoPreviewActive == true)
            _buildMainContent(context),
          if (photoPath == null) _buildCameraButton(context),
        ],
      );

  Widget _buildMainContent(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPreviewContainer(context),
          _buildActionBar(),
        ],
      );

  Widget _buildPreviewContainer(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: _getPreviewBorderRadius(),
        ),
        child: GestureDetector(
          onTapUp: isCameraPreviewActive == true
              ? (details) => _handleFocusTap(details, context)
              : null,
          child: _buildPreviewContent(),
        ),
      );

  BorderRadius _getPreviewBorderRadius() => isPhotoPreviewActive == true
      ? const BorderRadius.vertical(top: Radius.circular(8))
      : BorderRadius.circular(8);

  Widget _buildPreviewContent() => AnimatedSwitcher(
        duration: _animationDuration,
        transitionBuilder: _buildTransition,
        child: _getContent(),
      );

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final scaleCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );
    final scaleValue = Tween<double>(begin: 0.9, end: 1.0).animate(scaleCurve);

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: scaleValue,
        child: child,
      ),
    );
  }

  Widget _buildActionBar() => AnimatedOpacity(
        opacity: isPhotoPreviewActive == true ? 1.0 : 0.0,
        duration: _animationDuration,
        curve: Curves.easeInOut,
        child: AnimatedSlide(
          offset: Offset(0, isPhotoPreviewActive == true ? 0 : 0.5),
          duration: _previewSlideAnimationDuration,
          curve: Curves.easeInOut,
          child: _ActionBar(),
        ),
      );

  Widget _buildCameraButton(BuildContext context) => Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: _buttonAnimationDuration,
            curve: Curves.elasticOut,
            builder: (_, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withOpacity(0.4),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isProcessing
                      ? null
                      : () => context
                          .read<ReceiptScanBloc>()
                          .add(CameraButtonPressedEvent()),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, animation) {
                        final scaleCurve = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        );
                        final scaleValue = Tween<double>(
                          begin: 0.8,
                          end: 1.0,
                        ).animate(scaleCurve);

                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: scaleValue,
                            child: child,
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        isCameraPreviewActive == true
                            ? 'packages/presentation/assets/icon_scan_receipt.svg'
                            : 'packages/presentation/assets/icon_photo.svg',
                        width: 40,
                        height: 40,
                        key: ValueKey(isCameraPreviewActive),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  void _handleFocusTap(TapUpDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final localPoint = box.globalToLocal(details.globalPosition);
    final point = Offset(
      localPoint.dx / box.size.width,
      localPoint.dy / box.size.height,
    );
    context.read<ReceiptScanBloc>().add(SetFocusPointEvent(point));
  }

  Widget _getContent() {
    if (isCameraPreviewActive == true) return CameraPreview(cameraController);
    if (isPhotoPreviewActive == true) {
      return Image.file(File(photoPath!), fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }
}

class _ActionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          color: Colors.black.withOpacity(0.4),
        ),
        transform: Matrix4.translationValues(0, -1, 0),
        height: 64,
        child: Row(
          children: [
            _buildActionButton(
              flex: 1,
              iconPath: 'packages/presentation/assets/icon_back.svg',
              iconSize: 24,
            ),
            Container(width: 1, color: Colors.white),
            _buildActionButton(
              flex: 3,
              iconPath: 'packages/presentation/assets/icon_tick.svg',
              iconSize: 40,
            ),
          ],
        ),
      );

  Widget _buildActionButton({
    required int flex,
    required String iconPath,
    required double iconSize,
  }) =>
      Expanded(
        flex: flex,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
              ),
            ),
          ),
        ),
      );
}
