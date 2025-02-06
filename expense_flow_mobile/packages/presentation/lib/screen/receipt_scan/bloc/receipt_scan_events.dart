abstract class ReceiptScanEvent {}

class InitializeCameraEvent extends ReceiptScanEvent {}

class TakePhotoEvent extends ReceiptScanEvent {}

class CameraButtonPressedEvent extends ReceiptScanEvent {}
