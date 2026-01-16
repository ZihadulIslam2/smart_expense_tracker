/// Budget Model
/// Represents a monthly budget for a specific category
class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final int month; // 1-12
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create BudgetModel from Appwrite document
  factory BudgetModel.fromDocument(Map<String, dynamic> doc) {
    return BudgetModel(
      id: doc['\$id'] as String,
      userId: doc['userId'] as String,
      category: doc['category'] as String,
      amount: (doc['amount'] as num).toDouble(),
      month: doc['month'] as int,
      year: doc['year'] as int,
      createdAt: DateTime.parse(doc['\$createdAt'] as String),
      updatedAt: DateTime.parse(doc['\$updatedAt'] as String),
    );
  }

  /// Convert to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }

  /// Copy with method for updates
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
