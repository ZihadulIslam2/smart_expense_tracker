import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/core/init/appwrite_client.dart';
import 'package:smart_expense_tracker/core/services/data_cache_service.dart';
import 'package:smart_expense_tracker/features/expenses/models/transaction_model.dart';
import 'package:smart_expense_tracker/features/expenses/screens/add_expense_screen.dart';
import 'package:smart_expense_tracker/features/expenses/services/expense_service.dart';
import 'package:smart_expense_tracker/services/auth_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _authService = AuthService();

  late ExpenseService _expenseService;
  late DataCacheService _cacheService;
  String? _userId;

  List<TransactionModel> _transactions = [];
  String _filterType = 'all';
  bool _loading = true;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasSession = await _authService.hasActiveSession();
    if (!hasSession && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    final user = await _authService.getCurrentUser();
    if (user == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    // Initialize cache service
    final prefs = await SharedPreferences.getInstance();
    _cacheService = DataCacheService(prefs: prefs);

    _initializeService();

    if (mounted) {
      setState(() {
        _userId = user!.$id;
      });
    }

    // Only fetch on first load
    await _fetchTransactions(forceRefresh: _isFirstLoad);
    _isFirstLoad = false;
  }

  void _initializeService() {
    final databases = Databases(AppwriteClient.client);
    _expenseService = ExpenseService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: '6962b3c600110543e89f',
      cacheService: _cacheService,
    );
  }

  Future<void> _fetchTransactions({bool forceRefresh = false}) async {
    if (_userId == null) return;

    // Only show loading on first load or force refresh
    if (forceRefresh) {
      setState(() {
        _loading = true;
      });
    }

    try {
      List<TransactionModel> transactions;
      if (_filterType == 'all') {
        transactions = await _expenseService.getUserTransactions(
          userId: _userId!,
          forceRefresh: forceRefresh,
        );
      } else {
        transactions = await _expenseService.getTransactionsByType(
          userId: _userId!,
          type: _filterType,
          forceRefresh: forceRefresh,
        );
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(String documentId) async {
    try {
      await _expenseService.deleteTransaction(
        documentId: documentId,
        userId: _userId!,
      );
      setState(() {
        _transactions.removeWhere((t) => t.id == documentId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onAddTransaction() async {
    if (_userId == null) return;

    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddExpenseScreen(userId: _userId!, expenseService: _expenseService),
      ),
    );

    if (added == true) {
      await _fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTransaction,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Income', 'income'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Expense', 'expense'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              _fetchTransactions(forceRefresh: true),
                          child: ListView.builder(
                            itemCount: _transactions.length,
                            padding: const EdgeInsets.all(8.0),
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return _buildTransactionCard(transaction);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterType = value;
        });
        // Use cache for filter changes unless it's the first time
        _fetchTransactions(forceRefresh: false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.red : Colors.green;
    final icon = isExpense ? Icons.arrow_upward : Icons.arrow_downward;
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(transaction.date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${transaction.category} • $formattedDate',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  transaction.description!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () {
                _showDeleteConfirmation(transaction);
              },
            ),
          ],
          child: Text(
            '${isExpense ? '-' : '+'}${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(transaction.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
