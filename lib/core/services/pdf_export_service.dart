// lib/core/services/pdf_export_service.dart
import 'dart:io';
import 'package:fintrack/core/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  // Format mata uang
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Fungsi utama untuk membuat, menyimpan, dan membagikan PDF
  Future<void> generateAndSharePdf(List<TransactionModel> transactions) async {
    final pdf = pw.Document();

    final incomeList =
        transactions.where((trx) => trx.type == 'income').toList();
    final expenseList =
        transactions.where((trx) => trx.type == 'expense').toList();
    
    final double totalIncome =
        incomeList.fold(0, (sum, item) => sum + item.amount);
    final double totalExpense =
        expenseList.fold(0, (sum, item) => sum + item.amount);
    final double balance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(),
            _buildSummary(totalIncome, totalExpense, balance),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Divider(thickness: 2),
            ),
            _buildTransactionTable('Pemasukan', incomeList, PdfColors.green),
            pw.SizedBox(height: 20),
            _buildTransactionTable('Pengeluaran', expenseList, PdfColors.red),
          ];
        },
      ),
    );

    // Mendapatkan direktori temporary (Inilah yang tadi error MissingPluginException)
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/laporan_fintrack.pdf");
    await file.writeAsBytes(await pdf.save());

    // Membagikan file PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Berikut adalah laporan transaksi FinTrack Anda.',
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Laporan Transaksi FinTrack',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
        ),
        pw.Text(
          'Dibuat pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildSummary(double income, double expense, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Pemasukan', income, PdfColors.green),
          _buildSummaryItem('Pengeluaran', expense, PdfColors.red),
          _buildSummaryItem('Saldo Akhir', balance, PdfColors.blue),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String title, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          _currencyFormat.format(amount),
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 16, color: color),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionTable(
      String title, List<TransactionModel> transactions, PdfColor color) {
    final List<List<String>> tableData = transactions.map((trx) {
      return [
        DateFormat('dd/MM/yy').format(trx.date),
        trx.category,
        trx.note.isNotEmpty ? trx.note : '-',
        _currencyFormat.format(trx.amount),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 18, color: color),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Tanggal', 'Kategori', 'Catatan', 'Jumlah'],
          data: tableData,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          cellAlignments: {
            3: pw.Alignment.centerRight,
          },
          border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        ),
      ],
    );
  }
}