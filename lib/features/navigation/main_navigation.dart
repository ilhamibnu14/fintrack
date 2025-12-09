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

  // --- KEMBALIKAN KE 3 HALAMAN ---
  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),       // Index 0
    const AllTransactionsScreen(), // Index 1
    const ProfileScreen(),       // Index 2
  ];
  // ------------------------------

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
      // BUKAN LAGI resizeToAvoidBottomInset: false
      
      // Body sekarang mengambil halaman dari list
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // --- PERBAIKAN LOKASI FAB ---
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        backgroundColor: kAccentColor,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
      ),
      // Gunakan 'centerFloat' agar mengambang di atas navbar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // ----------------------------

      // --- PERBAIKAN BOTTOMNAVBAR ---
      // Gunakan BottomNavigationBar standar, BUKAN BottomAppBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.list),
            label: 'Laporan', // Label "Laporan" sekarang aman
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Style ini akan mengambil warna dari tema Anda
        selectedItemColor:
            Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
            Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
      ),
      // -------------------------------
    );
  }
}