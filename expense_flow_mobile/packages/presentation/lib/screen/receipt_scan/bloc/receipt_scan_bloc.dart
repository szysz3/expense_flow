import 'package:domain/use_case/analyze_receipt_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:vibration/vibration.dart';

import '../../../core/service/camera/camera_service.dart';
import 'receipt_scan_events.dart';

class ReceiptScanBloc extends Bloc<ReceiptScanEvent, BaseReceiptScanState> {
  final CameraService _cameraService;
  final AnalyzeReceiptUseCase _analyzeReceiptUseCase;

  ReceiptScanBloc(
    this._cameraService,
    this._analyzeReceiptUseCase,
  ) : super(ReceiptScanInitState()) {
    on<InitializeCameraEvent>(_initializeCamera);
    on<TakePhotoEvent>(_takePhoto);
    on<CameraButtonPressedEvent>(_handleCameraButtonPress);
    on<SetFocusPointEvent>(_handleSetFocusPoint);
    on<PhotoRejectedEvent>(_handleBackButtonPress);
    on<PhotoAcceptedEvent>(_handlePhotoAcceptedEvent);
  }

  Future<void> _initializeCamera(
    InitializeCameraEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) async {
    try {
      final controller = await _cameraService.initialize();
      emit(ReceiptScanState(controller: controller));
    } catch (e) {
      emit(ReceiptScanErrorState(message: 'Failed to initialize camera: $e'));
    }
  }

  void _handleCameraButtonPress(
    CameraButtonPressedEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) {
    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;
      if (scanState.cameraPreviewState != CameraPreviewState.photoProcessing) {
        if (scanState.cameraPreviewState == CameraPreviewState.cameraPreview) {
          add(TakePhotoEvent());
        } else {
          emit(scanState.copyWith(
              cameraPreviewState: CameraPreviewState.cameraPreview));
        }
      }
    }
  }

  Future<void> _handlePhotoAcceptedEvent(
    PhotoAcceptedEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) async {
    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;

      if (scanState.photoPath == null) {
        emit(ReceiptScanErrorState(message: 'No photo available for analysis'));
        return;
      }

      emit(scanState.copyWith(
        cameraPreviewState: CameraPreviewState.loading,
      ));

      final result = await _analyzeReceiptUseCase(
        AnalyzeReceiptParams(
          filePath: scanState.photoPath!,
          llmType: 'local', // You might want to make this configurable
        ),
      );

      result.fold(
        (failure) {
          emit(scanState.copyWith(
            cameraPreviewState: CameraPreviewState.uploadFailure,
          ));
        },
        (receipt) {
          emit(scanState.copyWith(
            cameraPreviewState: CameraPreviewState.uploadSuccess,
          ));
        },
      );

      // Wait for the success/failure animation to complete
      await Future.delayed(const Duration(milliseconds: 1500));

      if (state is ReceiptScanState) {
        final currentState = state as ReceiptScanState;
        emit(currentState.copyWith(
          photoPath: null,
          cameraPreviewState: CameraPreviewState.idle,
        ));
      }
    }
  }

  void _handleBackButtonPress(
    PhotoRejectedEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) {
    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;
      emit(scanState.copyWith(
        cameraPreviewState: CameraPreviewState.cameraPreview,
        photoPath: null,
      ));
    }
  }

  Future<void> _handleSetFocusPoint(
    SetFocusPointEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) async {
    if (state is ReceiptScanState) {
      try {
        await _cameraService.setFocusPoint(event.point.dx, event.point.dy);
      } catch (e) {
        emit(ReceiptScanErrorState(message: 'Failed to set focus: $e'));
      }
    }
  }

  Future<void> _takePhoto(
    TakePhotoEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) async {
    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;

      emit(scanState.copyWith(
          cameraPreviewState: CameraPreviewState.photoProcessing));

      try {
        await Vibration.vibrate(duration: 50);

        final imagePath = await _cameraService.takePhoto();
        emit(scanState.copyWith(
          cameraPreviewState: CameraPreviewState.photoPreview,
          photoPath: imagePath,
        ));
      } catch (e) {
        emit(scanState.copyWith(
            cameraPreviewState: CameraPreviewState.cameraPreview));
        emit(ReceiptScanErrorState(message: 'Failed to take photo: $e'));
      }
    }
  }
}
