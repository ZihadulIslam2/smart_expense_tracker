import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../../core/init/appwrite_client.dart';
import '../../services/auth_service.dart';
import '../expenses/services/expense_service.dart';
import '../dashboard/services/analytics_service.dart';
import '../dashboard/widgets/summary_card.dart';
import '../dashboard/widgets/category_pie_chart.dart';
import '../dashboard/widgets/monthly_bar_chart.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _authService = AuthService();

  String? _userId;
  bool _loading = true;

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  bool _loadingTotals = false;

  Map<String, double> _categorySpending = {};
  bool _loadingCategories = false;

  List<Map<String, dynamic>> _monthlyTrend = [];
  bool _loadingTrend = false;

  late ExpenseService _expenseService;
  late AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Check for active session
    final hasSession = await _authService.hasActiveSession();
    if (!hasSession && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    // Get current user
    final user = await _authService.getCurrentUser();
    if (user == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    if (mounted) {
      setState(() {
        _userId = user!.$id;
        _loading = false;
      });

      // Initialize services
      _initializeServices();

      // Fetch all analytics data
      await _fetchAllData();
    }
  }

  void _initializeServices() {
    final databases = Databases(AppwriteClient.client);
    _expenseService = ExpenseService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: '6962b3c600110543e89f',
    );
    _analyticsService = AnalyticsService(expenseService: _expenseService);
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchTotals(),
      _fetchCategorySpending(),
      _fetchMonthlyTrend(),
    ]);
  }

  Future<void> _fetchTotals() async {
    if (_userId == null) return;

    setState(() {
      _loadingTotals = true;
    });

    try {
      final transactions = await _expenseService.getUserTransactions(
        userId: _userId!,
      );

      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var transaction in transactions) {
        if (transaction.type == 'income') {
          totalIncome += transaction.amount;
        } else if (transaction.type == 'expense') {
          totalExpense += transaction.amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = totalIncome;
          _totalExpense = totalExpense;
          _loadingTotals = false;
        });
      }
    } catch (e) {
      print('Error fetching totals: $e');
      if (mounted) {
        setState(() {
          _loadingTotals = false;
        });
      }
    }
  }

  Future<void> _fetchCategorySpending() async {
    if (_userId == null) return;

    setState(() {
      _loadingCategories = true;
    });

    try {
      final spending = await _analyticsService.getCategoryWiseSpending(
        userId: _userId!,
      );

      if (mounted) {
        setState(() {
          _categorySpending = spending;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      print('Error fetching category spending: $e');
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchMonthlyTrend() async {
    if (_userId == null) return;

    setState(() {
      _loadingTrend = true;
    });

    try {
      final trend = await _analyticsService.getSpendingTrend(
        userId: _userId!,
        months: 6,
      );

      if (mounted) {
        setState(() {
          _monthlyTrend = trend;
          _loadingTrend = false;
        });
      }
    } catch (e) {
      print('Error fetching monthly trend: $e');
      if (mounted) {
        setState(() {
          _loadingTrend = false;
        });
      }
    }
  }

  String _generateInsights() {
    if (_categorySpending.isEmpty && _totalExpense == 0) {
      return 'No expenses yet. Start tracking your spending to see insights!';
    }

    final savings = _totalIncome - _totalExpense;
    final savingsPercentage = _totalIncome > 0
        ? ((savings / _totalIncome) * 100).toStringAsFixed(1)
        : '0';

    // Find top spending category
    String topCategory = 'N/A';
    double maxAmount = 0;

    _categorySpending.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCategory = category;
      }
    });

    final totalCategoryExpense = _categorySpending.values.fold(
      0.0,
      (sum, a) => sum + a,
    );
    final topCategoryPercentage = totalCategoryExpense > 0
        ? (maxAmount / totalCategoryExpense) * 100
        : 0;

    if (savings >= 0) {
      return '💰 You\'re saving ৳${savings.toStringAsFixed(2)} (${savingsPercentage}% of income).\n\n'
          '📊 Highest spending: $topCategory (${topCategoryPercentage.toStringAsFixed(1)}%).\n\n'
          '✨ Keep up the great work!';
    } else {
      final deficit = savings.abs();
      return '⚠️ You\'re spending ৳${deficit.toStringAsFixed(2)} more than your income.\n\n'
          '📊 Highest spending: $topCategory (${topCategoryPercentage.toStringAsFixed(1)}%).\n\n'
          '💡 Consider reducing expenses to balance your budget.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis'), elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Financial Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your income, expenses, and savings',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Summary Cards
                    SummaryCard(
                      title: 'Total Income',
                      amount: _totalIncome,
                      icon: Icons.arrow_downward,
                      color: Colors.green[400]!,
                      isLoading: _loadingTotals,
                    ),
                    const SizedBox(height: 12),
                    SummaryCard(
                      title: 'Total Expense',
                      amount: _totalExpense,
                      icon: Icons.arrow_upward,
                      color: Colors.red[400]!,
                      isLoading: _loadingTotals,
                    ),
                    const SizedBox(height: 12),
                    SummaryCard(
                      title: 'Total Savings',
                      amount: _totalIncome - _totalExpense,
                      icon: (_totalIncome - _totalExpense) >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: (_totalIncome - _totalExpense) >= 0
                          ? Colors.blue[400]!
                          : Colors.orange[400]!,
                      isLoading: _loadingTotals,
                    ),
                    const SizedBox(height: 24),

                    // Insights Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Insights',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _generateInsights(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Monthly Bar Chart
                    MonthlyBarChart(
                      monthlyTrend: _monthlyTrend,
                      isLoading: _loadingTrend,
                    ),
                    const SizedBox(height: 24),

                    // Category Pie Chart
                    CategoryPieChart(
                      categorySpending: _categorySpending,
                      isLoading: _loadingCategories,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
