abstract class Failure {
  final String message;

  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure()
      : super('Connection failed. Please check your internet connection.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Unauthorized access');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure() : super('Resource not found');
}

class ValidationFailure extends Failure {
  final List<Map<String, dynamic>> details;

  const ValidationFailure(this.details) : super('Validation failed');
}
