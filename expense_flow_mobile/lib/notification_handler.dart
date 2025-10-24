import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('[FCM Background] Message: ${message.messageId}');
  debugPrint('[FCM Background] Data: ${message.data}');

  if (message.notification != null) {
    debugPrint('[FCM Background] Title: ${message.notification!.title}');
    debugPrint('[FCM Background] Body: ${message.notification!.body}');
  }
}
