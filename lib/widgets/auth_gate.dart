// lib/widgets/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/features/auth/screens/login_screen.dart';
import 'package:fintrack/features/navigation/main_navigation.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika belum login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Jika sudah login
        return const MainNavigation();
      },
    );
  }
}