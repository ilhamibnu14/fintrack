// lib/core/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id;
  final String type; // "income" or "expense"
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? imageUrl; // <-- FIELD BARU DITAMBAHKAN

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.imageUrl, // <-- DITAMBAHKAN DI KONSTRUKTOR
  });

  // Factory untuk membuat dari Firestore Snapshot
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'], // <-- DITAMBAHKAN DI SINI
    );
  }

  // Method untuk mengubah ke Map (untuk kirim ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl, // <-- DITAMBAHKAN DI SINI
    };
  }
}