import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:presentation/screen/receipt_scan/service/camera_service.dart';
import 'receipt_scan_events.dart';

class ReceiptScanBloc extends Bloc<ReceiptScanEvent, BaseReceiptScanState> {
  final CameraService _cameraService;

  ReceiptScanBloc(this._cameraService) : super(ReceiptScanInitState()) {
    on<InitializeCameraEvent>(_initializeCamera);
    on<TakePhotoEvent>(_takePhoto);
    on<CameraButtonPressedEvent>(_handleCameraButtonPress);
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
      if (!scanState.isProcessing) {
        if (scanState.isCameraPreviewActive == true) {
          add(TakePhotoEvent());
        } else {
          emit(scanState.copyWith(isCameraPreviewActive: true));
        }
      }
    }
  }

  Future<void> _takePhoto(
    TakePhotoEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) async {
    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;

      emit(scanState.copyWith(isProcessing: true));

      try {
        final imagePath = await _cameraService.takePhoto();
        emit(scanState.copyWith(
          isPhotoPreviewActive: true,
          isCameraPreviewActive: false,
          photoPath: imagePath,
          isProcessing: false,
        ));
      } catch (e) {
        emit(scanState.copyWith(isProcessing: false));
        emit(ReceiptScanErrorState(message: 'Failed to take photo: $e'));
      }
    }
  }
}
