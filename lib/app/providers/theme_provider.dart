// lib/app/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeProvider extends ChangeNotifier {
  // Secara default, kita gunakan tema sistem (bisa terang/gelap)
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Cek apakah mode gelap sedang aktif (termasuk mode gelap sistem)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Dapatkan brightness dari sistem HP
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  // Fungsi untuk mengganti tema
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Beri tahu semua widget yang mendengarkan
  }
}