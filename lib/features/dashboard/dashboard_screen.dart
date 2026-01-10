import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/appwrite.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../expenses/services/expense_service.dart';
import '../expenses/screens/add_expense_screen.dart';
import '../expenses/screens/expense_list_screen.dart';
import '../../core/init/appwrite_client.dart';
import 'services/analytics_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
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
  String _insight = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // If no active session, kick back to login
    final hasSession = await _authService.hasActiveSession();
    if (!hasSession && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });

      // Initialize ExpenseService
      if (user != null) {
        _initializeExpenseService();
        // Fetch totals, category spending, and monthly trend after user is set
        _fetchTotals();
        _fetchCategorySpending();
        _fetchMonthlyTrend();
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
    }
  }

  /// Build pie chart sections from category spending data
  List<PieChartSectionData> _buildPieSections() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.indigo,
    ];

    final total = _categorySpending.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    _categorySpending.forEach((category, amount) {
      final percentage = (amount / total) * 100;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );

      colorIndex++;
    });

    return sections;
  }

  /// Build legend showing category colors and names
  Widget _buildCategoryLegend() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.indigo,
    ];

    List<String> categories = _categorySpending.keys.toList();
    int colorIndex = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categories.map((category) {
        final color = colors[colorIndex % colors.length];
        final amount = _categorySpending[category]!;
        colorIndex++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$category: ৳${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Get maximum Y value for bar chart
  double _getMaxYValue() {
    if (_monthlyTrend.isEmpty) return 10000;

    double max = 0;
    for (var month in _monthlyTrend) {
      final income = (month['income'] as num).toDouble();
      final expense = (month['expense'] as num).toDouble();
      if (income > max) max = income;
      if (expense > max) max = expense;
    }

    return max * 1.2; // Add 20% padding
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

  /// Build bar groups for monthly chart
  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_monthlyTrend.length, (index) {
      final monthData = _monthlyTrend[index];
      final income = (monthData['income'] as num).toDouble();
      final expense = (monthData['expense'] as num).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: income,
            color: Colors.green[400],
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expense,
            color: Colors.red[400],
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.name?.isNotEmpty == true ? _user!.name! : 'User';

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
                  // Total Expense Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Expense',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _loadingTotals
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.red[400]!,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      '৳ ${_totalExpense.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.red[400],
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Total Income Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Income',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _loadingTotals
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.green[400]!,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      '৳ ${_totalIncome.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.green[400],
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Total Savings Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Savings',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _loadingTotals
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.blue[400]!,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      '৳ ${(_totalIncome - _totalExpense).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            (_totalIncome - _totalExpense) >= 0
                                            ? Colors.blue
                                            : Colors.orange,
                                      ),
                                    ),
                            ],
                          ),
                          Icon(
                            (_totalIncome - _totalExpense) >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: (_totalIncome - _totalExpense) >= 0
                                ? Colors.blue[400]
                                : Colors.orange[400],
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Insights Card
                  Card(
                    elevation: 2,
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Insights',
                                style: const TextStyle(
                                  fontSize: 16,
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
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Category-wise Spending Pie Chart (with empty state)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending by Category',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_loadingCategories)
                            SizedBox(
                              height: 250,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[400]!,
                                  ),
                                ),
                              ),
                            )
                          else if (_categorySpending.isEmpty)
                            SizedBox(
                              height: 60,
                              child: Center(
                                child: Text(
                                  'No expense data yet. Add expenses to see the chart.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 250,
                              child: PieChart(
                                PieChartData(
                                  sections: _buildPieSections(),
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (_categorySpending.isNotEmpty)
                            _buildCategoryLegend(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Monthly Income vs Expense Bar Chart
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Income vs Expense',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_loadingTrend)
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[400]!,
                                  ),
                                ),
                              ),
                            )
                          else if (_monthlyTrend.isEmpty)
                            SizedBox(
                              height: 60,
                              child: Center(
                                child: Text(
                                  'No transactions yet. Add data to see the trend.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 300,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _getMaxYValue(),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (group) =>
                                          Colors.grey[800]!,
                                      tooltipBorderRadius:
                                          const BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                            final isIncome = rodIndex == 0;
                                            return BarTooltipItem(
                                              '${isIncome ? 'Income' : 'Expense'}: ৳${rod.toY.toStringAsFixed(0)}',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < _monthlyTrend.length) {
                                            return Text(
                                              _monthlyTrend[index]['month'],
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '৳${(value / 1000).toStringAsFixed(0)}K',
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: _buildBarGroups(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
