import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Watering', 'Fertilizer', 'Sunlight'];

  final List<Map<String, dynamic>> _activities = [
    {
      'type': 'watering',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'title': 'Watered Aloe Vera',
      'time': '7:00 PM',
      'date': 'Yesterday',
    },
    {
      'type': 'fertilizer',
      'icon': Icons.science_outlined,
      'color': Colors.green,
      'title': 'Fertilizer added to Cactus',
      'time': '10:30 AM',
      'date': '2 days ago',
    },
    {
      'type': 'sunlight',
      'icon': Icons.wb_sunny,
      'color': Colors.amber,
      'title': 'Sunlight Boost Activated for All Plants',
      'time': '9:15 AM',
      'date': '5 days ago',
    },
    {
      'type': 'watering',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'title': 'Watered Snake Plant',
      'time': '6:45 PM',
      'date': '1 week ago',
    },
    {
      'type': 'check',
      'icon': Icons.eco,
      'color': AppColors.primaryGreen,
      'title': 'Checked on Fiddle Leaf Fig',
      'time': '3:20 PM',
      'date': '1 week ago',
    },
  ];

  List<Map<String, dynamic>> get _filteredActivities {
    if (_selectedFilter == 'All') return _activities;

    final filterMap = {
      'Watering': 'watering',
      'Fertilizer': 'fertilizer',
      'Sunlight': 'sunlight',
    };

    return _activities.where((activity) {
      return activity['type'] == filterMap[_selectedFilter];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity History',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.dark_mode_outlined,
              color: AppColors.grey,
              size: 22,
            ),
            onPressed: () {
              // Toggle dark mode
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Activity List
          Expanded(
            child: _filteredActivities.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activities yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = _filteredActivities[index];
                return _ActivityItem(
                  icon: activity['icon'],
                  color: activity['color'],
                  title: activity['title'],
                  time: activity['time'],
                  date: activity['date'],
                  isLast: index == _filteredActivities.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  final String date;
  final bool isLast;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    required this.date,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Date
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}