import 'package:flutter/material.dart';
import '../utils/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, List<Map<String, dynamic>>> _notifications = {
    'Today': [
      {
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'title': 'Watering Completed',
        'time': '2h ago',
        'isUnread': true,
      },
      {
        'icon': Icons.wb_sunny,
        'color': Colors.amber,
        'title': 'Plant Received Optimal Light',
        'time': '5h ago',
        'isUnread': true,
      },
      {
        'icon': Icons.battery_alert,
        'color': Colors.red,
        'title': 'Low Battery Alert',
        'time': '8h ago',
        'isUnread': false,
      },
    ],
    'Yesterday': [
      {
        'icon': Icons.card_giftcard,
        'color': Colors.purple,
        'title': 'New Reward Available',
        'time': '1d ago',
        'isUnread': true,
      },
      {
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'title': 'Time to Water Your Plant',
        'time': '1d ago',
        'isUnread': false,
      },
    ],
    'This Week': [
      {
        'icon': Icons.warning_amber,
        'color': Colors.red,
        'title': 'Soil Moisture Low',
        'time': '3d ago',
        'isUnread': false,
      },
      {
        'icon': Icons.card_giftcard,
        'color': Colors.purple,
        'title': 'Plant Milestone Achieved',
        'time': '5d ago',
        'isUnread': false,
      },
    ],
    'Earlier': [
      {
        'icon': Icons.wb_sunny,
        'color': Colors.amber,
        'title': 'Plant Needs More Light',
        'time': '8d ago',
        'isUnread': false,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.black),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: ListView(
        children: _notifications.entries.map((entry) {
          return _NotificationSection(
            title: entry.key,
            notifications: entry.value,
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Scroll to top or refresh
          setState(() {});
        },
        backgroundColor: Colors.white,
        elevation: 4,
        child: Icon(
          Icons.dark_mode_outlined,
          color: AppColors.grey,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 20),
              _FilterOption('All Notifications', true),
              _FilterOption('Unread Only', false),
              _FilterOption('Water Reminders', false),
              _FilterOption('Rewards', false),
              _FilterOption('Alerts', false),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> notifications;

  const _NotificationSection({
    required this.title,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade100,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey.withOpacity(0.8),
            ),
          ),
        ),
        ...notifications.map((notification) {
          return _NotificationItem(
            icon: notification['icon'],
            color: notification['color'],
            title: notification['title'],
            time: notification['time'],
            isUnread: notification['isUnread'],
          );
        }).toList(),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  final bool isUnread;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 8),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          // Handle notification tap
        },
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterOption(this.label, this.isSelected);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? AppColors.primaryGreen : AppColors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}