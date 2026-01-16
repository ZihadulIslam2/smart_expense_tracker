import 'package:appwrite/appwrite.dart';
import '../models/goal_model.dart';

/// Service for managing financial goals
class GoalService {
  final Databases _databases;
  final String _databaseId;
  final String _collectionId;

  GoalService({
    required Databases databases,
    required String databaseId,
    required String collectionId,
  }) : _databases = databases,
       _databaseId = databaseId,
       _collectionId = collectionId;

  /// Create a new goal
  Future<GoalModel> createGoal({
    required String userId,
    required String title,
    required String description,
    required double targetAmount,
    required DateTime targetDate,
    required String category,
    double currentAmount = 0.0,
    String? iconName,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'userId': userId,
        'title': title,
        'description': description,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
        'category': category,
        'iconName': iconName,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final result = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: data,
      );

      return GoalModel.fromMap(result.data);
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  /// Get all goals for a user
  Future<List<GoalModel>> getUserGoals({required String userId}) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [Query.equal('userId', userId), Query.orderDesc('createdAt')],
      );

      return result.documents
          .map((doc) => GoalModel.fromMap(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch goals: $e');
    }
  }

  /// Get active goals (not achieved and not overdue)
  Future<List<GoalModel>> getActiveGoals({required String userId}) async {
    try {
      final goals = await getUserGoals(userId: userId);
      return goals
          .where((goal) => !goal.isAchieved && !goal.isOverdue)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active goals: $e');
    }
  }

  /// Update goal progress (add contribution)
  Future<GoalModel> addContribution({
    required String goalId,
    required double amount,
  }) async {
    try {
      // Get current goal
      final doc = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: goalId,
      );

      final goal = GoalModel.fromMap(doc.data);
      final newAmount = goal.currentAmount + amount;

      // Update goal
      final result = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: goalId,
        data: {
          'currentAmount': newAmount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return GoalModel.fromMap(result.data);
    } catch (e) {
      throw Exception('Failed to add contribution: $e');
    }
  }

  /// Update goal details
  Future<GoalModel> updateGoal({
    required String goalId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? iconName,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (targetAmount != null) data['targetAmount'] = targetAmount;
      if (currentAmount != null) data['currentAmount'] = currentAmount;
      if (targetDate != null) data['targetDate'] = targetDate.toIso8601String();
      if (category != null) data['category'] = category;
      if (iconName != null) data['iconName'] = iconName;

      final result = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: goalId,
        data: data,
      );

      return GoalModel.fromMap(result.data);
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  /// Delete a goal
  Future<void> deleteGoal({required String goalId}) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: goalId,
      );
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  /// Get goal by ID
  Future<GoalModel> getGoalById({required String goalId}) async {
    try {
      final result = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: goalId,
      );

      return GoalModel.fromMap(result.data);
    } catch (e) {
      throw Exception('Failed to fetch goal: $e');
    }
  }

  /// Get goals by category
  Future<List<GoalModel>> getGoalsByCategory({
    required String userId,
    required String category,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('category', category),
          Query.orderDesc('createdAt'),
        ],
      );

      return result.documents
          .map((doc) => GoalModel.fromMap(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch goals by category: $e');
    }
  }
}
