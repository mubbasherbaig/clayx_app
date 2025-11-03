import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import 'control_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PlaceholderScreen(title: 'Scan', icon: Icons.qr_code_scanner),
    const ControlScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
    const PlaceholderScreen(title: 'Rewards', icon: Icons.emoji_events_outlined),
  ];

  void _onItemTapped(int index) async {
    if (index == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );

      // Handle navigation from QR Scanner bottom bar
      if (result != null && result is Map && result['action'] == 'navigate') {
        setState(() => _selectedIndex = result['index']);
      }
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.qr_code_scanner, 'Scan', 1),
              _buildNavItem(Icons.tune, 'Control', 2),
              _buildNavItem(Icons.notifications_outlined, 'Notifications', 3),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
              _buildNavItem(Icons.emoji_events_outlined, 'Rewards', 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primaryGreen : AppColors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Screen',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}