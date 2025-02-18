class HttpConstants {
  static const String apiKeyHeader = 'X-API-Key';
  static const String acceptHeader = 'accept';
  static const String acceptValue = 'application/json';

  static const String contentTypeJpeg = 'image/jpeg';
  static const String contentTypePng = 'image/png';
  static const String contentTypePdf = 'application/pdf';

  static const int statusUnauthorized = 403;
  static const int statusNotFound = 404;
  static const int statusValidationError = 422;
}

class FormDataConstants {
  static const String fileField = 'file';
  static const String llmTypeField = 'llm_type';
}
