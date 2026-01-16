/// Account Model
/// Represents a financial account (Cash, Bank, Mobile Wallet, etc.)
class AccountModel {
  final String id;
  final String userId;
  final String name;
  final String type; // 'cash', 'bank', 'mobile_wallet'
  final double initialBalance;
  final String currency; // Default: 'BDT'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialBalance,
    this.currency = 'BDT',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AccountModel from Appwrite document
  factory AccountModel.fromDocument(Map<String, dynamic> doc) {
    return AccountModel(
      id: doc['\$id'] as String,
      userId: doc['userId'] as String,
      name: doc['name'] as String,
      type: doc['type'] as String,
      initialBalance: (doc['initialBalance'] as num).toDouble(),
      currency: doc['currency'] as String? ?? 'BDT',
      isActive: doc['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(doc['\$createdAt'] as String),
      updatedAt: DateTime.parse(doc['\$updatedAt'] as String),
    );
  }

  /// Convert to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'initialBalance': initialBalance,
      'currency': currency,
      'isActive': isActive,
    };
  }

  /// Copy with method for updates
  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? initialBalance,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get account type display name
  String getTypeDisplay() {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank Account';
      case 'mobile_wallet':
        return 'Mobile Wallet';
      default:
        return type;
    }
  }
}
