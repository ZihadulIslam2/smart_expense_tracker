import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/transaction_model.dart';

class ExpenseService {
  final Databases _databases;
  final String _databaseId;
  final String _collectionId;

  ExpenseService({
    required Databases databases,
    required String databaseId,
    required String collectionId,
  }) : _databases = databases,
       _databaseId = databaseId,
       _collectionId = collectionId;

  /// Add a new transaction to the database
  Future<TransactionModel> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required String category,
    required String type,
    required DateTime date,
    String? description,
  }) async {
    try {
      final transaction = TransactionModel(
        id: '',
        userId: userId,
        title: title,
        amount: amount,
        type: type,
        category: category,
        date: date,
        description: description,
      );

      final document = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: transaction.toMap(),
      );

      return TransactionModel.fromMap(document.data);
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  /// Get all transactions for a specific user
  Future<List<TransactionModel>> getUserTransactions({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final documents = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('date'),
          if (limit != null) Query.limit(limit),
          if (offset != null) Query.offset(offset),
        ],
      );

      return documents.documents
          .map((doc) => TransactionModel.fromMap(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Delete a transaction by document ID
  Future<void> deleteTransaction({required String documentId}) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: documentId,
      );
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  /// Get transactions by type (income/expense)
  Future<List<TransactionModel>> getTransactionsByType({
    required String userId,
    required String type,
  }) async {
    try {
      final documents = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('type', type),
          Query.orderDesc('date'),
        ],
      );

      return documents.documents
          .map((doc) => TransactionModel.fromMap(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions by type: $e');
    }
  }

  /// Get transactions by category
  Future<List<TransactionModel>> getTransactionsByCategory({
    required String userId,
    required String category,
  }) async {
    try {
      final documents = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('category', category),
          Query.orderDesc('date'),
        ],
      );

      return documents.documents
          .map((doc) => TransactionModel.fromMap(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions by category: $e');
    }
  }

  /// Get total expense for a user
  Future<double> getTotalExpense({required String userId}) async {
    try {
      final transactions = await getTransactionsByType(
        userId: userId,
        type: 'expense',
      );
      return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      throw Exception('Failed to calculate total expense: $e');
    }
  }

  /// Get total income for a user
  Future<double> getTotalIncome({required String userId}) async {
    try {
      final transactions = await getTransactionsByType(
        userId: userId,
        type: 'income',
      );
      return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      throw Exception('Failed to calculate total income: $e');
    }
  }
}
