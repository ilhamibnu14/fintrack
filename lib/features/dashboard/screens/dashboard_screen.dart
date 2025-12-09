// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/app/utils/constants.dart';
import 'package:fintrack/core/models/transaction_model.dart';
import 'package:fintrack/core/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
// Hapus import 'all_transactions_screen.dart' karena tidak lagi dipakai di sini

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN 1: HAPUS SCAFFOLD & APPBAR ---
    // Widget terluar sekarang adalah SafeArea
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<TransactionModel>>(
        stream: _firestoreService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada transaksi."));
          }

          List<TransactionModel> transactions =
              snapshot.data!.docs.map((doc) => doc.data()).toList();

          double totalIncome = 0;
          double totalExpense = 0;
          Map<String, double> categoryExpense = {};

          for (var trx in transactions) {
            if (trx.type == 'income') {
              totalIncome += trx.amount;
            } else {
              totalExpense += trx.amount;
              categoryExpense.update(
                  trx.category, (value) => value + trx.amount,
                  ifAbsent: () => trx.amount);
            }
          }
          double balance = totalIncome - totalExpense;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Judul Manual
              Text(
                "Dashboard FinTrack",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildSummaryCard(totalIncome, totalExpense, balance),
              const SizedBox(height: 24),
              Text("Pengeluaran per Kategori",
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                // Pastikan data yang dikirim tidak kosong
                child: categoryExpense.isEmpty
                    ? const Center(child: Text("Belum ada pengeluaran."))
                    : _buildPieChart(categoryExpense),
              ),
              const SizedBox(height: 24),
              // Judul "Transaksi Terbaru" (tanpa tombol "Lihat Semua")
              Text("Transaksi Terbaru",
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              _buildRecentTransactions(transactions),
            ],
          );
        },
      ),
    );
    // --- AKHIR PERBAIKAN 1 ---
  }

  // ... (Widget _buildSummaryCard dan _buildIncomeExpense sama persis)
  
  Widget _buildSummaryCard(
      double income, double expense, double balance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Total Saldo",
                style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            Text(
              _currencyFormat.format(balance),
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color ?? kPrimaryColor),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIncomeExpense("Pemasukan", income, kIncomeColor),
                _buildIncomeExpense("Pengeluaran", expense, kExpenseColor),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpense(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  // ... (Widget _buildPieChart sama)
  Widget _buildPieChart(Map<String, double> categoryData) {
    List<PieChartSectionData> sections = categoryData.entries.map((entry) {
      return PieChartSectionData(
        // --- PERBAIKAN 2: PANGGIL FUNGSI WARNA BARU ---
        color: _getColorForCategory(entry.key),
        value: entry.value,
        title: entry.key,
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  // --- PERBAIKAN 2: FUNGSI WARNA BARU ---
  Color _getColorForCategory(String category) {
    // Pengecekan khusus untuk kategori pengeluaran umum
    switch (category.toLowerCase()) {
      case 'makanan':
        return Colors.redAccent; // (Merah)
      case 'transportasi':
        return Colors.blueAccent; // (Biru)
      case 'belanja':
        return Colors.purpleAccent; // (Ungu)
      case 'tagihan':
        return Colors.teal; // (Teal/Hijau Tua)
      case 'hiburan':
        return Colors.indigo; // (Indigo/Biru Tua)

      // Untuk 'Lainnya' dan kategori kustom lainnya
      default:
        // Ambil hash code dari string kategori
        final hash = category.hashCode;
        // Gunakan modulo 360 untuk mendapatkan nilai Hue (0-360)
        final hue = (hash % 360).toDouble();
        // Buat warna dari HSL (Hue, Saturation, Lightness)
        // Ini memastikan warnanya selalu cerah dan berbeda
        return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
    }
  }
  // --- AKHIR PERBAIKAN 2 ---

  // ... (Widget _buildRecentTransactions sama persis)
  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    final recent = transactions.take(5).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final trx = recent[index];
        bool isExpense = trx.type == 'expense';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isExpense ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              color: isExpense ? kExpenseColor : kIncomeColor,
            ),
            title: Text(trx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(trx.note),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${isExpense ? '-' : '+'} ${_currencyFormat.format(trx.amount)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpense ? kExpenseColor : kIncomeColor,
                  ),
                ),
                Text(DateFormat('dd MMM yyyy').format(trx.date), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}