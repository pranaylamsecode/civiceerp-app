import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dakshin_pashchim/services/logger_service.dart';

class NotificationService {
  static Future<void> init() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // TOKEN (you can send this to your server)
    String? token = await messaging.getToken();
    LoggerService().info("FCM TOKEN: $token");

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LoggerService().info("FOREGROUND MESSAGE: ${message.notification?.title}");
    });

    // Background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }
}

// Background handler
Future<void> _backgroundHandler(RemoteMessage message) async {
  LoggerService().info("BACKGROUND MESSAGE: ${message.notification?.title}");
}
