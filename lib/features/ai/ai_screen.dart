import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/init/appwrite_client.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/data_cache_service.dart';
import '../expenses/services/expense_service.dart';
import '../dashboard/services/analytics_service.dart';
import '../budgets/models/budget_model.dart';
import '../budgets/services/budget_service.dart';
import 'widgets/suggestion_card.dart';
import 'widgets/warnings_card.dart';
import 'widgets/tips_card.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _authService = AuthService();
  final _badgeService = BadgeService();
  late AIService _aiService;

  String? _userId;
  bool _loading = true;
  bool _analyzingLoading = false;

  late ExpenseService _expenseService;
  late DataCacheService _cacheService;
  bool _isFirstLoad = true;
  late AnalyticsService _analyticsService;
  late BudgetService _budgetService;

  // Data
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  Map<String, double> _categorySpending = {};
  List<Map<String, dynamic>> _monthlyTrend = [];
  List<BudgetModel> _budgets = [];

  // AI Results
  String _overallAnalysis = '';
  String _spendingAdvice = '';
  String _savingTips = '';
  List<String> _warnings = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Initialize cache service
    final prefs = await SharedPreferences.getInstance();
    _cacheService = DataCacheService(prefs: prefs);

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
      });

      // Initialize services
      _initializeServices();

      // Fetch data
      await _fetchData(forceRefresh: _isFirstLoad);
      _isFirstLoad = false;
    }
  }

  void _initializeServices() {
    final databases = Databases(AppwriteClient.client);

    _expenseService = ExpenseService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: '6962b3c600110543e89f',
      cacheService: _cacheService,
    );

    _analyticsService = AnalyticsService(
      expenseService: _expenseService,
      cacheService: _cacheService,
    );

    _budgetService = BudgetService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: 'budgets',
      cacheService: _cacheService,
    );

    _aiService = AIService(cacheService: _cacheService);
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (_userId == null) return;

    try {
      // Fetch all data in parallel
      await Future.wait([
        _fetchTotals(),
        _fetchCategorySpending(),
        _fetchMonthlyTrend(),
        _fetchBudgets(),
      ]);

      if (mounted) {
        setState(() {
          _loading = false;
        });

        // Generate AI analysis after data is loaded (only on first load)
        if (forceRefresh || _overallAnalysis.isEmpty) {
          await _generateAIAnalysis(forceRefresh: forceRefresh);
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchTotals() async {
    if (_userId == null) return;

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
        });
      }
    } catch (e) {
      print('Error fetching totals: $e');
    }
  }

  Future<void> _fetchCategorySpending() async {
    if (_userId == null) return;

    try {
      final spending = await _analyticsService.getCategoryWiseSpending(
        userId: _userId!,
      );

      if (mounted) {
        setState(() {
          _categorySpending = spending;
        });
      }
    } catch (e) {
      print('Error fetching category spending: $e');
    }
  }

  Future<void> _fetchMonthlyTrend() async {
    if (_userId == null) return;

    try {
      final trend = await _analyticsService.getSpendingTrend(
        userId: _userId!,
        months: 6,
      );

      if (mounted) {
        setState(() {
          _monthlyTrend = trend;
        });
      }
    } catch (e) {
      print('Error fetching monthly trend: $e');
    }
  }

  Future<void> _fetchBudgets() async {
    if (_userId == null) return;

    try {
      final now = DateTime.now();
      final budgets = await _budgetService.getBudgetsByMonth(
        userId: _userId!,
        month: now.month,
        year: now.year,
      );

      if (mounted) {
        setState(() {
          _budgets = budgets;
        });
      }
    } catch (e) {
      // Silently handle budget fetch errors (collection might not exist yet)
      print('Info: Budgets collection not yet created or error: $e');
      // Don't show error to user, just continue without budgets
    }
  }

  Future<void> _generateAIAnalysis({bool forceRefresh = false}) async {
    if (_userId == null || _totalIncome == 0) return;

    setState(() {
      _analyzingLoading = true;
    });

    try {
      // Build budget status map
      final budgetStatus = <String, double>{};
      for (var budget in _budgets) {
        final spent = _categorySpending[budget.category] ?? 0.0;
        budgetStatus[budget.category] = budget.amount > 0
            ? spent / budget.amount
            : 0;
      }

      // Get transaction count
      int totalTransactions = 0;
      try {
        final transactions = await _expenseService.getUserTransactions(
          userId: _userId!,
        );
        totalTransactions = transactions.length;
      } catch (e) {
        print('Error getting transaction count: $e');
      }

      // Generate each analysis separately with error handling
      String analysis = '';
      String advice = '';
      String tips = '';
      List<String> warnings = [];

      try {
        final result = await _aiService.getFinancialAnalysis(
          totalIncome: _totalIncome,
          totalExpense: _totalExpense,
          categorySpending: _categorySpending,
          monthlyTrend: _monthlyTrend,
          budgetStatus: budgetStatus,
          totalTransactions: totalTransactions,
          forceRefresh: forceRefresh,
        );
        analysis = (result as Map)['analysis'] ?? 'Unable to generate analysis';
      } catch (e) {
        print('[AI ERROR] Error generating analysis: $e');
        analysis = 'Unable to generate analysis. Please try again later.';
      }

      try {
        advice = await _aiService.getSpendingAdvice(
          categorySpending: _categorySpending,
          totalIncome: _totalIncome,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        print('[AI ERROR] Error generating spending advice: $e');
        advice = 'Unable to generate spending advice. Please try again later.';
      }

      try {
        tips = await _aiService.getSavingTips(
          totalIncome: _totalIncome,
          totalExpense: _totalExpense,
          categorySpending: _categorySpending,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        print('[AI ERROR] Error generating saving tips: $e');
        tips = 'Unable to generate saving tips. Please try again later.';
      }

      try {
        warnings = await _aiService.getFinancialWarnings(
          totalIncome: _totalIncome,
          totalExpense: _totalExpense,
          categorySpending: _categorySpending,
          budgetStatus: budgetStatus,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        print('[AI ERROR] Error generating warnings: $e');
        warnings = ['Unable to generate financial warnings'];
      }

      if (mounted) {
        setState(() {
          _overallAnalysis = analysis;
          _spendingAdvice = advice;
          _savingTips = tips;
          _warnings = warnings;
          _analyzingLoading = false;
        });

        // Set AI tip badge when new insights are generated
        if (analysis.isNotEmpty || advice.isNotEmpty || tips.isNotEmpty) {
          _badgeService.setNewAITip(true);
        }
      }
    } catch (e) {
      print('[AI ERROR] Unexpected error: $e');
      if (mounted) {
        setState(() {
          _overallAnalysis = 'Error generating analysis';
          _analyzingLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchData();
              },
              child: _totalIncome == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transaction data',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add transactions to get AI analysis',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Summary header
                                Card(
                                  elevation: 2,
                                  color: Colors.blue[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Financial Summary',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Income',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  '৳${_totalIncome.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              width: 1,
                                              height: 40,
                                              color: Colors.grey[300],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Expense',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  '৳${_totalExpense.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              width: 1,
                                              height: 40,
                                              color: Colors.grey[300],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Savings',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  '৳${(_totalIncome - _totalExpense).toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Warnings
                                WarningsCard(
                                  warnings: _warnings,
                                  isLoading: _analyzingLoading,
                                  onRetry: () async {
                                    await _generateAIAnalysis(
                                      forceRefresh: true,
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Overall Analysis
                                SuggestionCard(
                                  title: 'Overall Analysis',
                                  icon: Icons.assessment,
                                  color: Colors.purple,
                                  content: _overallAnalysis,
                                  isLoading: _analyzingLoading,
                                  onRetry: () async {
                                    await _generateAIAnalysis(
                                      forceRefresh: true,
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Spending Advice
                                SuggestionCard(
                                  title: 'Spending Advice',
                                  icon: Icons.trending_down,
                                  color: Colors.orange,
                                  content: _spendingAdvice,
                                  isLoading: _analyzingLoading,
                                  onRetry: () async {
                                    await _generateAIAnalysis(
                                      forceRefresh: true,
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Saving Tips
                                TipsCard(
                                  title: 'Saving Tips',
                                  icon: Icons.savings,
                                  color: Colors.green,
                                  content: _savingTips,
                                  isLoading: _analyzingLoading,
                                  onRetry: () async {
                                    await _generateAIAnalysis(
                                      forceRefresh: true,
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Footer
                                Center(
                                  child: Text(
                                    'AI analysis powered by Gemini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
