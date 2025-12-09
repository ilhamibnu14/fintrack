// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fintrack/app/providers/theme_provider.dart'; // <-- Import
import 'package:fintrack/app/theme/app_theme.dart';
import 'package:fintrack/widgets/auth_gate.dart';
import 'package:provider/provider.dart'; // <-- Import
import 'firebase_options.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Bungkus aplikasi dengan provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const FinTrackApp(),
    ),
  );
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan tema dari provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'FinTrack',
      theme: AppTheme.lightTheme,      // <-- Tema terang
      darkTheme: AppTheme.darkTheme,  // <-- Tema gelap
      themeMode: themeProvider.themeMode, // <-- Ambil mode dari provider
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}