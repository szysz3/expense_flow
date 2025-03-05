import 'package:domain/use_case/analyze_receipt_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:vibration/vibration.dart';

import '../../../../core/error/app_error.dart';
import '../../../core/service/camera/camera_service.dart';
import 'receipt_scan_events.dart';

class ReceiptScanBloc extends Bloc<ReceiptScanEvent, BaseReceiptScanState> {
  final CameraService _cameraService;
  final AnalyzeReceiptUseCase _analyzeReceiptUseCase;
  final Logger _errorLogger;

  ReceiptScanBloc(
    this._cameraService,
    this._analyzeReceiptUseCase,
    this._errorLogger,
  ) : super(ReceiptScanInitState()) {
    on<InitializeCameraEvent>(_initializeCamera);
    on<TakePhotoEvent>(_takePhoto);
    on<CameraButtonPressedEvent>(_handleCameraButtonPress);
    on<SetFocusPointEvent>(_handleSetFocusPoint);
    on<PhotoRejectedEvent>(_handleBackButtonPress);
    on<PhotoAcceptedEvent>(_handlePhotoAcceptedEvent);
    on<DismissErrorEvent>(_handleDismissError);
  }

  Future<void> _initializeCamera(
    InitializeCameraEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) async {
    try {
      final controller = await _cameraService.initialize();
      emit(ReceiptScanState(controller: controller));
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Failed to initialize camera',
        error: e,
        stackTrace: stackTrace,
      );

      emit(ReceiptScanState(
        controller: null,
        error: AppError.fromException(
          e,
          onRetry: () => add(InitializeCameraEvent()),
        ),
      ));
    }
  }

  void _handleCameraButtonPress(
    CameraButtonPressedEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) {
    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;

      if (scanState.error != null) {
        emit(scanState.copyWith(error: null));
        return;
      }

      if (scanState.cameraPreviewState != CameraPreviewState.photoProcessing) {
        if (scanState.cameraPreviewState == CameraPreviewState.cameraPreview) {
          add(TakePhotoEvent());
        } else {
          emit(scanState.copyWith(
            cameraPreviewState: CameraPreviewState.cameraPreview,
            error: null,
          ));
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
        emit(scanState.copyWith(
          error: AppError(
            message: 'No photo available',
            details: 'Please take a photo first',
          ),
        ));
        return;
      }

      emit(scanState.copyWith(
        cameraPreviewState: CameraPreviewState.loading,
        error: null,
      ));

      try {
        final result = await _analyzeReceiptUseCase(
          AnalyzeReceiptParams(
            filePath: scanState.photoPath!,
            llmType: 'local',
          ),
        );

        result.fold(
          (failure) {
            _errorLogger.e(
              'Failed to analyze receipt',
              error: failure,
            );

            emit(scanState.copyWith(
              cameraPreviewState: CameraPreviewState.uploadFailure,
              error: AppError.fromFailure(
                failure,
                onRetry: () => add(PhotoAcceptedEvent()),
              ),
            ));
          },
          (receipt) {
            _errorLogger.i('Receipt analyzed successfully: ${receipt.id}');

            emit(scanState.copyWith(
              cameraPreviewState: CameraPreviewState.uploadSuccess,
              error: null,
            ));
          },
        );

        // Wait for the success/failure animation to complete
        await Future.delayed(const Duration(milliseconds: 1500));

        if (state is ReceiptScanState) {
          final currentState = state as ReceiptScanState;

          if (currentState.cameraPreviewState ==
                  CameraPreviewState.uploadSuccess ||
              currentState.cameraPreviewState ==
                  CameraPreviewState.uploadFailure) {
            emit(currentState.copyWith(
              photoPath: null,
              cameraPreviewState: CameraPreviewState.idle,
              // Keep error if we had a failure
            ));
          }
        }
      } catch (e, stackTrace) {
        _errorLogger.e(
          'Exception during receipt analysis',
          error: e,
          stackTrace: stackTrace,
        );

        emit(scanState.copyWith(
          cameraPreviewState: CameraPreviewState.uploadFailure,
          error: AppError.fromException(
            e,
            onRetry: () => add(PhotoAcceptedEvent()),
          ),
        ));

        // Wait a moment then reset to idle state
        await Future.delayed(const Duration(milliseconds: 1500));

        if (state is ReceiptScanState) {
          emit((state as ReceiptScanState).copyWith(
            photoPath: null,
            cameraPreviewState: CameraPreviewState.idle,
            // Keep the error
          ));
        }
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
        error: null,
      ));
    }
  }

  void _handleDismissError(
    DismissErrorEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) {
    if (state is ReceiptScanState) {
      final scanState = state as ReceiptScanState;
      emit(scanState.copyWith(error: null));
    }
  }

  Future<void> _handleSetFocusPoint(
    SetFocusPointEvent event,
    Emitter<BaseReceiptScanState> emit,
  ) async {
    if (state is ReceiptScanState) {
      try {
        await _cameraService.setFocusPoint(event.point.dx, event.point.dy);
      } catch (e, stackTrace) {
        _errorLogger.e(
          'Failed to set focus point',
          error: e,
          stackTrace: stackTrace,
        );
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
        cameraPreviewState: CameraPreviewState.photoProcessing,
        error: null, // Clear any errors when taking a new photo
      ));

      try {
        await Vibration.vibrate(duration: 50);

        final imagePath = await _cameraService.takePhoto();
        emit(scanState.copyWith(
          cameraPreviewState: CameraPreviewState.photoPreview,
          photoPath: imagePath,
        ));
      } catch (e, stackTrace) {
        _errorLogger.e(
          'Failed to take photo',
          error: e,
          stackTrace: stackTrace,
        );

        emit(scanState.copyWith(
          cameraPreviewState: CameraPreviewState.cameraPreview,
          error: AppError.fromException(
            e,
            onRetry: () => add(TakePhotoEvent()),
          ),
        ));
      }
    }
  }
}
