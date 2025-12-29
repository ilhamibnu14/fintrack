// lib/features/profile/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/app/providers/theme_provider.dart';
import 'package:fintrack/app/utils/constants.dart';
import 'package:fintrack/core/services/auth_service.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/features/profile/screens/about_screen.dart';
// --- TAMBAHKAN IMPORT INI ---
import 'package:fintrack/features/profile/screens/account_settings_screen.dart';
import 'package:fintrack/features/profile/screens/security_settings_screen.dart';
// -----------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          return const Center(child: Text("Anda tidak login."));
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ... (Judul, _buildProfileHeader, Pengaturan Akun) ...
              Text(
                "Profil Pengguna",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildProfileHeader(
                context,
                currentUser.displayName ?? "Tanpa Nama",
                currentUser.email ?? "Tanpa Email",
                currentUser.photoURL,
              ),
              const SizedBox(height: 30),
              _buildProfileMenuItem(
                context,
                icon: LucideIcons.settings,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  ).then((_) {
                    (context as Element).reassemble();
                  });
                },
              ),

              // --- PERBAIKAN DI SINI ---
              _buildProfileMenuItem(
                context,
                icon: LucideIcons.shield,
                title: 'Keamanan',
                onTap: () {
                  // Arahkan ke halaman Keamanan
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecuritySettingsScreen(),
                    ),
                  );
                },
              ),
              // --- AKHIR PERBAIKAN ---

              SwitchListTile(
                // ... (Kode SwitchListTile tetap sama)
                title: const Text("Mode Gelap", style: TextStyle(fontSize: 16)),
                secondary: Icon(
                  themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                  color: Theme.of(context).colorScheme.primary,
                ),
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                },
              ),
              _buildProfileMenuItem(
                context,
                icon: LucideIcons.info,
                title: 'Tentang Aplikasi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 40),
              _buildLogoutButton(context),
            ],
          ),
        );
      },
    );
  }

  // ... (Sisa kode _buildProfileHeader, _buildProfileMenuItem, _buildLogoutButton 
  // SAMA PERSIS seperti sebelumnya)
  
  Widget _buildProfileHeader(
      BuildContext context, String name, String email, String? photoUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.surface,
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
              ? NetworkImage(photoUrl)
              : null,
          child: (photoUrl == null || photoUrl.isEmpty)
              ? Icon(
                  LucideIcons.user,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(LucideIcons.chevronRight, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: OutlinedButton.icon(
        icon: const Icon(LucideIcons.logOut, color: kExpenseColor),
        label: const Text(
          "LOGOUT",
          style: TextStyle(color: kExpenseColor, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kExpenseColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Konfirmasi Logout"),
              content: const Text("Apakah Anda yakin ingin keluar?"),
              actions: [
                TextButton(
                  child: const Text("Batal"),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                TextButton(
                  child: const Text("Logout",
                      style: TextStyle(color: kExpenseColor)),
                  onPressed: () {
                    Navigator.of(ctx).pop(); 
                    AuthService().signOut();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}