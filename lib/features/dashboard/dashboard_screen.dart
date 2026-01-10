import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/appwrite.dart';
import '../../services/auth_service.dart';
import '../expenses/services/expense_service.dart';
import '../expenses/screens/add_expense_screen.dart';
import '../expenses/screens/expense_list_screen.dart';
import '../../core/init/appwrite_client.dart';

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
        // Fetch totals after user is set
        _fetchTotals();
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
      // Refresh totals when a new expense is added
      _fetchTotals();
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

    // Refresh totals when returning from transaction list
    if (mounted) {
      _fetchTotals();
    }
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
          : Padding(
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
