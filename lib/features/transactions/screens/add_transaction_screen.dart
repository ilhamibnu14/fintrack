// lib/features/transactions/screens/add_transaction_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fintrack/app/utils/constants.dart';
import 'package:fintrack/core/models/transaction_model.dart';
import 'package:fintrack/core/services/cloudinary_service.dart';
import 'package:fintrack/core/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  XFile? _imageFile;

  final List<String> _incomeCategories = ['Gaji', 'Bonus', 'Hadiah', 'Lainnya'];
  final List<String> _expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _expenseCategories.first;
    // Format awal
    _dateController.text = DateFormat('dd MMMM yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      // --- PERBAIKAN BUG WAKTU 00:00 ---
      // Ambil waktu sekarang (Jam, Menit, Detik)
      final now = DateTime.now();
      
      // Gabungkan Tanggal yang dipilih (picked) dengan Waktu Sekarang (now)
      final DateTime combinedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
        now.second,
      );

      setState(() {
        _selectedDate = combinedDateTime;
        _dateController.text = DateFormat('dd MMMM yyyy').format(_selectedDate);
      });
      // ----------------------------------
    }
  }

  Future<void> _pickImage() async {
    XFile? pickedFile = await _cloudinaryService.pickImage();
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String? imageUrl;
      if (_imageFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mengupload gambar...')),
          );
        }
        imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
        if (imageUrl == null) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload gambar gagal. Coba lagi.')),
            );
          }
          return;
        }
      }
      final double amount = double.parse(_amountController.text);
      final String note = _noteController.text;
      
      TransactionModel newTransaction = TransactionModel(
        type: _selectedType,
        amount: amount,
        category: _selectedCategory!,
        note: note,
        date: _selectedDate, // Ini sekarang sudah mengandung jam yang benar
        imageUrl: imageUrl,
      );
      
      try {
        await _firestoreService.addTransaction(newTransaction);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menyimpan: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories =
        _selectedType == 'income' ? _incomeCategories : _expenseCategories;
    if (!currentCategories.contains(_selectedCategory)) {
      _selectedCategory = currentCategories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Transaksi Baru"),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(currentCategories),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bukti Transaksi (Opsional)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _imageFile != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    kIsWeb
                        ? Image.network(
                            _imageFile!.path,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        style: IconButton.styleFrom(backgroundColor: Colors.black45),
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                          });
                        },
                      ),
                    )
                  ],
                )
              : Center(
                  child: TextButton.icon(
                    icon: const Icon(LucideIcons.imagePlus),
                    label: const Text("Pilih Gambar"),
                    onPressed: _pickImage,
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildTypeSelector() {
    return Center(
      child: ToggleButtons(
        isSelected: [_selectedType == 'expense', _selectedType == 'income'],
        onPressed: (index) {
          setState(() {
            _selectedType = index == 0 ? 'expense' : 'income';
            _selectedCategory = (_selectedType == 'income'
                    ? _incomeCategories
                    : _expenseCategories)
                .first;
          });
        },
        borderRadius: BorderRadius.circular(8.0),
        selectedColor: Colors.white,
        fillColor: _selectedType == 'expense' ? kExpenseColor : kIncomeColor,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text("Pengeluaran", style: TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text("Pemasukan", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: "Jumlah",
        prefixIcon: const Icon(LucideIcons.wallet),
        prefixText: "Rp ",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Jumlah tidak boleh kosong";
        }
        if (double.tryParse(value) == null) {
          return "Format angka tidak valid";
        }
        if (double.parse(value) <= 0) {
          return "Jumlah harus lebih dari 0";
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      decoration: InputDecoration(
        labelText: "Kategori",
        prefixIcon: const Icon(LucideIcons.tag),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) =>
          value == null ? "Kategori tidak boleh kosong" : null,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Tanggal",
        prefixIcon: const Icon(LucideIcons.calendar),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () => _selectDate(context),
      validator: (value) =>
          value == null || value.isEmpty ? "Tanggal tidak boleh kosong" : null,
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: "Catatan (Opsional)",
        prefixIcon: const Icon(LucideIcons.messageSquare),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _submitTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                const Text("SIMPAN TRANSAKSI", style: TextStyle(fontSize: 16)),
          );
  }
}