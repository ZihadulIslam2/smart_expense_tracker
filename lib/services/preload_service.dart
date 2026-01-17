import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';
import 'ai_service.dart';
import '../core/init/appwrite_client.dart';
import '../core/services/data_cache_service.dart';
import '../features/expenses/services/expense_service.dart';
import '../features/dashboard/services/analytics_service.dart';
import '../features/budgets/services/budget_service.dart';

/// Service to preload AI analysis data at app startup
class PreloadService {
  static final PreloadService _instance = PreloadService._internal();

  factory PreloadService() {
    return _instance;
  }

  PreloadService._internal();

  bool _isPreloading = false;
  bool _isPreloaded = false;

  /// Check if preloading is already done
  bool get isPreloaded => _isPreloaded;

  /// Start preloading AI analysis data in background
  /// Call this after user logs in and data is available
  Future<void> preloadAIAnalysis({
    required String userId,
    required List<Map<String, dynamic>> goals,
  }) async {
    // Prevent multiple simultaneous preloads
    if (_isPreloading || _isPreloaded) {
      print('[PRELOAD] Already preloading or preloaded, skipping...');
      return;
    }

    _isPreloading = true;
    print('[PRELOAD] Starting background AI preload...');

    try {
      // Initialize services
      final prefs = await SharedPreferences.getInstance();
      final cacheService = DataCacheService(prefs: prefs);
      final databases = Databases(AppwriteClient.client);

      final expenseService = ExpenseService(
        databases: databases,
        databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
        collectionId: '6962b3c600110543e89f',
        cacheService: cacheService,
      );

      final analyticsService = AnalyticsService(
        expenseService: expenseService,
        cacheService: cacheService,
      );

      final budgetService = BudgetService(
        databases: databases,
        databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
        collectionId: 'budgets',
        cacheService: cacheService,
      );

      final aiService = AIService(cacheService: cacheService);

      // Fetch current financial data
      print('[PRELOAD] Fetching financial data from Appwrite...');
      final expenses = await expenseService.getUserTransactions(userId: userId);

      // Calculate analytics data from transactions
      final totalIncome = await expenseService.getTotalIncome(userId: userId);
      final totalExpense = await expenseService.getTotalExpense(userId: userId);
      final categorySpending = await analyticsService.getCategoryWiseSpending(
        userId: userId,
      );
      final monthlyTrend = await analyticsService.getSpendingTrend(
        userId: userId,
      );

      // Get budget data
      final budgets = await budgetService.getUserBudgets(userId: userId);
      final budgetStatus = _calculateBudgetStatus(categorySpending, budgets);
      final totalTransactions = expenses.length;

      print('[PRELOAD] Financial data loaded:');
      print('  - Income: ৳$totalIncome');
      print('  - Expense: ৳$totalExpense');
      print('  - Categories: ${categorySpending.length}');
      print('  - Goals: ${goals.length}');

      // Call AI service to preload all analysis
      print('[PRELOAD] Calling AI service to preload analysis...');
      await aiService.getFinancialAnalysis(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: monthlyTrend,
        budgetStatus: budgetStatus,
        totalTransactions: totalTransactions,
      );

      print('[PRELOAD] ✓ AI analysis preloaded successfully');
      _isPreloaded = true;
    } catch (e) {
      print('[PRELOAD] ✗ Error during preload: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Calculate budget status from category spending and budgets
  Map<String, double> _calculateBudgetStatus(
    Map<String, double> categorySpending,
    List<dynamic> budgets,
  ) {
    final budgetStatus = <String, double>{};

    try {
      for (final budget in budgets) {
        if (budget is Map<String, dynamic>) {
          final category = budget['category'] as String?;
          final budgetAmount = (budget['limit'] as num?)?.toDouble() ?? 0.0;

          if (category != null && budgetAmount > 0) {
            final spent = categorySpending[category] ?? 0.0;
            final percentage = spent / budgetAmount;
            budgetStatus[category] = percentage;
          }
        }
      }
    } catch (e) {
      print('[PRELOAD] Error calculating budget status: $e');
    }

    return budgetStatus;
  }

  /// Reset preload state (useful for logout)
  void reset() {
    _isPreloading = false;
    _isPreloaded = false;
    print('[PRELOAD] Preload state reset');
  }
}
