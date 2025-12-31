import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);
  final ValueNotifier<ConnectivityResult> connectionType = 
      ValueNotifier<ConnectivityResult>(ConnectivityResult.wifi);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      isConnected.value = false;
      connectionType.value = ConnectivityResult.none;
      return;
    }

    final result = results.first;
    connectionType.value = result;
    isConnected.value = result != ConnectivityResult.none;
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }

  void dispose() {
    _subscription?.cancel();
    isConnected.dispose();
    connectionType.dispose();
  }
}
