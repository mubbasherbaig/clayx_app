import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  final bool showBottomNav;

  const MyPlantsScreen({super.key, this.showBottomNav = true});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  List<dynamic> _plants = [];
  bool _isLoading = true;

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
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _deviceStatusSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    await _wsService.connect();

    // Listen for connection status
    _connectionSubscription = _wsService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() => _isWsConnected = connected);

        if (connected && _plants.isNotEmpty) {
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
    final deviceIds = _plants
        .where((p) => p['device_id_string'] != null || p['device_id'] != null)
        .map((p) => (p['device_id_string'] ?? p['device_id']).toString())
        .toSet()
        .toList();

    if (deviceIds.isNotEmpty) {
      await _wsService.joinDeviceRooms(deviceIds);
      print('[MY_PLANTS] Joined ${deviceIds.length} device rooms');
    }
  }

  void _handleSensorUpdate(Map<String, dynamic> data) {
    print('[MY_PLANTS] Real-time sensor update: $data');

    final plantId = data['plantId'];
    final sensorData = data['data'];

    if (plantId == null || sensorData == null) return;

    final Map<String, dynamic> sensorMap = Map<String, dynamic>.from(sensorData);

    setState(() {
      final index = _plants.indexWhere((p) => p['id'] == plantId);
      if (index != -1) {
        final Map<String, dynamic> currentPlant = Map<String, dynamic>.from(_plants[index]);

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
    print('[MY_PLANTS] Device status update: $data');

    final deviceId = data['deviceId'];
    final isOnline = data['isOnline'] ?? false;
    final lastSeen = data['lastSeen'];

    setState(() {
      for (var plant in _plants) {
        final plantDeviceId = plant['device_id_string']?.toString() ?? plant['device_id']?.toString();

        if (plantDeviceId == deviceId) {
          plant['is_online'] = isOnline;
          if (lastSeen != null) {
            plant['last_seen'] = lastSeen;
          }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load plants: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.showBottomNav,
        leading: widget.showBottomNav
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: const Text(
          'My Plants',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isWsConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isWsConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isWsConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _isWsConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.black),
            onPressed: () {
              // TODO: Implement filtering
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.black),
            onPressed: _loadPlants,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plants.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadPlants,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _plants.length,
          itemBuilder: (context, index) {
            return _PlantCard(
              plant: _plants[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantDetailScreen(
                      plant: Plant.fromJson(_plants[index]),
                    ),
                  ),
                ).then((_) => _loadPlants());
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPlantScreen(),
            ),
          ).then((result) {
            if (result == true) {
              _loadPlants();
            }
          });
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      bottomNavigationBar: widget.showBottomNav ? null : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 100,
            color: AppColors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'No plants yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first plant to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPlantScreen(),
                ),
              ).then((result) {
                if (result == true) {
                  _loadPlants();
                }
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Plant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Plant {
  final int id;
  final String name;
  final bool isOnline;
  final int waterLevel;
  final int humidity;
  final String light;
  final int temperature;
  final IconData image;
  final String deviceId;

  Plant({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.waterLevel,
    required this.humidity,
    required this.light,
    required this.temperature,
    required this.image,
    required this.deviceId,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? 0,
      name: json['plant_name'] ?? 'Unknown',
      isOnline: json['is_online'] ?? false,
      waterLevel: _toInt(json['water_level']),
      humidity: _toInt(json['humidity']),
      light: json['light_level']?.toString() ?? 'Unknown',
      temperature: _toInt(json['temperature']),
      image: Icons.local_florist,
      deviceId: json['device_id']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _PlantCard extends StatelessWidget {
  final Map<String, dynamic> plant;
  final VoidCallback onTap;

  const _PlantCard({
    required this.plant,
    required this.onTap,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final soilMoisture = _toDouble(plant['soil_moisture']);
    final humidity = _toDouble(plant['humidity']);
    final temperature = _toDouble(plant['temperature']);
    final waterLevel = _toDouble(plant['water_level']);
    final lightLevel = plant['light_level']?.toString() ?? 'Unknown';
    final isOnline = plant['is_online'] ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
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
            // Header
            Row(
              children: [
                // Plant Image
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_florist, color: AppColors.primaryGreen, size: 28),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Plant Name and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant['plant_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: AppColors.grey.withOpacity(0.5),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricItem(
                  icon: Icons.opacity,
                  label: 'Soil',
                  value: '${soilMoisture.toStringAsFixed(1)}%',
                  color: Colors.brown,
                ),
                _MetricItem(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${humidity.toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
                _MetricItem(
                  icon: Icons.light_mode,
                  label: 'Light',
                  value: lightLevel,
                  color: Colors.amber,
                ),
                _MetricItem(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: '${temperature.toStringAsFixed(1)}°C',
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.grey.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}