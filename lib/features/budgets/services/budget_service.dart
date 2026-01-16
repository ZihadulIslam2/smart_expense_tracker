import 'package:appwrite/appwrite.dart';
import '../models/budget_model.dart';
import '../../../core/services/data_cache_service.dart';

/// Budget Service for managing budgets in Appwrite
class BudgetService {
  final Databases _databases;
  final String _databaseId;
  final String _collectionId;
  final DataCacheService _cacheService;

  BudgetService({
    required Databases databases,
    required String databaseId,
    required String collectionId,
    required DataCacheService cacheService,
  }) : _databases = databases,
       _databaseId = databaseId,
       _collectionId = collectionId,
       _cacheService = cacheService;

  /// Create a new budget
  Future<BudgetModel> createBudget({
    required String userId,
    required String category,
    required double amount,
    required int month,
    required int year,
  }) async {
    try {
      final doc = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'category': category,
          'amount': amount,
          'month': month,
          'year': year,
        },
      );

      // Invalidate cache
      await _cacheService.clearCache('budgets_$userId');

      return BudgetModel.fromDocument(doc.data);
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  /// Get all budgets for a user
  Future<List<BudgetModel>> getUserBudgets({
    required String userId,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'budgets_$userId';

      // Return cached data if valid and not forcing refresh
      if (!forceRefresh) {
        final cached = await _cacheService.getCachedData<List<dynamic>>(
          cacheKey,
          (json) => json is List ? json : [],
        );
        if (cached != null && cached.isNotEmpty) {
          return cached
              .map(
                (item) => BudgetModel.fromDocument(
                  item is Map ? item.cast<String, dynamic>() : {},
                ),
              )
              .toList();
        }
      }

      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      final budgets = response.documents
          .map((doc) => BudgetModel.fromDocument(doc.data))
          .toList();

      // Cache the results
      await _cacheService.cacheData(
        cacheKey,
        budgets.map((b) => b.toMap()).toList(),
      );

      return budgets;
    } catch (e) {
      throw Exception('Failed to fetch budgets: $e');
    }
  }

  /// Get budgets for a specific month and year
  Future<List<BudgetModel>> getBudgetsByMonth({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('month', month),
          Query.equal('year', year),
        ],
      );

      return response.documents
          .map((doc) => BudgetModel.fromDocument(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch budgets for month: $e');
    }
  }

  /// Get budget for a specific category and month
  Future<BudgetModel?> getBudgetByCategory({
    required String userId,
    required String category,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('category', category),
          Query.equal('month', month),
          Query.equal('year', year),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) {
        return null;
      }

      return BudgetModel.fromDocument(response.documents.first.data);
    } catch (e) {
      throw Exception('Failed to fetch budget by category: $e');
    }
  }

  /// Update a budget
  Future<BudgetModel> updateBudget({
    required String budgetId,
    required String userId,
    required String category,
    required double amount,
  }) async {
    try {
      final doc = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: budgetId,
        data: {'category': category, 'amount': amount},
      );

      // Invalidate cache
      await _cacheService.clearCache('budgets_$userId');

      return BudgetModel.fromDocument(doc.data);
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  /// Delete a budget
  Future<void> deleteBudget({
    required String budgetId,
    required String userId,
  }) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: budgetId,
      );

      // Invalidate cache
      await _cacheService.clearCache('budgets_$userId');
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }
}
