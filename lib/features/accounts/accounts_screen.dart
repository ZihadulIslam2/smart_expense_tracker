import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../../core/init/appwrite_client.dart';
import '../../services/auth_service.dart';
import '../expenses/services/expense_service.dart';
import 'models/account_model.dart';
import 'services/account_service.dart';
import 'widgets/account_card.dart';
import 'widgets/add_edit_account_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _authService = AuthService();

  String? _userId;
  bool _loading = true;

  late AccountService _accountService;
  late ExpenseService _expenseService;

  List<AccountModel> _accounts = [];
  Map<String, double> _accountBalances = {};

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

    _accountService = AccountService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId:
          '696a268b002b9cbfa3d3', // You'll need to create this collection
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
      // Fetch all accounts
      final accounts = await _accountService.getUserAccounts(userId: _userId!);

      // Fetch all transactions
      final transactions = await _expenseService.getUserTransactions(
        userId: _userId!,
      );

      // Calculate balance for each account
      final balances = <String, double>{};

      for (var account in accounts) {
        double balance = account.initialBalance;

        // Add/subtract transactions for this account
        for (var transaction in transactions) {
          // Check if transaction belongs to this account
          // For now, we'll calculate based on category and type
          // In the future, transactions should have accountId field
          if (transaction.type == 'income') {
            balance += transaction.amount;
          } else if (transaction.type == 'expense') {
            balance -= transaction.amount;
          }
        }

        balances[account.id] = balance;
      }

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _accountBalances = balances;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching account data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading accounts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddAccountDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddEditAccountDialog(),
    );

    if (result != null && mounted) {
      _addAccount(
        name: result['name'] as String,
        type: result['type'] as String,
        initialBalance: result['initialBalance'] as double,
      );
    }
  }

  Future<void> _showEditAccountDialog(AccountModel account) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddEditAccountDialog(
        accountName: account.name,
        accountType: account.type,
        initialBalance: account.initialBalance,
      ),
    );

    if (result != null && mounted) {
      _updateAccount(
        accountId: account.id,
        name: result['name'] as String,
        type: result['type'] as String,
        initialBalance: result['initialBalance'] as double,
      );
    }
  }

  Future<void> _addAccount({
    required String name,
    required String type,
    required double initialBalance,
  }) async {
    if (_userId == null) return;

    try {
      await _accountService.createAccount(
        userId: _userId!,
        name: name,
        type: type,
        initialBalance: initialBalance,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      print('Error adding account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAccount({
    required String accountId,
    required String name,
    required String type,
    required double initialBalance,
  }) async {
    try {
      await _accountService.updateAccount(
        accountId: accountId,
        name: name,
        type: type,
        initialBalance: initialBalance,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      print('Error updating account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${account.name}"?\n\nThis will not delete associated transactions.',
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
        await _accountService.deleteAccount(accountId: account.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchData();
        }
      } catch (e) {
        print('Error deleting account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNetBalanceCard() {
    double totalBalance = 0.0;

    for (var balance in _accountBalances.values) {
      totalBalance += balance;
    }

    final isSolvent = totalBalance >= 0;

    return Card(
      elevation: 3,
      color: isSolvent ? Colors.green[50] : Colors.red[50],
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Net Balance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BDT ${totalBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isSolvent ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Accounts',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_accounts.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Column(
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isSolvent
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: isSolvent ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSolvent ? 'Healthy' : 'Alert',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSolvent ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView(
                slivers: [
                  // Net Balance Summary
                  SliverToBoxAdapter(child: _buildNetBalanceCard()),

                  // Accounts List
                  if (_accounts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
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
                              'No accounts yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first account',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final account = _accounts[index];
                        final balance =
                            _accountBalances[account.id] ??
                            account.initialBalance;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: AccountCard(
                            account: account,
                            currentBalance: balance,
                            onEdit: () => _showEditAccountDialog(account),
                            onDelete: () => _deleteAccount(account),
                          ),
                        );
                      }, childCount: _accounts.length),
                    ),

                  // Bottom padding
                  if (_accounts.isNotEmpty)
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
