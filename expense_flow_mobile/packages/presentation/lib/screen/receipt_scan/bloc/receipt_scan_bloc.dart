import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:presentation/screen/receipt_scan/service/camera_service.dart';
import 'receipt_scan_events.dart';

class ReceiptScanBloc extends Bloc<ReceiptScanEvent, ReceiptScanState> {
  final CameraService _cameraService;

  ReceiptScanBloc(this._cameraService) : super(ReceiptScanInitial()) {
    on<InitializeCameraEvent>(_initializeCamera);
    on<TakePhotoEvent>(_takePhoto);
    on<CameraButtonPressedEvent>(_handleCameraButtonPress);
  }

  Future<void> _initializeCamera(
    InitializeCameraEvent event,
    Emitter<ReceiptScanState> emit,
  ) async {
    try {
      final controller = await _cameraService.initialize();
      emit(CameraInitialized(controller, isBlurred: true));
    } catch (e) {
      emit(ReceiptScanError('Failed to initialize camera: $e'));
    }
  }

  void _handleCameraButtonPress(
    CameraButtonPressedEvent event,
    Emitter<ReceiptScanState> emit,
  ) {
    if (state is CameraInitialized) {
      final currentState = state as CameraInitialized;
      if (currentState.isBlurred) {
        emit(CameraInitialized(currentState.controller, isBlurred: false));
      } else {
        add(TakePhotoEvent());
      }
    }
  }

  Future<void> _takePhoto(
    TakePhotoEvent event,
    Emitter<ReceiptScanState> emit,
  ) async {
    try {
      final imagePath = await _cameraService.takePhoto();
      emit(PhotoTaken(imagePath));
    } catch (e) {
      emit(ReceiptScanError('Failed to take photo: $e'));
    }
  }

  @override
  Future<void> close() {
    _cameraService.dispose();
    return super.close();
  }
}
