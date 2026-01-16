import 'package:appwrite/appwrite.dart';
import '../models/account_model.dart';

/// Account Service for managing accounts in Appwrite
class AccountService {
  final Databases _databases;
  final String _databaseId;
  final String _collectionId;

  AccountService({
    required Databases databases,
    required String databaseId,
    required String collectionId,
  }) : _databases = databases,
       _databaseId = databaseId,
       _collectionId = collectionId;

  /// Create a new account
  Future<AccountModel> createAccount({
    required String userId,
    required String name,
    required String type, // 'cash', 'bank', 'mobile_wallet'
    required double initialBalance,
    String currency = 'BDT',
  }) async {
    try {
      final doc = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'name': name,
          'type': type,
          'initialBalance': initialBalance,
          'currency': currency,
          'isActive': true,
        },
      );

      return AccountModel.fromDocument(doc.data);
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  /// Get all accounts for a user
  Future<List<AccountModel>> getUserAccounts({required String userId}) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents
          .map((doc) => AccountModel.fromDocument(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch accounts: $e');
    }
  }

  /// Get active accounts for a user
  Future<List<AccountModel>> getActiveAccounts({required String userId}) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('isActive', true),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.documents
          .map((doc) => AccountModel.fromDocument(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active accounts: $e');
    }
  }

  /// Get account by ID
  Future<AccountModel?> getAccountById({required String accountId}) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: accountId,
      );

      return AccountModel.fromDocument(doc.data);
    } catch (e) {
      throw Exception('Failed to fetch account: $e');
    }
  }

  /// Update an account
  Future<AccountModel> updateAccount({
    required String accountId,
    String? name,
    String? type,
    double? initialBalance,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (type != null) data['type'] = type;
      if (initialBalance != null) data['initialBalance'] = initialBalance;
      if (isActive != null) data['isActive'] = isActive;

      final doc = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: accountId,
        data: data,
      );

      return AccountModel.fromDocument(doc.data);
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  /// Delete an account
  Future<void> deleteAccount({required String accountId}) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: accountId,
      );
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
