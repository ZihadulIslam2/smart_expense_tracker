import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../../core/init/appwrite_client.dart';
import '../../services/auth_service.dart';
import '../expenses/services/expense_service.dart';
import 'models/budget_model.dart';
import 'services/budget_service.dart';
import 'widgets/budget_card.dart';
import 'widgets/add_edit_budget_dialog.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _authService = AuthService();

  String? _userId;
  bool _loading = true;

  late BudgetService _budgetService;
  late ExpenseService _expenseService;

  List<BudgetModel> _budgets = [];
  Map<String, double> _categorySpending = {};

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

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

      // Fetch data
      await _fetchData();
    }
  }

  void _initializeServices() {
    final databases = Databases(AppwriteClient.client);

    _budgetService = BudgetService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: 'budgets', // You'll need to create this collection
    );

    _expenseService = ExpenseService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: '6962b3c600110543e89f',
    );
  }

  Future<void> _fetchData() async {
    if (_userId == null) return;

    setState(() {
      _loading = true;
    });

    try {
      // Fetch budgets for selected month
      final budgets = await _budgetService.getBudgetsByMonth(
        userId: _userId!,
        month: _selectedMonth,
        year: _selectedYear,
      );

      // Fetch transactions for selected month to calculate spending
      final transactions = await _expenseService.getUserTransactions(
        userId: _userId!,
      );

      final monthlySpending = <String, double>{};
      for (var transaction in transactions) {
        if (transaction.type == 'expense' &&
            transaction.date.month == _selectedMonth &&
            transaction.date.year == _selectedYear) {
          monthlySpending[transaction.category] =
              (monthlySpending[transaction.category] ?? 0.0) +
              transaction.amount;
        }
      }

      if (mounted) {
        setState(() {
          _budgets = budgets;
          _categorySpending = monthlySpending;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching budget data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading budgets: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddBudgetDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          AddEditBudgetDialog(month: _selectedMonth, year: _selectedYear),
    );

    if (result != null && mounted) {
      _addBudget(
        category: result['category'] as String,
        amount: result['amount'] as double,
      );
    }
  }

  Future<void> _showEditBudgetDialog(BudgetModel budget) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddEditBudgetDialog(
        budget: budget,
        month: _selectedMonth,
        year: _selectedYear,
      ),
    );

    if (result != null && mounted) {
      _updateBudget(
        budgetId: budget.id,
        category: result['category'] as String,
        amount: result['amount'] as double,
      );
    }
  }

  Future<void> _addBudget({
    required String category,
    required double amount,
  }) async {
    if (_userId == null) return;

    try {
      // Check if budget already exists for this category
      final existing = await _budgetService.getBudgetByCategory(
        userId: _userId!,
        category: category,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Budget for $category already exists for this month',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _budgetService.createBudget(
        userId: _userId!,
        category: category,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      print('Error adding budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding budget: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateBudget({
    required String budgetId,
    required String category,
    required double amount,
  }) async {
    try {
      await _budgetService.updateBudget(
        budgetId: budgetId,
        category: category,
        amount: amount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      print('Error updating budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating budget: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete the budget for ${budget.category}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _budgetService.deleteBudget(budgetId: budget.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchData();
        }
      } catch (e) {
        print('Error deleting budget: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting budget: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _fetchData();
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildSummaryCard() {
    double totalBudget = 0.0;
    double totalSpent = 0.0;
    int overBudgetCount = 0;

    for (var budget in _budgets) {
      totalBudget += budget.amount;
      final spent = _categorySpending[budget.category] ?? 0.0;
      totalSpent += spent;
      if (spent > budget.amount) {
        overBudgetCount++;
      }
    }

    final remaining = totalBudget - totalSpent;
    final isOverBudget = totalSpent > totalBudget;

    return Card(
      elevation: 3,
      color: isOverBudget ? Colors.red[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${totalBudget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Spent',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverBudget
                      ? 'Over by ৳${remaining.abs().toStringAsFixed(2)}'
                      : 'Remaining ৳${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isOverBudget ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (overBudgetCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$overBudgetCount Over Budget',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets'), elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Column(
                children: [
                  // Month Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _changeMonth(-1),
                        ),
                        Text(
                          '${_getMonthName(_selectedMonth)} $_selectedYear',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _changeMonth(1),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _budgets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No budgets set for this month',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap + to add your first budget',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildSummaryCard(),
                              const SizedBox(height: 16),
                              ..._budgets.map((budget) {
                                final spent =
                                    _categorySpending[budget.category] ?? 0.0;
                                return BudgetCard(
                                  budget: budget,
                                  actualSpending: spent,
                                  onEdit: () => _showEditBudgetDialog(budget),
                                  onDelete: () => _deleteBudget(budget),
                                );
                              }),
                            ],
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetDialog,
        tooltip: 'Add Budget',
        child: const Icon(Icons.add),
      ),
    );
  }
}
