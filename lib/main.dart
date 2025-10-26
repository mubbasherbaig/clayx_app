import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';

void main() {
  runApp(const ClayxApp());
}

class ClayxApp extends StatelessWidget {
  const ClayxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clayx Smart Planter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}