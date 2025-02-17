class ServerException implements Exception {
  final String message;

  ServerException(this.message);
}

class UnauthorizedException implements Exception {}

class NotFoundException implements Exception {}

class ValidationException implements Exception {
  final List<Map<String, dynamic>> details;

  ValidationException(this.details);
}
