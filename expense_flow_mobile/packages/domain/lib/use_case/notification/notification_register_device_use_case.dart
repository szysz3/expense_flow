import 'package:dartz/dartz.dart';

import '../../model/device_platform.dart';
import '../../model/failure/failures.dart';
import '../../repository/notification_repository.dart';
import '../base/base_use_case.dart';

class NotificationRegisterDeviceParams {
  final String token;
  final DevicePlatform platform;

  NotificationRegisterDeviceParams({
    required this.token,
    required this.platform,
  });
}

class NotificationRegisterDeviceUseCase
    implements
        BaseUseCase<NotificationRegisterDeviceParams, Either<Failure, void>> {
  final NotificationRepository repository;

  NotificationRegisterDeviceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
      NotificationRegisterDeviceParams params) async {
    return repository.registerDevice(params.token, params.platform);
  }
}
