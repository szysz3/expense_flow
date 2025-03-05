import 'package:domain/use_case/analyze_receipt_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/di/di.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_bloc.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_events.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:presentation/screen/receipt_scan/controller/receipt_scan_controller.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_state.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_widget.dart';

import '../../core/service/camera/camera_service.dart';

class ReceiptScanScreen extends StatelessWidget {
  const ReceiptScanScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ReceiptScanBloc(
          getIt<CameraService>(),
          getIt<AnalyzeReceiptUseCase>(),
        )..add(InitializeCameraEvent()),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const ReceiptScanView(),
        ),
      );
}

class ReceiptScanView extends StatelessWidget {
  const ReceiptScanView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ReceiptScanBloc, BaseReceiptScanState>(
        builder: (context, state) => switch (state) {
          ReceiptScanState() => CameraPreviewWidget(
              controller: ReceiptScanController(context),
              state: CameraPreviewWidgetState(
                previewState: state.cameraPreviewState,
                photoPath: state.photoPath,
                cameraController: state.controller,
              ),
            ),
          ReceiptScanErrorState() => Center(child: Text(state.message)),
          _ => const SizedBox.shrink()
        },
      );
}
