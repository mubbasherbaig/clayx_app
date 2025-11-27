import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'token_storage_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final _connectionController = StreamController<bool>.broadcast();
  IO.Socket? _socket;
  final _tokenStorage = TokenStorageService();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final StreamController<Map<String, dynamic>> _sensorDataController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _deviceStatusController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _commandStatusController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get sensorDataStream =>
      _sensorDataController.stream;
  Stream<Map<String, dynamic>> get deviceStatusStream =>
      _deviceStatusController.stream;
  Stream<Map<String, dynamic>> get commandStatusStream =>
      _commandStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // ✅ NEW: Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
        print('[WS] Heartbeat sent');
      }
    });
  }

  // ✅ NEW: Auto-reconnect if disconnected
  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_socket == null || !_socket!.connected) {
        print('[WS] Auto-reconnect triggered');
        await connect();
      }
    });
  }

  Future<void> joinDeviceRooms(List<String> deviceIds) async {
    if (!isConnected) {
      print('[WS] Cannot join rooms - not connected');
      return;
    }

    for (var deviceId in deviceIds) {
      _socket!.emit('join_device_room', {'deviceId': deviceId});
      print('[WS] Joined room for device: $deviceId');
    }
  }

  Future<void> connect() async {
    print('[WS] ========= CONNECT CALLED =========');

    if (_socket != null && _socket!.connected) {
      print('[WS] Already connected');
      return;
    }

    // Disconnect existing socket if any
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null) {
        print('[WS] ❌ No auth token found - CANNOT CONNECT');
        return;
      }

      const serverUrl = 'https://clayx-backend.onrender.com';
      print('[WS] Attempting connection to: $serverUrl');

      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
        'reconnection': true,
        'reconnectionAttempts': 999,  // ✅ Increased
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'timeout': 20000,
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        print('[WS] ✅ Connected successfully');
        _connectionController.add(true);
        _startHeartbeat();  // ✅ Start heartbeat
      });

      _socket!.onDisconnect((_) {
        print('[WS] ❌ Disconnected');
        _connectionController.add(false);
        _heartbeatTimer?.cancel();
      });

      _socket!.onConnectError((data) {
        print('[WS] ❌ Connection error: $data');
        _connectionController.add(false);
      });

      _socket!.onError((data) {
        print('[WS] ❌ Error: $data');
      });

      // ✅ Add pong listener
      _socket!.on('pong', (data) {
        print('[WS] Pong received');
      });

      _socket!.on('sensor_update', (data) {
        print('[WS] Sensor update received: $data');
        _sensorDataController.add(Map<String, dynamic>.from(data));
      });

      _socket!.on('device_status', (data) {
        print('[WS] Device status: $data');
        _deviceStatusController.add(Map<String, dynamic>.from(data));
      });

      _socket!.on('command_status', (data) {
        print('[WS] Command status: $data');
        _commandStatusController.add(Map<String, dynamic>.from(data));
      });

      _socket!.on('command_sent', (data) {
        print('[WS] Command sent: $data');
        _commandStatusController.add(Map<String, dynamic>.from(data));
      });

      _socket!.on('command_error', (data) {
        print('[WS] Command error: $data');
        _commandStatusController.add({'error': true, 'message': data['error']});
      });

      // ✅ Start auto-reconnect timer
      _startReconnectTimer();

    } catch (e) {
      print('[WS] Connection failed: $e');
      _connectionController.add(false);
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      print('[WS] Disconnected manually');
    }
  }

  void sendCommand(String deviceId, String commandType, String commandValue) {
    if (_socket == null || !_socket!.connected) {
      print('[WS] Not connected, cannot send command');
      return;
    }

    print('[WS] Sending command: $commandType = $commandValue to $deviceId');
    _socket!.emit('send_command', {
      'deviceId': deviceId,
      'commandType': commandType,
      'commandValue': commandValue,
    });
  }

  void getSensorData(int plantId) {
    if (_socket == null || !_socket!.connected) {
      print('[WS] Not connected, cannot request sensor data');
      return;
    }

    _socket!.emit('get_sensor_data', {'plantId': plantId});
  }

  void dispose() {
    disconnect();
    _sensorDataController.close();
    _deviceStatusController.close();
    _commandStatusController.close();
    _connectionController.close();
  }
}