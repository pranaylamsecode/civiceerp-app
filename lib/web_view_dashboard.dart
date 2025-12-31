//Optimized InAppWebView with built-in pull-to-refresh, advanced caching, and better performance

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:dakshin_pashchim/services/download_service.dart';
import 'package:dakshin_pashchim/services/logger_service.dart';
import 'package:dakshin_pashchim/services/connectivity_service.dart';
import 'package:dakshin_pashchim/widgets/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:file_picker/file_picker.dart';

class WebViewDashboard extends StatefulWidget {
  const WebViewDashboard({super.key});

  static final ValueNotifier<bool> webviewReady = ValueNotifier<bool>(false);

  @override
  State<WebViewDashboard> createState() => _WebViewDashboardState();
}

class _WebViewDashboardState extends State<WebViewDashboard> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;

  bool isLoading = false;
  double _progress = 0;
  bool hasUnreadMessage = false;
  bool _isConnected = true;


  final String loginUrl = "https://dash.kollecta.com";

  @override
  void initState() {
    super.initState();

    // Monitor connectivity
    ConnectivityService().isConnected.addListener(_onConnectivityChanged);
    _isConnected = ConnectivityService().isConnected.value;

    // Initialize pull-to-refresh controller (mobile only)
    if (!kIsWeb) {
      _pullToRefreshController = PullToRefreshController(
        settings: PullToRefreshSettings(
          color: const Color(0xFFEA580C),
        ),
        onRefresh: () async {
          if (_controller != null) {
            await _controller!.reload();
          }
        },
      );
    }

    // Foreground FCM (mobile only)
    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        LoggerService().info("📩 Foreground Notification: ${message.notification?.title}");

        if (mounted) {
          setState(() {
            hasUnreadMessage = true;
          });
        }

        if (message.notification != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${message.notification!.title}\n${message.notification!.body}",
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });

      _setupFCM();
    }

    
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    setState(() {
      _isConnected = ConnectivityService().isConnected.value;
    });

    if (_isConnected && _controller != null) {
      _controller!.reload();
    }
  }

  void _setupFCM() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      LoggerService().info("🔄 FCM Token refreshed");
      _injectFCMToken(newToken);
    });
  }

  void _injectFCMToken(String token) {
    if (_controller != null) {
      final js = "if(window.updateFcmTokenFromNative){ window.updateFcmTokenFromNative('$token'); }";
      _controller!.evaluateJavascript(source: js);
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final base64Data = base64Encode(await file.readAsBytes());

      String mime = "application/octet-stream";
      if (fileName.endsWith(".jpg")) mime = "image/jpeg";
      if (fileName.endsWith(".jpeg")) mime = "image/jpeg";
      if (fileName.endsWith(".png")) mime = "image/png";
      if (fileName.endsWith(".pdf")) mime = "application/pdf";

      final js = "handleAndroidFile('$base64Data','$fileName','$mime')";
      _controller?.evaluateJavascript(source: js);

      LoggerService().info("✔ File sent to WebView: $fileName");
    } catch (e, st) {
      LoggerService().error("❌ FilePicker error", e, st);
    }
  }


  @override
  void dispose() {
    ConnectivityService().isConnected.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return OfflineScreen(
        onRetry: () async {
          final connected = await ConnectivityService().checkConnection();
          if (connected && mounted) {
            setState(() => _isConnected = true);
            _controller?.reload();
          }
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_controller != null && await _controller!.canGoBack()) {
          _controller!.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: null,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(loginUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: false,
            mediaPlaybackRequiresUserGesture: false,
            cacheEnabled: true,
            clearCache: false,
            useHybridComposition: true,
            supportZoom: false,
            builtInZoomControls: false,
            displayZoomControls: false,
            useShouldOverrideUrlLoading: true,
            allowFileAccess: true,
            allowContentAccess: true,
            useOnDownloadStart: true,
            // geolocationEnabled: true,
          ),
          pullToRefreshController: _pullToRefreshController,
          onWebViewCreated: (controller) {
            _controller = controller;

            // Add JavaScript handlers
            controller.addJavaScriptHandler(
              handlerName: 'FilePicker',
              callback: (args) {
                LoggerService().debug("📁 FilePicker event");
                if (args.isNotEmpty && args[0] == "open") {
                  _pickAndSendFile();
                }
              },
            );

            controller.addJavaScriptHandler(
              handlerName: 'DownloadFile',
              callback: (args) {
                if (args.isNotEmpty) {
                  LoggerService().debug("⬇ Download request: ${args[0]}");
                  DownloadService.downloadFile(args[0].toString());
                }
              },
            );

            WebViewDashboard.webviewReady.value = true;
          },
          onDownloadStartRequest: (controller, downloadStartRequest) async {
             LoggerService().info("⬇ Web Download request: ${downloadStartRequest.url}");
             await DownloadService.downloadFile(downloadStartRequest.url.toString());
          },
          // onGeolocationPermissionsShowPrompt: (controller, origin) async {
          //   return GeolocationPermissionShowPromptResponse(
          //       origin: origin, allow: true, retain: true);
          // },
          onLoadStart: (controller, url) {
            if (mounted) setState(() => isLoading = true);
            _pullToRefreshController?.endRefreshing();
          },
          onLoadStop: (controller, url) async {
            if (mounted) setState(() => isLoading = false);
            _pullToRefreshController?.endRefreshing();

            final urlString = url.toString();
            LoggerService().debug("🌍 Page Loaded: $urlString");

            // Inject FCM token (mobile only)
            if (!kIsWeb) {
              String? token = await FirebaseMessaging.instance.getToken();
              if (token != null) {
                _injectFCMToken(token);
              }
            }

            // No tab handling needed - fullscreen webview only
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url.toString();
            LoggerService().debug("🌐 URL Requested: $url");

            // Check for downloadable files
            final isDownloadable = url.toLowerCase().endsWith(".pdf") ||
                url.toLowerCase().endsWith(".xlsx") ||
                url.toLowerCase().endsWith(".xls") ||
                url.toLowerCase().endsWith(".csv") ||
                url.toLowerCase().endsWith(".zip") ||
                url.toLowerCase().endsWith(".docx") ||
                url.toLowerCase().endsWith(".doc") ||
                url.toLowerCase().contains("download");

            if (isDownloadable) {
              LoggerService().info("📥 File detected → starting download");
              DownloadService.downloadFile(url);
              return NavigationActionPolicy.CANCEL;
            }

            // Handle external links
            if (url.startsWith("tel:") ||
                url.startsWith("whatsapp:") ||
                url.startsWith("mailto:")) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              return NavigationActionPolicy.CANCEL;
            }

            return NavigationActionPolicy.ALLOW;
          },
          onReceivedError: (controller, request, error) {
            LoggerService().error("WebView Error: ${error.description}");
            _pullToRefreshController?.endRefreshing();
          },
          onProgressChanged: (controller, progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100;
              });
            }
            if (progress == 100) {
              _pullToRefreshController?.endRefreshing();
            }
          },
        ),
        if (isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _progress,
              color: Color(0xFFEA580C),
              backgroundColor: Colors.white,
              minHeight: 3,
            ),
          ),
          // Loading overlay - shows until webview content loads
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/bjp-icon-android12.png',
                      height: 120,
                    ),
                    const SizedBox(height: 30),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFEA580C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
        bottomNavigationBar: null,
      ),
    );
  }
}
