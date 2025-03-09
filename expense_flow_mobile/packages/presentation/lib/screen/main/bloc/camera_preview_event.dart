import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_preview_event.freezed.dart';

@freezed
class CameraPreviewEvent with _$CameraPreviewEvent {
  const factory CameraPreviewEvent.initialize() = InitializeCameraEvent;
}
