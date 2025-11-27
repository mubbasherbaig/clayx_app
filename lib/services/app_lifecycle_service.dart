// lib/services/app_lifecycle_service.dart
import 'package:flutter/material.dart';
import 'websocket_service.dart';

class AppLifecycleService with WidgetsBindingObserver {
  final WebSocketService _wsService = WebSocketService();

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    print('[LIFECYCLE] Service initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[LIFECYCLE] State changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
      // App came to foreground - reconnect WebSocket
        print('[LIFECYCLE] App RESUMED - Reconnecting WebSocket');
        _reconnectWebSocket();
        break;

      case AppLifecycleState.paused:
      // App went to background - keep connection alive
        print('[LIFECYCLE] App PAUSED - Maintaining connection');
        break;

      case AppLifecycleState.inactive:
        print('[LIFECYCLE] App INACTIVE');
        break;

      case AppLifecycleState.detached:
        print('[LIFECYCLE] App DETACHED');
        _wsService.disconnect();
        break;

      default:
        break;
    }
  }

  Future<void> _reconnectWebSocket() async {
    if (!_wsService.isConnected) {
      print('[LIFECYCLE] WebSocket disconnected, reconnecting...');
      await _wsService.connect();
    } else {
      print('[LIFECYCLE] WebSocket already connected');
    }
  }
}