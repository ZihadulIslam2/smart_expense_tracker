/// Goal model for financial goals
class GoalModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String
  category; // e.g., 'Emergency Fund', 'Vacation', 'Car', 'House', etc.
  final String? iconName; // Optional icon identifier
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.category,
    this.iconName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate progress percentage (0-100)
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final progress = (currentAmount / targetAmount) * 100;
    return progress.clamp(0.0, 100.0);
  }

  /// Calculate remaining amount
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  /// Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// Calculate months remaining
  int get monthsRemaining {
    final days = daysRemaining;
    return (days / 30).ceil();
  }

  /// Calculate suggested monthly contribution
  double get suggestedMonthlyContribution {
    if (monthsRemaining <= 0) return remainingAmount;
    return remainingAmount / monthsRemaining;
  }

  /// Check if goal is achieved
  bool get isAchieved {
    return currentAmount >= targetAmount;
  }

  /// Check if goal is overdue
  bool get isOverdue {
    return !isAchieved && DateTime.now().isAfter(targetDate);
  }

  /// Create from Appwrite document
  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
      targetDate: DateTime.parse(map['targetDate']),
      category: map['category'] ?? 'Other',
      iconName: map['iconName'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to Appwrite document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
