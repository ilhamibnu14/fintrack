// lib/features/transactions/screens/edit_transaction_screen.dart
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

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _dateController;

  late String _selectedType;
  late String? _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  XFile? _newImageFile;
  String? _existingImageUrl;

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
    
    final trx = widget.transaction;
    _amountController = TextEditingController(text: trx.amount.toStringAsFixed(0));
    _noteController = TextEditingController(text: trx.note);
    _dateController = TextEditingController(text: DateFormat('dd MMMM yyyy').format(trx.date));

    _selectedType = trx.type;
    _selectedDate = trx.date;
    _existingImageUrl = trx.imageUrl;
    
    final categories = trx.type == 'income' ? _incomeCategories : _expenseCategories;
    if (categories.contains(trx.category)) {
      _selectedCategory = trx.category;
    } else {
      _selectedCategory = categories.first;
    }
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMMM yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _pickImage() async {
    XFile? pickedFile = await _cloudinaryService.pickImage();
    if (pickedFile != null) {
      setState(() {
        _newImageFile = pickedFile;
        _existingImageUrl = null;
      });
    }
  }

  void _submitUpdateTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String? finalImageUrl = _existingImageUrl;
      if (_newImageFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mengupload gambar baru...')),
          );
        }
        finalImageUrl = await _cloudinaryService.uploadImage(_newImageFile!);
        if (finalImageUrl == null) {
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
      TransactionModel updatedTransaction = TransactionModel(
        id: widget.transaction.id,
        type: _selectedType,
        amount: amount,
        category: _selectedCategory!,
        note: note,
        date: _selectedDate,
        imageUrl: finalImageUrl,
      );
      try {
        await _firestoreService.updateTransaction(updatedTransaction);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal mengupdate: $e")),
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
        title: const Text("Edit Transaksi"),
        // --- PERBAIKAN DI SINI ---
        foregroundColor: Colors.white,
        // -------------------------
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

  // ... (Sisa kode sama)
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
          child: _buildImagePreview(),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_newImageFile != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          kIsWeb
              ? Image.network(
                  _newImageFile!.path,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : Image.file(
                  File(_newImageFile!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
          _buildRemoveImageButton(),
        ],
      );
    }
    if (_existingImageUrl != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            _existingImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Text('Gagal memuat gambar'));
            },
          ),
          _buildRemoveImageButton(),
        ],
      );
    }
    return Center(
      child: TextButton.icon(
        icon: const Icon(LucideIcons.imagePlus),
        label: const Text("Pilih Gambar"),
        onPressed: _pickImage,
      ),
    );
  }

  Widget _buildRemoveImageButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
        style: IconButton.styleFrom(backgroundColor: Colors.black45),
        onPressed: () {
          setState(() {
            _newImageFile = null;
            _existingImageUrl = null;
          });
        },
      ),
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
            onPressed: _submitUpdateTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                const Text("UPDATE TRANSAKSI", style: TextStyle(fontSize: 16)),
          );
  }
}