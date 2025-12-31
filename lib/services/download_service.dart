
// // Download service for handling file downloads with retry logic
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:dakshin_pashchim/services/logger_service.dart';

// class DownloadService {
//   static Future<void> init() async {
//     if (kIsWeb) {
//       LoggerService().warning("Download service not available on web");
//       return;
//     }
//     await FlutterDownloader.initialize(
//       debug: true,
//       ignoreSsl: true,
//     );
//     LoggerService().info("Download service initialized");
//   }

//   static Future<void> downloadFile(String url, {int retryCount = 0}) async {
//     if (kIsWeb) {
//       LoggerService().warning("Downloads not supported on web platform");
//       return;
//     }
//     LoggerService().info("⬇ DownloadService → URL: $url");

//     // Fix relative path
//     if (url.startsWith("/")) {
//       url = "https://dash.kollecta.com$url";
//       LoggerService().debug("🔄 Converted → $url");
//     }

//     // Android 13+ Notification permission
//     if (Platform.isAndroid) {
//       await Permission.notification.request();
//     }

//     // ❗ Always use the REAL public download folder
//     Directory downloads = Directory('/storage/emulated/0/Download');

//     // fallback if blocked on some devices
//     if (!await downloads.exists()) {
//       downloads = await getApplicationDocumentsDirectory();
//       LoggerService().warning("Using app directory instead of public Downloads");
//     }

//     final savedDir = downloads.path;
//     LoggerService().info("📁 Saving to: $savedDir");

//     try {
//       final taskId = await FlutterDownloader.enqueue(
//         url: url,
//         savedDir: savedDir,
//         fileName: url.split('/').last,
//         showNotification: true,
//         openFileFromNotification: true,
//         saveInPublicStorage: true,   // ⭐ MUST BE TRUE FOR DOWNLOAD FOLDER
//       );

//       LoggerService().info("📥 Download Task Started: $taskId");
//     } catch (e, stackTrace) {
//       LoggerService().error("Download failed", e, stackTrace);
      
//       // Retry logic (max 2 retries)
//       if (retryCount < 2) {
//         LoggerService().warning("Retrying download... Attempt ${retryCount + 1}");
//         await Future.delayed(Duration(seconds: 2));
//         await downloadFile(url, retryCount: retryCount + 1);
//       }
//     }
//   }
// }




// Download service for handling file downloads with retry logic
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dakshin_pashchim/services/logger_service.dart';

class DownloadService {
  static Future<void> init() async {
    if (kIsWeb) {
      LoggerService().warning("Download service not available on web");
      return;
    }
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true,
    );
    LoggerService().info("Download service initialized");
  }

static Future<void> downloadFile(String url) async {
  if (kIsWeb) return;

  if (url.startsWith("/")) {
    url = "https://dash.kollecta.com$url";
  }

  // Request permissions
  await Permission.notification.request();
  await Permission.storage.request();

  final Directory dir = Directory('/storage/emulated/0/Download');

  if (!await dir.exists()) {
    LoggerService().error("❌ Downloads folder not found");
    return;
  }

  await FlutterDownloader.enqueue(
    url: url,
    savedDir: dir.path,
    fileName: url.split('/').last,
    showNotification: true,
    openFileFromNotification: true,
    saveInPublicStorage: true,
  );
}


}
