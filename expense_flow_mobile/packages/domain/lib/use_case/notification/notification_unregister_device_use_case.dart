import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../repository/notification_repository.dart';
import '../base/base_use_case.dart';

class NotificationUnregisterDeviceUseCase
    implements BaseUseCase<String, Either<Failure, void>> {
  final NotificationRepository repository;

  NotificationUnregisterDeviceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String token) async {
    return repository.unregisterDevice(token);
  }
}
