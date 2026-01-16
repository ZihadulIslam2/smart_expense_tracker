import 'package:flutter/material.dart';
import 'package:smart_expense_tracker/features/records/records_screen.dart';
import 'package:smart_expense_tracker/features/analysis/analysis_screen.dart';
import 'package:smart_expense_tracker/features/budgets/budgets_screen.dart';
import 'package:smart_expense_tracker/features/accounts/accounts_screen.dart';
import 'package:smart_expense_tracker/features/ai/ai_screen.dart';
import 'package:smart_expense_tracker/features/goals/goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
        ],
      ),
    );
  }
}
