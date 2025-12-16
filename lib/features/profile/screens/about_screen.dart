// lib/features/profile/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
        // --- PERBAIKAN DI SINI ---
        foregroundColor: Colors.white,
        // -------------------------
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  LucideIcons.wallet,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  "FinTrack",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Versi 1.0.0",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Text(
                  "FinTrack adalah aplikasi pengelola keuangan pribadi untuk mahasiswa, dibangun menggunakan Flutter dan Firebase sebagai bagian dari studi Cloud Computing.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Divider(height: 50),
                Text(
                  "Dibuat oleh:",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ilham Ibnu Qalbi. Yk dan Agam Nelzon Ramadhan", // Anda bisa ganti dengan nama lengkap Anda
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
