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

    try {
      final token = await _tokenStorage.getToken();

      if (token != null) {
        print('[WS] Token retrieved: YES (${token.substring(0, 20)}...)');
      } else {
        print('[WS] Token retrieved: NO');
      }

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
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      });

      print('[WS] Socket created, calling connect()...');
      _socket!.connect();

      _socket!.onConnect((_) {
        print('[WS] ✅ Connected successfully');
        _connectionController.add(true);
      });

      _socket!.onDisconnect((_) {
        print('[WS] ❌ Disconnected');
        _connectionController.add(false);
      });

      _socket!.onConnectError((data) {
        print('[WS] ❌ Connection error: $data');
        _connectionController.add(false);
      });

      _socket!.onError((data) {
        print('[WS] ❌ Error: $data');
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
    } catch (e) {
      print('[WS] Connection failed: $e');
    }
  }

  void disconnect() {
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
  }
}