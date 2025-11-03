import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/websocket_service.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import 'add_plant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  List<dynamic> _plants = [];
  bool _isLoading = true;
  String _userName = 'User';
  int _selectedPlantIndex = 0;
  bool _isDarkMode = false;

  StreamSubscription<Map<String, dynamic>>? _sensorSubscription;
  StreamSubscription<Map<String, dynamic>>? _deviceStatusSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isWsConnected = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
    });
    _testBackendConnection();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel(); // NEW
    _deviceStatusSubscription?.cancel(); // NEW
    super.dispose();
  }

  Future<void> _testBackendConnection() async {
    try {
      print('[TEST] Testing backend connection...');
      final response = await http.get(
        Uri.parse('https://clayx-backend.onrender.com'),
      ).timeout(const Duration(seconds: 10));

      print('[TEST] Backend status: ${response.statusCode}');
      print('[TEST] Backend reachable: YES');
    } catch (e) {
      print('[TEST] Backend reachable: NO - Error: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    print('[SCREEN] ========= Connecting WebSocket =========');

    await _wsService.connect();
    print('[SCREEN] WebSocket connect() completed');

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
            .where((p) => p['device_id_string'] != null)
            .map((p) => p['device_id_string'] as String)
            .toSet()
            .toList();

    if (deviceIds.isNotEmpty) {
      await _wsService.joinDeviceRooms(deviceIds);
      print('[Dashboard] Joined ${deviceIds.length} device rooms');
    }
  }

  void _handleSensorUpdate(Map<String, dynamic> data) {
    print('[Dashboard] Real-time sensor update: $data');

    final plantId = data['plantId'];
    final sensorData = data['data'];

    if (plantId == null || sensorData == null) {
      print('[Dashboard] Invalid sensor update data');
      return;
    }

    // Properly cast the data
    final Map<String, dynamic> sensorMap = Map<String, dynamic>.from(
      sensorData,
    );

    // Find and update the plant
    setState(() {
      final index = _plants.indexWhere((p) => p['id'] == plantId);
      if (index != -1) {
        print('[Dashboard] Updating plant ${_plants[index]['plant_name']}');

        // Create a new map with proper typing
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
    print('[Dashboard] Device status update: $data');

    final deviceId = data['deviceId'];
    final isOnline = data['isOnline'] ?? false;
    final lastSeen = data['lastSeen'];

    setState(() {
      for (var plant in _plants) {
        if (plant['device_id_string'] == deviceId) {
          plant['is_online'] = isOnline;
          if (lastSeen != null) {
            plant['last_seen'] = lastSeen;
          }
          print(
            '[Dashboard] Device $deviceId is now ${isOnline ? "ONLINE" : "OFFLINE"}',
          );
        }
      }
    });
  }

  // NEW: Setup WebSocket listeners
  void _setupWebSocketListeners() {
    // Listen for sensor updates
    _sensorSubscription = _wsService.sensorDataStream.listen((data) {
      print('[DASHBOARD] Sensor update received: $data');
      _updatePlantSensorData(data);
    });

    // Listen for device status changes
    _deviceStatusSubscription = _wsService.deviceStatusStream.listen((data) {
      print('[DASHBOARD] Device status: $data');
      _updateDeviceStatus(data);
    });
  }

  // NEW: Update plant sensor data from WebSocket
  void _updatePlantSensorData(Map<String, dynamic> data) {
    if (!mounted) return;

    final plantId = data['plantId'];
    final sensorData = data['data'];

    setState(() {
      for (var i = 0; i < _plants.length; i++) {
        if (_plants[i]['id'] == plantId) {
          _plants[i]['temperature'] = sensorData['temperature'];
          _plants[i]['humidity'] = sensorData['humidity'];
          _plants[i]['soil_moisture'] = sensorData['soil_moisture'];
          _plants[i]['water_level'] = sensorData['water_level'];
          _plants[i]['light_level'] = sensorData['light_level'];
          break;
        }
      }
    });
  }

  // NEW: Update device online status
  void _updateDeviceStatus(Map<String, dynamic> data) {
    if (!mounted) return;

    final deviceId = data['deviceId'];
    final isOnline = data['isOnline'];

    setState(() {
      for (var plant in _plants) {
        if (plant['device_id'] == deviceId) {
          plant['is_online'] = isOnline;
        }
      }
    });
  }

  // Load initial data (only once, then WebSocket handles updates)
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Get user profile
      final profileResponse = await _apiService.getProfile();
      if (profileResponse['success']) {
        setState(() {
          _userName =
              profileResponse['data']['fullName']?.split(' ')[0] ?? 'User';
        });
      }

      // Get plants
      final plantsResponse = await _apiService.getPlants();
      if (plantsResponse['success']) {
        setState(() {
          _plants = plantsResponse['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get user profile
      final profileResponse = await _apiService.getProfile();
      if (profileResponse['success']) {
        setState(() {
          _userName =
              profileResponse['data']['fullName']?.split(' ')[0] ?? 'User';
        });
      }

      // Get plants
      final plantsResponse = await _apiService.getPlants();
      if (plantsResponse['success']) {
        setState(() {
          _plants = plantsResponse['data'] ?? [];

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
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        _buildGreetingSection(),
                        const SizedBox(height: 24),
                        _buildYourPlantsSection(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildAchievements(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and Title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Smart Planter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          // Actions
          Row(
            children: [
              // WebSocket Connection Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _isWsConnected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
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
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: AppColors.grey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _isDarkMode = !_isDarkMode);
                },
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
              children: [
                TextSpan(text: '${_getGreeting()}, '),
                TextSpan(
                  text: _userName.split(' ')[0], // Only first name
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, // Make name bold (optional)
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your plants are looking great today!',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildToggleButton('Show Empty State', false),
              const SizedBox(width: 12),
              _buildToggleButton('Show Plants', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryGreen : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.white : AppColors.grey,
        ),
      ),
    );
  }

  Widget _buildYourPlantsSection() {
    if (_plants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 64,
                  color: AppColors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No plants yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first plant to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Plants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_plants.length, (index) {
                final plant = _plants[index];
                final isSelected = index == _selectedPlantIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedPlantIndex = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primaryGreen
                                : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        plant['plant_name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _buildPlantCard(_plants[_selectedPlantIndex]),
        ],
      ),
    );
  }

  Widget _buildPlantCard(Map<String, dynamic> plant) {
    final soilMoisture = _toDouble(plant['soil_moisture']);
    final temperature = _toDouble(plant['temperature']);
    final waterLevel = _toDouble(plant['water_level']);
    final humidity = _toDouble(plant['humidity']);

    // Fix: Trim and parse light level (handle " 0" format)
    final lightLevelStr = (plant['light_level']?.toString() ?? '0').trim();
    final lightLevel = double.tryParse(lightLevelStr) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_florist,
                  color: AppColors.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
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
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                plant['is_online'] == true
                                    ? Colors.green
                                    : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          plant['is_online'] == true ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                plant['is_online'] == true
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.water_drop,
                  label: 'Water',
                  value: '${soilMoisture.toStringAsFixed(1)}%',
                  color:
                      soilMoisture < 30 ? Colors.red : AppColors.primaryGreen,
                  isWarning: soilMoisture < 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.wb_sunny,
                  label: 'Light',
                  value: _getLightStatusFromValue(lightLevel),
                  color: AppColors.primaryGreen,
                  isWarning: false,
                  showCheck: lightLevel > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.opacity,
                  label: 'Soil',
                  value: '${soilMoisture.toStringAsFixed(1)}%',
                  color: AppColors.primaryGreen,
                  isWarning: soilMoisture < 30,
                  showCheck: soilMoisture > 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: '${temperature.toStringAsFixed(0)}°C',
                  color: AppColors.primaryGreen,
                  isWarning: false,
                  showCheck: true,
                ),
              ),
            ],
          ),
          if (humidity > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.water,
                    label: 'Humidity',
                    value: '${humidity.toStringAsFixed(1)}%',
                    color: AppColors.primaryGreen,
                    isWarning: false,
                    showCheck: true,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Add this helper method
  String _getLightStatusFromValue(double lightLevel) {
    if (lightLevel == 0) return 'Dark';
    if (lightLevel > 1000) return 'Bright';
    if (lightLevel > 500) return 'Medium';
    return 'Low';
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isWarning,
    bool showCheck = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
              const Spacer(),
              if (isWarning)
                const Icon(Icons.warning, color: Colors.red, size: 16)
              else if (showCheck)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.add,
                label: 'Add Plant',
                color: AppColors.primaryGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPlantScreen(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadData(); // Refresh dashboard after adding plant
                    }
                  });
                },
              ),
              _buildActionButton(
                icon: Icons.water_drop,
                label: 'Water Now',
                color: const Color(0xFF3B82F6),
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.wb_sunny,
                label: 'Light Control',
                color: const Color(0xFFFBBF24),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Color(0xFFFBBF24),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reward Points',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              Text(
                                '750 pts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: AppColors.primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plants Saved',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              Text(
                                '${_plants.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Reward: 1000 pts',
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                        Text(
                          '75%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getLightStatus(String lightLevel) {
    final value = double.tryParse(lightLevel) ?? 0;
    if (value > 1000) return 'Good';
    if (value > 500) return 'Medium';
    return 'Low';
  }

  String _getSoilStatus(double moisture) {
    if (moisture > 60) return 'Moist';
    if (moisture > 30) return 'Normal';
    return 'Dry';
  }
}
