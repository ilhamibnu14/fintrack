// lib/features/transactions/screens/all_transactions_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/app/utils/constants.dart';
import 'package:fintrack/core/models/transaction_model.dart';
import 'package:fintrack/core/services/firestore_service.dart';
import 'package:fintrack/features/transactions/screens/edit_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:collection/collection.dart';
import 'package:fintrack/core/services/pdf_export_service.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PdfExportService _pdfExportService = PdfExportService();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<TransactionModel> _currentTransactions = [];
  bool _isExporting = false;

  void _handleExportPdf() async {
    if (_currentTransactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    setState(() => _isExporting = true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mempersiapkan PDF...')),
      );
    }

    try {
      await _pdfExportService.generateAndSharePdf(_currentTransactions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String docId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: kExpenseColor),
              child: const Text('Hapus'),
              onPressed: () {
                _firestoreService.deleteTransaction(docId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageDialog(BuildContext context, String imageUrl) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(8.0),
          content: Stack(
            children: [
              Center(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                        child: Text('Gagal memuat gambar.',
                            textAlign: TextAlign.center));
                  },
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          actionsPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.all(10),
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hari ini';
    } else if (dateOnly == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _currentTransactions = [];
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.search, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Belum ada transaksi.", style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          _currentTransactions =
              snapshot.data!.docs.map((doc) => doc.data()).toList();

          final groupedTransactions = groupBy(
            _currentTransactions,
            (TransactionModel trx) =>
                DateTime(trx.date.year, trx.date.month, trx.date.day),
          );

          List<MapEntry<DateTime, List<TransactionModel>>> sortedGroups =
              groupedTransactions.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Riwayat Transaksi",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_isExporting)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(LucideIcons.share,
                            color: Theme.of(context).colorScheme.primary),
                        onPressed: _handleExportPdf,
                        tooltip: 'Ekspor ke PDF',
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedGroups.length,
                  itemBuilder: (context, index) {
                    final entry = sortedGroups[index];
                    final date = entry.key;
                    final aTransactionsInGroup = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, top: 16.0, bottom: 8.0, right: 16.0),
                          child: Text(
                            _formatDateHeader(date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: aTransactionsInGroup.length,
                          itemBuilder: (context, subIndex) {
                            final trx = aTransactionsInGroup[subIndex];
                            bool isExpense = trx.type == 'expense';
                            bool hasImage = trx.imageUrl != null &&
                                trx.imageUrl!.isNotEmpty;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(
                                    left: 16, right: 8),
                                leading: Icon(
                                  isExpense
                                      ? LucideIcons.arrowUp
                                      : LucideIcons.arrowDown,
                                  color:
                                      isExpense ? kExpenseColor : kIncomeColor,
                                ),
                                title: Text(
                                  trx.category,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.clock,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('HH:mm').format(trx.date),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500),
                                        ),
                                        if (trx.note.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          const Text("|",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              trx.note,
                                              // --- PERBAIKAN WARNA DI SINI ---
                                              style: TextStyle(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white70 // Warna putih transparan untuk mode gelap
                                                    : Colors.black87, // Warna hitam untuk mode terang
                                              ),
                                              // -------------------------------
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${isExpense ? '-' : '+'} ${_currencyFormat.format(trx.amount)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isExpense
                                            ? kExpenseColor
                                            : kIncomeColor,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(LucideIcons.ellipsisVertical,
                                          size: 20, color: Colors.grey),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditTransactionScreen(
                                                      transaction: trx),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          _showDeleteConfirmation(
                                              context, trx.id!);
                                        } else if (value == 'image') {
                                          _showImageDialog(
                                              context, trx.imageUrl!);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          if (hasImage)
                                            const PopupMenuItem(
                                              value: 'image',
                                              child: Row(
                                                children: [
                                                  Icon(LucideIcons.image,
                                                      size: 18,
                                                      color: Colors.blueAccent),
                                                  SizedBox(width: 8),
                                                  Text('Lihat Bukti'),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.pencil,
                                                    size: 18,
                                                    color: Colors.grey),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.trash,
                                                    size: 18,
                                                    color: kExpenseColor),
                                                SizedBox(width: 8),
                                                Text('Hapus'),
                                              ],
                                            ),
                                          ),
                                        ];
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}