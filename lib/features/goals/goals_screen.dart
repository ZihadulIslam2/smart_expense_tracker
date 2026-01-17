import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/init/appwrite_client.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../core/services/data_cache_service.dart';
import '../expenses/services/expense_service.dart';
import '../dashboard/services/analytics_service.dart';
import 'models/goal_model.dart';
import 'services/goal_service.dart';
import 'widgets/goal_card.dart';
import 'widgets/add_edit_goal_dialog.dart';
import 'widgets/add_contribution_dialog.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _authService = AuthService();
  late GoalService _goalService;
  late ExpenseService _expenseService;
  late AnalyticsService _analyticsService;
  late AIService _aiService;
  late DataCacheService _cacheService;

  String? _userId;
  bool _loading = true;
  bool _aiLoading = false;
  bool _isFirstLoad = true;
  List<GoalModel> _goals = [];
  String _aiInsights = '';

  // Financial context for AI
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  Map<String, double> _categorySpending = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Initialize cache service
    final prefs = await SharedPreferences.getInstance();
    _cacheService = DataCacheService(prefs: prefs);

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

    if (mounted) {
      setState(() {
        _userId = user!.$id;
      });

      _initializeServices();
      await _fetchData(forceRefresh: _isFirstLoad);
      _isFirstLoad = false;
    }
  }

  void _initializeServices() {
    final databases = Databases(AppwriteClient.client);

    _goalService = GoalService(
      databases: databases,
      databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
      collectionId: '696a29970026248c4dcf',
    );

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
    _aiService = AIService(cacheService: _cacheService);
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (_userId == null) return;

    setState(() {
      _loading = true;
    });

    try {
      // Fetch goals and financial data in parallel
      await Future.wait([_fetchGoals(), _fetchFinancialContext()]);

      // Only use cached data - don't make new AI calls
      // The data was preloaded at app startup via PreloadService
      // Load AI insights only if empty (first time)
      if (_goals.isNotEmpty && _aiInsights.isEmpty) {
        await _loadAIInsightsFromCache();
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchGoals() async {
    try {
      final goals = await _goalService.getUserGoals(userId: _userId!);
      if (mounted) {
        setState(() {
          _goals = goals;
        });
      }
    } catch (e) {
      print('Info: Goals collection not yet created or error: $e');
      // Silently handle - collection might not exist yet
    }
  }

  Future<void> _fetchFinancialContext() async {
    try {
      final transactions = await _expenseService.getUserTransactions(
        userId: _userId!,
      );

      double income = 0.0;
      double expense = 0.0;

      for (var transaction in transactions) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else if (transaction.type == 'expense') {
          expense += transaction.amount;
        }
      }

      final spending = await _analyticsService.getCategoryWiseSpending(
        userId: _userId!,
      );

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          _categorySpending = spending;
        });
      }
    } catch (e) {
      print('Error fetching financial context: $e');
    }
  }

  /// Load AI insights from cache (preloaded data)
  Future<void> _loadAIInsightsFromCache({bool forceRefresh = false}) async {
    if (_goals.isEmpty) return;

    setState(() {
      _aiLoading = true;
    });

    try {
      final goalsData = _goals.map((goal) {
        return {
          'title': goal.title,
          'targetAmount': goal.targetAmount.toStringAsFixed(0),
          'currentAmount': goal.currentAmount.toStringAsFixed(0),
          'remaining': goal.remainingAmount.toStringAsFixed(0),
          'progress': goal.progressPercentage.toStringAsFixed(1),
          'deadline': '${goal.monthsRemaining} months',
          'suggestedMonthly': goal.suggestedMonthlyContribution.toStringAsFixed(
            0,
          ),
        };
      }).toList();

      print(
        '[GOALS SCREEN] Loading goal insights from cache (preloaded data)...',
      );
      // Always use cache by default (forceRefresh: false)
      // Only refresh when explicitly called from refresh button
      final result = await _aiService.getGoalInsights(
        goals: goalsData,
        totalIncome: _totalIncome,
        totalExpense: _totalExpense,
        categorySpending: _categorySpending,
        forceRefresh:
            forceRefresh, // Will be false by default, true only on manual refresh
      );

      if (mounted) {
        setState(() {
          _aiInsights = result['insights'] ?? '';
          _aiLoading = false;
        });
      }
    } catch (e) {
      print('[AI ERROR] Error loading goal insights: $e');
      if (mounted) {
        setState(() {
          _aiInsights = 'Unable to load goal insights. Please try again later.';
          _aiLoading = false;
        });
      }
    }
  }

  Future<void> _showAddGoalDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddEditGoalDialog(),
    );

    if (result != null && _userId != null) {
      try {
        await _goalService.createGoal(
          userId: _userId!,
          title: result['title'],
          description: result['description'],
          targetAmount: result['targetAmount'],
          currentAmount: result['currentAmount'],
          targetDate: result['targetDate'],
          category: result['category'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating goal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditGoalDialog(GoalModel goal) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddEditGoalDialog(goal: goal),
    );

    if (result != null) {
      try {
        await _goalService.updateGoal(
          goalId: goal.id,
          title: result['title'],
          description: result['description'],
          targetAmount: result['targetAmount'],
          currentAmount: result['currentAmount'],
          targetDate: result['targetDate'],
          category: result['category'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating goal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddContributionDialog(GoalModel goal) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AddContributionDialog(goal: goal),
    );

    if (amount != null) {
      try {
        await _goalService.addContribution(goalId: goal.id, amount: amount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contribution added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding contribution: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteGoal(GoalModel goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _goalService.deleteGoal(goalId: goal.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal deleted'),
              backgroundColor: Colors.orange,
            ),
          );
          await _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting goal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: _goals.isEmpty ? _buildEmptyState() : _buildGoalsList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_outlined, size: 120, color: Colors.grey[300]),
              const SizedBox(height: 24),
              Text(
                'No Goals Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start saving for what matters most to you.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showAddGoalDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Goal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    // Separate goals by status
    final activeGoals = _goals
        .where((g) => !g.isAchieved && !g.isOverdue)
        .toList();
    final achievedGoals = _goals.where((g) => g.isAchieved).toList();
    final overdueGoals = _goals.where((g) => g.isOverdue).toList();

    return CustomScrollView(
      slivers: [
        // AI Insights Card
        if (_aiInsights.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                color: Colors.purple[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lightbulb,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: const Text(
                              'AI Goal Insights',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!_aiLoading)
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              color: Colors.purple,
                              onPressed: () async {
                                // Force refresh bypasses cache
                                await _loadAIInsightsFromCache(
                                  forceRefresh: true,
                                );
                              },
                              tooltip: 'Refresh AI Insights',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_aiLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Text(
                          _aiInsights,
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
            ),
          ),

        // Active Goals
        if (activeGoals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Active Goals (${activeGoals.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final goal = activeGoals[index];
              return GoalCard(
                goal: goal,
                onTap: () {},
                onAddContribution: () => _showAddContributionDialog(goal),
                onEdit: () => _showEditGoalDialog(goal),
                onDelete: () => _deleteGoal(goal),
              );
            }, childCount: activeGoals.length),
          ),
        ],

        // Achieved Goals
        if (achievedGoals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Achieved Goals (${achievedGoals.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final goal = achievedGoals[index];
              return GoalCard(
                goal: goal,
                onTap: () {},
                onAddContribution: () {},
                onEdit: () => _showEditGoalDialog(goal),
                onDelete: () => _deleteGoal(goal),
              );
            }, childCount: achievedGoals.length),
          ),
        ],

        // Overdue Goals
        if (overdueGoals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Overdue Goals (${overdueGoals.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final goal = overdueGoals[index];
              return GoalCard(
                goal: goal,
                onTap: () {},
                onAddContribution: () => _showAddContributionDialog(goal),
                onEdit: () => _showEditGoalDialog(goal),
                onDelete: () => _deleteGoal(goal),
              );
            }, childCount: overdueGoals.length),
          ),
        ],

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
