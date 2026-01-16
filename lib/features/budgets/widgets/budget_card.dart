import 'package:flutter/material.dart';
import '../models/budget_model.dart';

/// Widget to display a budget card with spending comparison
class BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final double actualSpending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.actualSpending,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final budgetAmount = budget.amount;
    final spent = actualSpending;
    final remaining = budgetAmount - spent;
    final percentageUsed = budgetAmount > 0 ? (spent / budgetAmount) * 100 : 0;
    final isOverBudget = spent > budgetAmount;

    // Determine color based on budget status
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isOverBudget) {
      statusColor = Colors.red;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Over Budget';
    } else if (percentageUsed >= 90) {
      statusColor = Colors.orange;
      statusIcon = Icons.info_outline;
      statusText = 'Near Limit';
    } else if (percentageUsed >= 75) {
      statusColor = Colors.amber;
      statusIcon = Icons.trending_up;
      statusText = 'On Track';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Good';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category name and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(budget.category),
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit Budget',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete Budget',
                      color: Colors.red[400],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Budget vs Spent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${budgetAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${spent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentageUsed > 100 ? 1.0 : percentageUsed / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),

            // Remaining/Over text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverBudget
                      ? 'Over by ৳${remaining.abs().toStringAsFixed(2)}'
                      : 'Remaining ৳${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverBudget ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${percentageUsed.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'utilities':
        return Icons.lightbulb;
      case 'rent':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}
