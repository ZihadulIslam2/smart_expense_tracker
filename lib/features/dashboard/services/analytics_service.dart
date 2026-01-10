import 'package:appwrite/appwrite.dart';
import '../../expenses/models/transaction_model.dart';
import '../../expenses/services/expense_service.dart';

/// Analytics Service for dashboard insights
/// Provides data for monthly summaries, category breakdown, and savings calculations
class AnalyticsService {
  final ExpenseService _expenseService;

  AnalyticsService({required ExpenseService expenseService})
    : _expenseService = expenseService;

  /// Get monthly summary of income and expenses
  ///
  /// Returns a map with:
  /// - income: sum of income for the month
  /// - expense: sum of expenses for the month
  /// - savings: income - expense
  Future<Map<String, double>> getMonthlySummary({
    required String userId,
    int? month,
    int? year,
  }) async {
    try {
      // Use current month/year if not provided
      final now = DateTime.now();
      final targetMonth = month ?? now.month;
      final targetYear = year ?? now.year;

      // Calculate start and end of month
      final firstDay = DateTime(targetYear, targetMonth, 1);
      final lastDay = DateTime(
        targetYear,
        targetMonth + 1,
        1,
      ).subtract(const Duration(days: 1));

      // Fetch all transactions for the user
      final transactions = await _expenseService.getUserTransactions(
        userId: userId,
      );

      // Filter transactions for the target month
      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var transaction in transactions) {
        // Check if transaction is within the target month
        if (transaction.date.year == targetYear &&
            transaction.date.month == targetMonth) {
          if (transaction.type == 'income') {
            totalIncome += transaction.amount;
          } else if (transaction.type == 'expense') {
            totalExpense += transaction.amount;
          }
        }
      }

      final savings = totalIncome - totalExpense;

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'savings': savings,
      };
    } catch (e) {
      throw Exception('Failed to get monthly summary: $e');
    }
  }

  /// Get category-wise spending breakdown
  ///
  /// Returns a map with categories as keys and total amounts as values
  /// Only includes expense transactions
  /// Example: {'Food': 5000.0, 'Transportation': 2000.0, ...}
  Future<Map<String, double>> getCategoryWiseSpending({
    required String userId,
  }) async {
    try {
      // Fetch all transactions for the user
      final transactions = await _expenseService.getUserTransactions(
        userId: userId,
      );

      // Create a map to group expenses by category
      final categorySpending = <String, double>{};

      // Loop through all transactions
      for (var transaction in transactions) {
        // Only include expense transactions
        if (transaction.type == 'expense') {
          // Get or initialize the category total
          final currentAmount = categorySpending[transaction.category] ?? 0.0;
          // Add the transaction amount to the category
          categorySpending[transaction.category] =
              currentAmount + transaction.amount;
        }
      }

      return categorySpending;
    } catch (e) {
      throw Exception('Failed to get category-wise spending: $e');
    }
  }

  /// Calculate total savings (income - expenses)
  ///
  /// Returns the overall savings amount
  /// Positive value = savings, Negative value = deficit
  Future<double> getSavings({required String userId}) async {
    try {
      // TODO: Implement logic to calculate total savings
      // Fetch all transactions and calculate income - expense
      return 0.0;
    } catch (e) {
      throw Exception('Failed to calculate savings: $e');
    }
  }

  /// Get top spending categories
  ///
  /// Returns a map of top N categories by spending amount
  Future<Map<String, double>> getTopCategories({
    required String userId,
    required int limit,
  }) async {
    try {
      // TODO: Implement logic to get top spending categories
      return {};
    } catch (e) {
      throw Exception('Failed to get top categories: $e');
    }
  }

  /// Get spending trend over months
  ///
  /// Returns a list of monthly spending data for the last N months
  /// Each item contains: month, income, expense, savings
  Future<List<Map<String, dynamic>>> getSpendingTrend({
    required String userId,
    int months = 6,
  }) async {
    try {
      // Fetch all transactions for the user
      final transactions = await _expenseService.getUserTransactions(
        userId: userId,
      );

      // Create list to store monthly data
      final monthlyData = <Map<String, dynamic>>[];

      // Get current date
      final now = DateTime.now();

      // Loop through the last N months
      for (int i = months - 1; i >= 0; i--) {
        // Calculate the target month
        final targetDate = DateTime(now.year, now.month - i, 1);
        final targetMonth = targetDate.month;
        final targetYear = targetDate.year;

        // Initialize totals for this month
        double monthlyIncome = 0.0;
        double monthlyExpense = 0.0;

        // Filter and sum transactions for this month
        for (var transaction in transactions) {
          if (transaction.date.year == targetYear &&
              transaction.date.month == targetMonth) {
            if (transaction.type == 'income') {
              monthlyIncome += transaction.amount;
            } else if (transaction.type == 'expense') {
              monthlyExpense += transaction.amount;
            }
          }
        }

        // Add month data to list
        monthlyData.add({
          'month': _getMonthName(targetMonth),
          'monthNumber': targetMonth,
          'year': targetYear,
          'income': monthlyIncome,
          'expense': monthlyExpense,
          'savings': monthlyIncome - monthlyExpense,
        });
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to get spending trend: $e');
    }
  }

  /// Get month name from month number
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
