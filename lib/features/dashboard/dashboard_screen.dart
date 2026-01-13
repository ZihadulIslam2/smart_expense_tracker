import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/appwrite.dart';
import '../../services/auth_service.dart';
import '../expenses/services/expense_service.dart';
import '../expenses/screens/add_expense_screen.dart';
import '../expenses/screens/expense_list_screen.dart';
import '../../core/init/appwrite_client.dart';
import 'services/analytics_service.dart';
import 'services/ai_service.dart';
import 'widgets/summary_card.dart';
import 'widgets/insights_card.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/ai_suggestions_card.dart';
import 'widgets/ai_goals_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _aiService = AIService();
  models.User? _user;
  bool _loading = true;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  bool _loadingTotals = false;
  late ExpenseService _expenseService;
  late AnalyticsService _analyticsService;
  Map<String, double> _categorySpending = {};
  bool _loadingCategories = false;
  List<Map<String, dynamic>> _monthlyTrend = [];
  bool _loadingTrend = false;
  String _aiSuggestions = '';
  bool _loadingSuggestions = false;
  String _aiGoalsAdvice = '';
  bool _loadingGoalsAdvice = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print('[DASHBOARD INIT] Starting dashboard initialization');

    // Debug Gemini setup
    _aiService.debugGeminiSetup();

    // If no active session, kick back to login
    final hasSession = await _authService.hasActiveSession();
    print('[DASHBOARD INIT] Has session: $hasSession');

    if (!hasSession && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    final user = await _authService.getCurrentUser();
    print('[DASHBOARD INIT] User: ${user?.$id}');

    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });

      // Initialize ExpenseService
      if (user != null) {
        print('[DASHBOARD INIT] Initializing expense service');
        _initializeExpenseService();
        // Fetch totals, category spending, and monthly trend after user is set
        await _fetchTotals();
        print(
          '[DASHBOARD INIT] After fetchTotals - Income: $_totalIncome, Expense: $_totalExpense',
        );

        await _fetchCategorySpending();
        print(
          '[DASHBOARD INIT] After fetchCategorySpending - Categories: $_categorySpending',
        );

        await _fetchMonthlyTrend();
        print(
          '[DASHBOARD INIT] After fetchMonthlyTrend - Trend length: ${_monthlyTrend.length}',
        );

        print('[DASHBOARD INIT] About to fetch AI suggestions');
        _fetchAISuggestions();

        print('[DASHBOARD INIT] About to fetch goals advice');
        _fetchGoalsAdvice();
      }
    }
  }

  void _initializeExpenseService() {
    final databases = Databases(AppwriteClient.client);
    _expenseService = ExpenseService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: '6962b3c600110543e89f',
    );
    _analyticsService = AnalyticsService(expenseService: _expenseService);
  }

  Future<void> _fetchTotals() async {
    if (_user == null) return;

    setState(() {
      _loadingTotals = true;
    });

    try {
      // Fetch all transactions for the user
      final transactions = await _expenseService.getUserTransactions(
        userId: _user!.$id,
      );

      // Calculate totals
      double totalIncome = 0.0;
      double totalExpense = 0.0;

      // Loop through each transaction
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
    if (_user == null) return;

    setState(() {
      _loadingCategories = true;
    });

    try {
      final spending = await _analyticsService.getCategoryWiseSpending(
        userId: _user!.$id,
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
    if (_user == null) return;

    setState(() {
      _loadingTrend = true;
    });

    try {
      final trend = await _analyticsService.getSpendingTrend(
        userId: _user!.$id,
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

  Future<void> _fetchAISuggestions() async {
    if (_user == null) {
      print('[AI DEBUG] _fetchAISuggestions: User is null, returning');
      return;
    }

    print('[AI DEBUG] _fetchAISuggestions: Starting fetch');
    print('[AI DEBUG] Total Income: $_totalIncome');
    print('[AI DEBUG] Total Expense: $_totalExpense');

    if (_totalIncome == 0) {
      print('[AI DEBUG] _fetchAISuggestions: Total income is 0, returning');
      return;
    }

    setState(() {
      _loadingSuggestions = true;
    });

    try {
      print('[AI DEBUG] Calling AIService.getFinancialSuggestions()');
      final suggestions = await _aiService.getFinancialSuggestions(
        totalIncome: _totalIncome,
        totalExpense: _totalExpense,
        categorySpending: _categorySpending,
        monthlyTrend: _monthlyTrend,
        goalsProgress: {},
      );

      print('[AI DEBUG] Received suggestions: $suggestions');

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _loadingSuggestions = false;
        });
        print('[AI DEBUG] UI Updated with suggestions');
      }
    } catch (e) {
      print('[AI ERROR] Error fetching AI suggestions: $e');
      if (mounted) {
        setState(() {
          _aiSuggestions = 'Error: ${e.toString()}';
          _loadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _fetchGoalsAdvice() async {
    if (_user == null) {
      print('[GOALS DEBUG] _fetchGoalsAdvice: User is null, returning');
      return;
    }

    print('[GOALS DEBUG] _fetchGoalsAdvice: Starting fetch');
    print('[GOALS DEBUG] Total Income: $_totalIncome');

    if (_totalIncome == 0) {
      print('[GOALS DEBUG] _fetchGoalsAdvice: Total income is 0, returning');
      return;
    }

    setState(() {
      _loadingGoalsAdvice = true;
    });

    try {
      print('[GOALS DEBUG] Calling AIService.getSavingsGoalsAdvice()');
      final goalsAdvice = await _aiService.getSavingsGoalsAdvice(
        totalIncome: _totalIncome,
        totalExpense: _totalExpense,
        categorySpending: _categorySpending,
      );

      print('[GOALS DEBUG] Received goals advice: $goalsAdvice');

      if (mounted) {
        setState(() {
          _aiGoalsAdvice = goalsAdvice;
          _loadingGoalsAdvice = false;
        });
        print('[GOALS DEBUG] UI Updated with goals');
      }
    } catch (e) {
      print('[GOALS ERROR] Error fetching goals advice: $e');
      if (mounted) {
        setState(() {
          _aiGoalsAdvice = 'Error: ${e.toString()}';
          _loadingGoalsAdvice = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/'); // back to Login
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _navigateToAddExpense() async {
    if (_user == null) return;

    // Use the existing Appwrite client
    final databases = Databases(AppwriteClient.client);
    final expenseService = ExpenseService(
      databases: databases,
      databaseId:
          '143973bc-3217-4b7e-a1ca-05082dfde404', // Replace with your database ID
      collectionId: '6962b3c600110543e89f', // Replace with your collection ID
    );

    // Navigate to Add Expense Screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          userId: _user!.$id,
          expenseService: expenseService,
        ),
      ),
    );

    // Refresh dashboard if expense was added
    if (result == true && mounted) {
      // Refresh all dashboard data when a new expense is added
      _fetchTotals();
      _fetchCategorySpending();
      _fetchMonthlyTrend();
      _fetchAISuggestions();
      _fetchGoalsAdvice();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _navigateToTransactionList() async {
    if (_user == null) return;

    // Navigate and wait for return
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseListScreen(userId: _user!.$id),
      ),
    );

    // Refresh all data when returning from transaction list
    if (mounted) {
      _fetchTotals();
      _fetchCategorySpending();
      _fetchMonthlyTrend();
      _fetchAISuggestions();
      _fetchGoalsAdvice();
    }
  }

  /// Generate spending insights
  String _generateInsights() {
    if (_categorySpending.isEmpty) {
      return 'No expenses yet. Start tracking your spending!';
    }

    // Find the category with highest spending
    String topCategory = '';
    double maxAmount = 0;

    _categorySpending.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCategory = category;
      }
    });

    // Calculate percentage
    final totalExpense = _categorySpending.values.fold(
      0.0,
      (sum, a) => sum + a,
    );
    final percentage = (maxAmount / totalExpense) * 100;

    // Calculate savings
    final savings = _totalIncome - _totalExpense;
    final savingsPercentage = _totalIncome > 0
        ? ((savings / _totalIncome) * 100).toStringAsFixed(1)
        : '0';

    if (savings >= 0) {
      return 'Great job! You\'re saving ৳${savings.toStringAsFixed(2)} (${savingsPercentage}% of income). '
          'Your highest spending is on $topCategory (${percentage.toStringAsFixed(1)}%).';
    } else {
      return 'You spent ৳${_totalExpense.toStringAsFixed(2)}. '
          'Your top expense is $topCategory (${percentage.toStringAsFixed(1)}%). '
          'Try reducing spending to increase savings.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _user?.name;
    final name = userName != null && userName.isNotEmpty ? userName : 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Summary Cards
                  SummaryCard(
                    title: 'Total Expense',
                    amount: _totalExpense,
                    icon: Icons.arrow_upward,
                    color: Colors.red[400]!,
                    isLoading: _loadingTotals,
                  ),
                  const SizedBox(height: 12),
                  SummaryCard(
                    title: 'Total Income',
                    amount: _totalIncome,
                    icon: Icons.arrow_downward,
                    color: Colors.green[400]!,
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
                  // Insights
                  InsightsCard(insights: _generateInsights()),
                  const SizedBox(height: 24),
                  // Category Pie Chart
                  CategoryPieChart(
                    categorySpending: _categorySpending,
                    isLoading: _loadingCategories,
                  ),
                  const SizedBox(height: 24),
                  // Monthly Bar Chart
                  MonthlyBarChart(
                    monthlyTrend: _monthlyTrend,
                    isLoading: _loadingTrend,
                  ),
                  const SizedBox(height: 24),
                  // AI Suggestions
                  AISuggestionsCard(
                    suggestions: _aiSuggestions,
                    isLoading: _loadingSuggestions,
                  ),
                  const SizedBox(height: 24),
                  // AI Goals Advice
                  AIGoalsCard(
                    goalsAdvice: _aiGoalsAdvice,
                    isLoading: _loadingGoalsAdvice,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToAddExpense,
                      child: const Text('Add Expense'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _navigateToTransactionList,
                      child: const Text('View Transactions'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
