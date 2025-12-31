import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// App State
class AppState {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool isWebViewReady;
  final bool isConnected;
  final ConnectivityResult connectionType;

  AppState({
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.isWebViewReady = false,
    this.isConnected = true,
    this.connectionType = ConnectivityResult.wifi,
  });

  AppState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? isWebViewReady,
    bool? isConnected,
    ConnectivityResult? connectionType,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isWebViewReady: isWebViewReady ?? this.isWebViewReady,
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

// App State Notifier
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? message) {
    state = state.copyWith(hasError: message != null, errorMessage: message);
  }

  void setWebViewReady(bool ready) {
    state = state.copyWith(isWebViewReady: ready);
  }

  void setConnectivity(bool connected, ConnectivityResult type) {
    state = state.copyWith(isConnected: connected, connectionType: type);
  }

  void clearError() {
    state = state.copyWith(hasError: false, errorMessage: null);
  }
}

// Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);
