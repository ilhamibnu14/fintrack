// lib/features/navigation/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:fintrack/features/dashboard/screens/dashboard_screen.dart';
import 'package:fintrack/features/profile/screens/profile_screen.dart';
import 'package:fintrack/features/transactions/screens/add_transaction_screen.dart';
import 'package:fintrack/features/transactions/screens/all_transactions_screen.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:fintrack/app/utils/constants.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),       // Index 0 (Home)
    const AllTransactionsScreen(), // Index 1 (Laporan)
    const ProfileScreen(),         // Index 2 (Profile)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // --- PERBAIKAN DI SINI ---
      // Jika _selectedIndex adalah 2 (halaman Profile), tombol menjadi null (hilang).
      // Jika bukan 2 (Home atau Laporan), tombol ditampilkan.
      floatingActionButton: _selectedIndex == 2 
          ? null 
          : FloatingActionButton(
              onPressed: _navigateToAddTransaction,
              backgroundColor: kAccentColor,
              foregroundColor: Colors.white,
              child: const Icon(LucideIcons.plus),
            ),
      // -------------------------

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.list),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor:
            Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
            Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
      ),
    );
  }
}