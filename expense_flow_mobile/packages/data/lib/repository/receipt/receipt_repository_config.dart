import '../../consts/receipt_constants.dart';

class RepositoryConfig {
  final String baseUrl;
  final String apiKey;
  final Duration timeout;

  const RepositoryConfig({
    required this.baseUrl,
    required this.apiKey,
    this.timeout = ReceiptConstants.defaultTimeout,
  });
}
