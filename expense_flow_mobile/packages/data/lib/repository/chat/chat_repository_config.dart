class ChatRepositoryConfig {
  final String webSocketUrl;
  final String? apiKey;

  const ChatRepositoryConfig({
    required this.webSocketUrl,
    this.apiKey,
  });
}
