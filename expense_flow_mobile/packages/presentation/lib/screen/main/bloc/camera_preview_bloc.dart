import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/main/bloc/camera_preview_event.dart';
import 'package:presentation/screen/main/bloc/camera_preview_state.dart';
import 'package:presentation/services/camera/camera_service.dart';

class CameraPreviewBloc extends Bloc<CameraPreviewEvent, CamerawPreviewState> {
  final CameraService _cameraService;

  CameraPreviewBloc(this._cameraService) : super(CameraPreviewInit()) {
    on<InitializeCameraEvent>(_initializeCamera);
  }

  Future<void> _initializeCamera(
    InitializeCameraEvent event,
    Emitter<CamerawPreviewState> emit,
  ) async {
    try {
      final controller = await _cameraService.initialize();
      emit(CameraPreviewInitialized(controller));
    } catch (e) {
      emit(CameraInitError('Failed to initialize camera: $e'));
    }
  }

  @override
  Future<void> close() {
    _cameraService.dispose();
    return super.close();
  }
}
