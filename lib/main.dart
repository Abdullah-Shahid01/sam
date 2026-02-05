// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'config/theme.dart';
import 'screens/dashboard_screen.dart';

// Conditional import for platform-specific setup
import 'platform_setup.dart' if (dart.library.html) 'platform_setup_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializePlatform();
  
  runApp(const SAMApp());
}

class SAMApp extends StatelessWidget {
  const SAMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}