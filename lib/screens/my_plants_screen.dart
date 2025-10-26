import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'plant_detail_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final List<Plant> _plants = [
    Plant(
      name: 'Aloe Vera',
      isOnline: true,
      waterLevel: 65,
      humidity: 89,
      light: 'Good',
      temperature: 22,
      image: Icons.local_florist,
    ),
    Plant(
      name: 'Snake Plant',
      isOnline: false,
      waterLevel: 45,
      humidity: 75,
      light: 'Low',
      temperature: 20,
      image: Icons.eco,
    ),
    Plant(
      name: 'Monstera',
      isOnline: true,
      waterLevel: 80,
      humidity: 92,
      light: 'Good',
      temperature: 24,
      image: Icons.spa,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Plants',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plants.length,
        itemBuilder: (context, index) {
          return _PlantCard(
            plant: _plants[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlantDetailScreen(plant: _plants[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add plant screen
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.grey,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Plants'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Location'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class Plant {
  final String name;
  final bool isOnline;
  final int waterLevel;
  final int humidity;
  final String light;
  final int temperature;
  final IconData image;

  Plant({
    required this.name,
    required this.isOnline,
    required this.waterLevel,
    required this.humidity,
    required this.light,
    required this.temperature,
    required this.image,
  });
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _PlantCard({
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(plant.image, color: AppColors.primaryGreen, size: 28),
                ),
                const SizedBox(width: 12),

                // Plant Name
                Expanded(
                  child: Text(
                    plant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),

                // Online Status Toggle
                Switch(
                  value: plant.isOnline,
                  onChanged: (value) {},
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricItem(
                  icon: Icons.water_drop,
                  label: 'Water',
                  value: '${plant.waterLevel}%',
                  color: Colors.blue,
                ),
                _MetricItem(
                  icon: Icons.opacity,
                  label: 'Humidity',
                  value: '${plant.humidity}%',
                  color: Colors.orange,
                ),
                _MetricItem(
                  icon: Icons.light_mode,
                  label: 'Light',
                  value: plant.light,
                  color: Colors.amber,
                ),
                _MetricItem(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: '${plant.temperature}°C',
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