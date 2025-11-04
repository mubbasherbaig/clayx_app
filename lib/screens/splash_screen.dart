import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    if (mounted) {
      // Check if user has a valid token
      final isLoggedIn = await _apiService.isLoggedIn();

      if (isLoggedIn) {
        // User is logged in, go to main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        // No token, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF2A2A2A)]
                : [AppColors.white, AppColors.backgroundColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icons/nobg_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 30),
            Text(
              'Smart Planter',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Growing smarter together',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? Colors.grey.shade300 : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}