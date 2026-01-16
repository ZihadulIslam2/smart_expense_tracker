import 'package:flutter/material.dart';
import 'package:smart_expense_tracker/features/records/records_screen.dart';
import 'package:smart_expense_tracker/features/analysis/analysis_screen.dart';
import 'package:smart_expense_tracker/features/budgets/budgets_screen.dart';
import 'package:smart_expense_tracker/features/accounts/accounts_screen.dart';
import 'package:smart_expense_tracker/features/ai/ai_screen.dart';
import 'package:smart_expense_tracker/features/goals/goals_screen.dart';
import 'package:smart_expense_tracker/core/services/badge_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  final BadgeService _badgeService = BadgeService();

  // List of screens corresponding to each tab
  final List<Widget> _screens = const [
    RecordsScreen(),
    AnalysisScreen(),
    BudgetsScreen(),
    AccountsScreen(),
    AIScreen(),
    GoalsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Clear badges when navigating to respective tabs
    if (index == 2) {
      // Budgets tab
      _badgeService.clearBudgetWarning();
    } else if (index == 4) {
      // AI tab
      _badgeService.clearAITipBadge();
    }

    setState(() {
      _currentIndex = index;
    });

    // Animate page transition
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Animate FAB
    _fabAnimationController.reset();
    _fabAnimationController.forward();
  }

  /// Build navigation item with badge support
  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    bool showBadge = false,
    int? badgeCount,
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (showBadge)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: badgeCount != null && badgeCount > 0
                      ? BoxShape.circle
                      : BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: badgeCount != null && badgeCount > 0
                    ? Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _badgeService,
        builder: (context, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 8,
            items: [
              _buildNavItem(icon: Icons.receipt_long, label: 'Records'),
              _buildNavItem(icon: Icons.analytics, label: 'Analysis'),
              _buildNavItem(
                icon: Icons.account_balance_wallet,
                label: 'Budgets',
                showBadge: _badgeService.hasBudgetWarning,
                badgeCount: _badgeService.budgetExceededCount,
              ),
              _buildNavItem(icon: Icons.account_balance, label: 'Accounts'),
              _buildNavItem(
                icon: Icons.auto_awesome,
                label: 'AI',
                showBadge: _badgeService.hasNewAITip,
              ),
              _buildNavItem(icon: Icons.flag, label: 'Goals'),
            ],
          );
        },
      ),
    );
  }
}
