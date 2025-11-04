import 'package:flutter/material.dart';
import 'dart:async';
import '../services/websocket_service.dart';
import '../utils/colors.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PlantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailEnhancedScreenState();
}

class _PlantDetailEnhancedScreenState extends State<PlantDetailScreen> {
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _sensorSubscription;
  late Map<String, dynamic> _currentPlant;

  @override
  void initState() {
    super.initState();
    _currentPlant = Map<String, dynamic>.from(widget.plant);
    _setupSensorListener();
  }

  void _setupSensorListener() {
    _sensorSubscription = _wsService.sensorDataStream.listen((data) {
      if (data['plantId'] == _currentPlant['id']) {
        setState(() {
          final sensorData = Map<String, dynamic>.from(data['data']);
          _currentPlant['temperature'] = sensorData['temperature'];
          _currentPlant['humidity'] = sensorData['humidity'];
          _currentPlant['soil_moisture'] = sensorData['soil_moisture'];
          _currentPlant['water_level'] = sensorData['soil_moisture'];
          _currentPlant['light_level'] = sensorData['light_level'];
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _calculateHealthPercentage() {
    final soilMoisture = _toDouble(_currentPlant['soil_moisture']);
    final temperature = _toDouble(_currentPlant['temperature']);

    int health = 100;
    if (soilMoisture < 30) health -= 20;
    if (temperature < 15 || temperature > 35) health -= 15;

    return health.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final waterLevel = _toDouble(_currentPlant['soil_moisture']);
    final soilMoisture = _toDouble(_currentPlant['soil_moisture']);
    final temperature = _toDouble(_currentPlant['temperature']);
    final lightLevel = _toDouble(_currentPlant['light_level'] ?? '0');
    final sunlightHours = (lightLevel / 1000 * 12).clamp(0, 12);
    final healthPercentage = _calculateHealthPercentage();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentPlant['plant_name'] ?? 'Unknown',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Text('🌱', style: TextStyle(fontSize: 18)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image with Health Indicator
            // Plant Image with Health Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: healthPercentage / 100,
                          strokeWidth: 8,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            healthPercentage > 70 ? AppColors.primaryGreen : Colors.orange,
                          ),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/plants/aloe_vera.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.local_florist,
                                size: 80,
                                color: AppColors.primaryGreen,
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                            ],
                          ),
                          child: Text(
                            '$healthPercentage% Health',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: healthPercentage > 70 ? AppColors.primaryGreen : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        healthPercentage > 70 ? 'Healthy' : 'Needs Care',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plant Metrics Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plant Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.water_drop,
                          iconColor: Colors.blue,
                          label: 'Water Level',
                          value: '${waterLevel.toStringAsFixed(0)}',
                          unit: '%',
                          status: waterLevel > 50 ? 'Good' : 'Low',
                          statusColor: waterLevel > 50 ? AppColors.primaryGreen : Colors.orange,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.wb_sunny,
                          iconColor: Colors.amber,
                          label: 'Sunlight',
                          value: sunlightHours.toStringAsFixed(1),
                          unit: 'hrs/day',
                          status: 'Good',
                          statusColor: AppColors.primaryGreen,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.opacity,
                          iconColor: Colors.brown,
                          label: 'Soil Moisture',
                          value: '${soilMoisture.toStringAsFixed(0)}',
                          unit: '%',
                          status: soilMoisture > 40 ? 'Good' : 'Low',
                          statusColor: soilMoisture > 40 ? AppColors.primaryGreen : Colors.orange,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.thermostat,
                          iconColor: Colors.red,
                          label: 'Temperature',
                          value: '${temperature.toStringAsFixed(0)}',
                          unit: '°C',
                          status: 'Good',
                          statusColor: AppColors.primaryGreen,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Care Timeline Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Care Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TimelineItem(
                    icon: Icons.water_drop,
                    iconColor: Colors.blue,
                    title: 'Watered at 7 PM yesterday',
                    subtitle: 'Sep 25, 7:00 PM',
                    isDark: isDark,
                  ),
                  _TimelineItem(
                    icon: Icons.wb_sunny,
                    iconColor: Colors.amber,
                    title: 'Light boost applied',
                    subtitle: 'Sep 24, 2:30 PM',
                    isDark: isDark,
                  ),
                  _TimelineItem(
                    icon: Icons.science_outlined,
                    iconColor: AppColors.primaryGreen,
                    title: 'Fertilizer due in 3 days',
                    subtitle: 'Sep 29',
                    showArrow: true,
                    isDark: isDark,
                  ),
                  _TimelineItem(
                    icon: Icons.warning_amber,
                    iconColor: Colors.orange,
                    title: 'Soil moisture dropping',
                    subtitle: 'Sep 25, 8:15 AM',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }
  bool _isPumpOn = false;
  Widget _buildBottomButtons() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final deviceId = _currentPlant['device_id_string']?.toString() ??
                    _currentPlant['device_id']?.toString() ?? '';

                setState(() {
                  _isPumpOn = !_isPumpOn; // Toggle state
                });

                final command = _isPumpOn ? 'on' : 'off';
                _wsService.sendCommand(deviceId, 'pump', command);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isPumpOn ? 'Watering started!' : 'Watering stopped!'),
                    backgroundColor: _isPumpOn ? AppColors.primaryGreen : Colors.blue,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPumpOn ? AppColors.primaryGreen : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                elevation: 2,
                shadowColor: Colors.black26,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPumpOn ? Icons.water_drop : Icons.water_drop_outlined,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Water Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ────── Fertilize (unchanged) ──────
          Expanded(
            child: _GrayActionButton(
              icon: Icons.science_outlined,
              label: 'Fertilize',
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fertilize reminder set!')),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // ────── Light Boost (unchanged) ──────
          Expanded(
            child: _GrayActionButton(
              icon: Icons.wb_sunny,
              label: 'Light Boost',
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Light boost activated!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: (isDark ? Colors.grey.shade400 : AppColors.grey).withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.black,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: (isDark ? Colors.grey.shade400 : AppColors.grey).withOpacity(0.8),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool showArrow;
  final bool isDark;

  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.showArrow = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: (isDark ? Colors.grey.shade400 : AppColors.grey).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }
}

class _GrayActionButton extends StatelessWidget {
  const _GrayActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      elevation: isDark ? 0 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}