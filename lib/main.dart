import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/colors.dart';
import 'services/app_lifecycle_service.dart';  // ✅ ADD THIS

void main() {
  WidgetsFlutterBinding.ensureInitialized();  // ✅ ADD THIS

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ClayxApp(),
    ),
  );
}

class ClayxApp extends StatefulWidget {  // ✅ CHANGE TO StatefulWidget
  const ClayxApp({super.key});

  @override
  State<ClayxApp> createState() => _ClayxAppState();
}

class _ClayxAppState extends State<ClayxApp> {
  final AppLifecycleService _lifecycleService = AppLifecycleService();  // ✅ ADD THIS

  @override
  void initState() {
    super.initState();
    _lifecycleService.initialize();  // ✅ ADD THIS
  }

  @override
  void dispose() {
    _lifecycleService.dispose();  // ✅ ADD THIS
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Clayx Smart Planter',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.dark().textTheme,
            ),
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}