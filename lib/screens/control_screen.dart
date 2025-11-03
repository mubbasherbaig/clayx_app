import 'package:clayx_smart_planter/screens/plant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final WebSocketService _wsService = WebSocketService();
  final ApiService _apiService = ApiService();
  Map<String, bool> _pumpStates = {};
  List<dynamic> _plants = [];
  bool _isLoading = true;

  StreamSubscription<Map<String, dynamic>>? _commandStatusSubscription;
  StreamSubscription<Map<String, dynamic>>? _sensorSubscription;
  StreamSubscription<Map<String, dynamic>>? _deviceStatusSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isWsConnected = false;

  @override
  void initState() {
    super.initState();
    _loadPlants();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
    });
    _testBackendConnection();
  }

  @override
  void dispose() {
    _commandStatusSubscription?.cancel();
    _sensorSubscription?.cancel();
    _deviceStatusSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _testBackendConnection() async {
    try {
      print('[TEST] Testing backend connection...');
      final response = await http
          .get(Uri.parse('https://clayx-backend.onrender.com'))
          .timeout(const Duration(seconds: 10));

      print('[TEST] Backend status: ${response.statusCode}');
      print('[TEST] Backend reachable: YES');
    } catch (e) {
      print('[TEST] Backend reachable: NO - Error: $e');
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final DateTime dt = DateTime.parse(timestamp.toString());
      final Duration diff = DateTime.now().difference(dt);

      if (diff.inDays > 0)
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      if (diff.inHours > 0)
        return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      if (diff.inMinutes > 0)
        return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _setupListeners() {
    _commandStatusSubscription = _wsService.commandStatusStream.listen((data) {
      print('[CONTROL] Command status: $data');

      if (data['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (data['status'] == 'executed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Command executed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  Future<void> _connectWebSocket() async {
    print('[SCREEN] ========= Connecting WebSocket =========');

    await _wsService.connect();
    print('[SCREEN] WebSocket connect() completed');

    await Future.delayed(const Duration(seconds: 2));
    print('[SCREEN] Waited 2 seconds');

    // Listen for connection status
    _connectionSubscription = _wsService.connectionStream.listen((connected) {
      print('[SCREEN] Connection status changed: $connected');
      if (mounted) {
        setState(() => _isWsConnected = connected);

        if (connected && _plants.isNotEmpty) {
          print('[SCREEN] Connected! Joining device rooms...');
          _joinDeviceRooms();
        }
      }
    });

    // Listen for sensor updates
    _sensorSubscription = _wsService.sensorDataStream.listen((data) {
      if (mounted) {
        _handleSensorUpdate(data);
      }
    });

    // Listen for device status
    _deviceStatusSubscription = _wsService.deviceStatusStream.listen((data) {
      if (mounted) {
        _handleDeviceStatus(data);
      }
    });
  }

  Future<void> _joinDeviceRooms() async {
    final deviceIds =
        _plants
            .where(
              (p) => p['device_id_string'] != null || p['device_id'] != null,
            )
            .map((p) => (p['device_id_string'] ?? p['device_id']).toString())
            .toSet()
            .toList();

    if (deviceIds.isNotEmpty) {
      await _wsService.joinDeviceRooms(deviceIds);
      print('[CONTROL] Joined ${deviceIds.length} device rooms');
    }
  }

  void _handleSensorUpdate(Map<String, dynamic> data) {
    print('[CONTROL] Real-time sensor update: $data');

    final plantId = data['plantId'];
    final sensorData = data['data'];

    if (plantId == null || sensorData == null) return;

    // Properly cast the data
    final Map<String, dynamic> sensorMap = Map<String, dynamic>.from(
      sensorData,
    );

    setState(() {
      final index = _plants.indexWhere((p) => p['id'] == plantId);
      if (index != -1) {
        print('[CONTROL] Updating plant ${_plants[index]['plant_name']}');

        final Map<String, dynamic> currentPlant = Map<String, dynamic>.from(
          _plants[index],
        );

        _plants[index] = {
          ...currentPlant,
          'temperature': sensorMap['temperature'],
          'humidity': sensorMap['humidity'],
          'soil_moisture': sensorMap['soil_moisture'],
          'water_level': sensorMap['water_level'],
          'light_level': sensorMap['light_level'],
          'is_online': true,
          'last_seen': DateTime.now().toIso8601String(),
        };
      }
    });
  }

  void _handleDeviceStatus(Map<String, dynamic> data) {
    print('[CONTROL] Device status update: $data');

    final deviceId = data['deviceId'];
    final isOnline = data['isOnline'] ?? false;
    final lastSeen = data['lastSeen'];

    setState(() {
      for (var plant in _plants) {
        final plantDeviceId =
            plant['device_id_string']?.toString() ??
            plant['device_id']?.toString();

        if (plantDeviceId == deviceId) {
          plant['is_online'] = isOnline;
          if (lastSeen != null) {
            plant['last_seen'] = lastSeen;
          }
          print(
            '[CONTROL] Device $deviceId is now ${isOnline ? "ONLINE" : "OFFLINE"}',
          );
        }
      }
    });
  }

  Future<void> _loadPlants() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getPlants();
      if (response['success']) {
        setState(() {
          _plants = response['data'] ?? [];

          for (var plant in _plants) {
            plant['is_online'] = false;
          }
        });

        // Join device rooms after loading plants
        if (_isWsConnected && _plants.isNotEmpty) {
          await _joinDeviceRooms();
        }
      }
    } catch (e) {
      print('Error loading plants: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sendPumpCommand(String deviceId, bool turnOn) {
    print(
      '[CONTROL] Sending pump ${turnOn ? "ON" : "OFF"} to device: $deviceId',
    );

    // ✅ FIXED: Actually send the command via WebSocket
    _wsService.sendCommand(deviceId, 'pump', turnOn ? 'on' : 'off');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pump ${turnOn ? "ON" : "OFF"} command sent'),
        backgroundColor: turnOn ? AppColors.primaryGreen : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Device Control',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Connection status with label
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _isWsConnected
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isWsConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isWsConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isWsConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isWsConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _plants.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadPlants,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plants.length,
                  itemBuilder: (context, index) {
                    return _buildPlantControlCard(_plants[index]);
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: AppColors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No plants found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a plant to control devices',
            style: TextStyle(color: AppColors.grey.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantControlCard(Map<String, dynamic> plant) {
    final isOnline = plant['is_online'] ?? false;
    final soilMoisture = _toDouble(plant['soil_moisture']);
    final humidity = _toDouble(plant['humidity']);
    final lastSeen = plant['last_seen'];

    // ✅ FIXED: Get deviceId properly (try both fields)
    final deviceId =
        plant['device_id_string']?.toString() ??
        plant['device_id']?.toString() ??
        '';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailScreen(plant: plant),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Plant info + Switch
            Row(
              children: [
                // Plant Image with Green Dot
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_florist,
                        color: AppColors.primaryGreen,
                        size: 32,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Plant Name and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant['plant_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 14,
                          color: isOnline ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Water Switch with Label
                Column(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: _pumpStates[deviceId] ?? false,
                        onChanged:
                            isOnline && deviceId.isNotEmpty
                                ? (bool value) {
                                  // ✅ FIXED: Update state AND send command
                                  setState(() {
                                    _pumpStates[deviceId] = value;
                                  });

                                  // ✅ FIXED: Actually send the command
                                  _sendPumpCommand(deviceId, value);
                                }
                                : null,
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.primaryGreen,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    const Text(
                      'Water',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),

            // Bottom Row: Controls and Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Control Icons
                _buildIconMetric(Icons.wb_sunny, 'Light'),
                const SizedBox(width: 20),
                _buildIconMetric(Icons.water_drop, 'Humidity'),

                const Spacer(),

                // Time and Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getTimeAgo(lastSeen),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 100,
                            height: 8,
                            child: LinearProgressIndicator(
                              value: soilMoisture / 100,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                soilMoisture > 60
                                    ? AppColors.primaryGreen
                                    : soilMoisture > 30
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${soilMoisture.toStringAsFixed(0)} %',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconMetric(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.grey, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.grey),
        ),
      ],
    );
  }
}
