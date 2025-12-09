// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintrack/core/models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  // ... (kode transactionsRef yang ada) ...
  CollectionReference<TransactionModel> get transactionsRef {
    if (_userId == null) throw Exception("User not logged in");
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .withConverter<TransactionModel>(
          fromFirestore: (snapshot, _) => TransactionModel.fromFirestore(snapshot),
          toFirestore: (model, _) => model.toMap(),
        );
  }

  // ... (kode addTransaction yang ada) ...
  Future<void> addTransaction(TransactionModel transaction) async {
    await transactionsRef.add(transaction);
  }

  // ... (kode getTransactionsStream yang ada) ...
  Stream<QuerySnapshot<TransactionModel>> getTransactionsStream() {
    return transactionsRef.orderBy('date', descending: true).snapshots();
  }

  // ... (kode deleteTransaction yang ada) ...
  Future<void> deleteTransaction(String transactionId) async {
    await transactionsRef.doc(transactionId).delete();
  }

  // --- TAMBAHKAN METODE DI BAWAH INI ---

  // Update transaksi
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) {
      throw Exception("Transaction ID is missing for update");
    }
    // Kita gunakan .set() atau .update() pada .doc(transaction.id)
    // .update() lebih efisien jika kita hanya mengirim map
    await transactionsRef.doc(transaction.id).update(transaction.toMap());
  }
}