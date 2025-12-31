

// //for splash screen only

// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:dakshin_pashchim/web_view_dashboard.dart';
// import 'package:dakshin_pashchim/services/download_service.dart';
// import 'package:dakshin_pashchim/services/logger_service.dart';
// import 'package:dakshin_pashchim/services/connectivity_service.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// // 🔥 DOWNLOAD CALLBACK
// void downloadCallback(String id, DownloadTaskStatus status, int progress) {
//   LoggerService().debug('📥 Download Status = $status, Progress = $progress%');
// }

// // ----------------------------------------------------------------------------
// //  FCM BACKGROUND HANDLER
// // ----------------------------------------------------------------------------
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   LoggerService().info("🔥 BACKGROUND NOTIFICATION: ${message.notification?.title}");
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize logger first
//   LoggerService().init(isProduction: false); // Set to true for production

//   try {
//     // Initialize services
//     // Only init download service on mobile (not web)
//     if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
//       await DownloadService.init();
//       await Firebase.initializeApp();
      
//       // Get FCM token
//       String? token = await FirebaseMessaging.instance.getToken();
//       LoggerService().info("FCM Token: $token");

//       await FirebaseMessaging.instance.requestPermission();
//       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     } else {
//       LoggerService().info("Running on web - skipping Firebase and download services");
//     }
    
//     await ConnectivityService().init();

//     runApp(const ProviderScope(child: MyApp()));
//   } catch (e, stackTrace) {
//     LoggerService().error("Failed to initialize app", e, stackTrace);
//     runApp(const ProviderScope(child: MyApp()));
//   }
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const WebViewDashboard(),  // <-- Direct to dashboard
//     );
//   }
// }





import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:dakshin_pashchim/web_view_dashboard.dart';
import 'package:dakshin_pashchim/services/logger_service.dart';
import 'package:dakshin_pashchim/services/connectivity_service.dart';

@pragma('vm:entry-point')
void downloadCallback(
  String id,
  int status,
  int progress,
) {
  LoggerService().debug(
    '📥 Download status=$status progress=$progress%',
  );
}

/// 🔥 FCM background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LoggerService().info("🔥BACKGROUND FCM: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggerService().init(isProduction: false);

  if (!kIsWeb && Platform.isAndroid) {
    // ✅ Initialize downloader
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true,
    );

    // ✅ REGISTER CALLBACK (ONLY ONCE)
    FlutterDownloader.registerCallback(downloadCallback);

    // Firebase
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);
  }

  await ConnectivityService().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewDashboard(),
    );
  }
}
