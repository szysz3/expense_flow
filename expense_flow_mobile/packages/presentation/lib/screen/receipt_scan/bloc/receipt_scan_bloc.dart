import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/services/camera/camera_service.dart';
import 'package:vibration/vibration.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'receipt_scan_events.dart';

class ReceiptScanBloc extends Bloc<ReceiptScanEvent, BaseReceiptScanState> {
  final CameraService _cameraService;

  ReceiptScanBloc(this._cameraService) : super(ReceiptScanInitState()) {
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
      emit(scanState.copyWith(
        cameraPreviewState: CameraPreviewState.loading,
      ));
    }

    await Future.delayed(Duration(milliseconds: 5000));

    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;
      emit(scanState.copyWith(
        cameraPreviewState: CameraPreviewState.uploadSuccess,
      ));
    }

    await Future.delayed(Duration(milliseconds: 1500));

    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;
      emit(scanState.copyWith(
          photoPath: null, cameraPreviewState: CameraPreviewState.idle));
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
