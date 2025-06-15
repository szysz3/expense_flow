import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'flavor_config.dart';

class EnvConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  static String get webSocketUrl => dotenv.env['CHAT_WEBSOCKET_URL'] ?? '';

  static Future<void> load() async {
    String envFile = _getEnvFile();
    await dotenv.load(fileName: envFile);
  }

  static String _getEnvFile() {
    switch (FlavorConfig.appFlavor) {
      case Flavor.prod:
        return '.env.prod';
      case Flavor.demo:
        return '.env.demo';
      case null:
        throw Exception(
            'Flavor not initialized. App must be started with either prod or demo flavor.');
    }
  }

  static bool validate() {
    final missing = <String>[];

    if (baseUrl.isEmpty) missing.add('API_BASE_URL');
    if (apiKey.isEmpty) missing.add('API_KEY');
    if (webSocketUrl.isEmpty) missing.add('CHAT_WEBSOCKET_URL');

    if (missing.isNotEmpty) {
      throw Exception(
          'Missing required environment variables for ${FlavorConfig.name} flavor: ${missing.join(', ')}');
    }

    return true;
  }
}
