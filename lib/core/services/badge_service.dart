import 'package:flutter/foundation.dart';

/// Service to manage notification badges for bottom navigation tabs
class BadgeService extends ChangeNotifier {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  // Badge states
  bool _hasBudgetWarning = false;
  bool _hasNewAITip = false;
  int _budgetExceededCount = 0;

  // Getters
  bool get hasBudgetWarning => _hasBudgetWarning;
  bool get hasNewAITip => _hasNewAITip;
  int get budgetExceededCount => _budgetExceededCount;

  /// Update budget warning badge
  void setBudgetWarning(bool hasWarning, {int exceededCount = 0}) {
    if (_hasBudgetWarning != hasWarning ||
        _budgetExceededCount != exceededCount) {
      _hasBudgetWarning = hasWarning;
      _budgetExceededCount = exceededCount;
      notifyListeners();
    }
  }

  /// Update AI tip badge
  void setNewAITip(bool hasNewTip) {
    if (_hasNewAITip != hasNewTip) {
      _hasNewAITip = hasNewTip;
      notifyListeners();
    }
  }

  /// Clear budget warning badge
  void clearBudgetWarning() {
    if (_hasBudgetWarning) {
      _hasBudgetWarning = false;
      _budgetExceededCount = 0;
      notifyListeners();
    }
  }

  /// Clear AI tip badge
  void clearAITipBadge() {
    if (_hasNewAITip) {
      _hasNewAITip = false;
      notifyListeners();
    }
  }

  /// Reset all badges
  void resetAll() {
    _hasBudgetWarning = false;
    _hasNewAITip = false;
    _budgetExceededCount = 0;
    notifyListeners();
  }
}
