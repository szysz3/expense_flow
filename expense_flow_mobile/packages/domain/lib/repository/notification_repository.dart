import 'package:dartz/dartz.dart';

import '../model/device_platform.dart';
import '../model/failure/failures.dart';

abstract class NotificationRepository {
  /// Register device for push notifications
  Future<Either<Failure, void>> registerDevice(
    String token,
    DevicePlatform platform,
  );

  /// Unregister device from push notifications
  Future<Either<Failure, void>> unregisterDevice(String token);
}
