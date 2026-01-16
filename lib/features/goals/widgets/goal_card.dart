import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onTap;
  final VoidCallback onAddContribution;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    required this.onAddContribution,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getCategoryIcon() {
    switch (goal.category.toLowerCase()) {
      case 'emergency fund':
        return Icons.health_and_safety;
      case 'vacation':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'house':
        return Icons.home;
      case 'education':
        return Icons.school;
      case 'retirement':
        return Icons.elderly;
      case 'wedding':
        return Icons.celebration;
      case 'gadget':
        return Icons.devices;
      default:
        return Icons.flag;
    }
  }

  Color _getProgressColor() {
    final progress = goal.progressPercentage;
    if (progress >= 100) return Colors.green;
    if (progress >= 75) return Colors.lightGreen;
    if (progress >= 50) return Colors.orange;
    if (progress >= 25) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getStatusColor() {
    if (goal.isAchieved) return Colors.green;
    if (goal.isOverdue) return Colors.red;
    if (goal.daysRemaining < 30) return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText() {
    if (goal.isAchieved) return 'Achieved! 🎉';
    if (goal.isOverdue) return 'Overdue';
    if (goal.daysRemaining < 30) return '${goal.daysRemaining} days left';
    if (goal.monthsRemaining == 1) return '1 month left';
    return '${goal.monthsRemaining} months left';
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon, title, and menu
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getStatusColor(),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // More menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              if (goal.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    goal.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '৳${numberFormat.format(goal.currentAmount)} / ৳${numberFormat.format(goal.targetAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${goal.progressPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal.progressPercentage / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  // Remaining amount
                  Expanded(
                    child: _buildStatChip(
                      icon: Icons.attach_money,
                      label: 'Remaining',
                      value: '৳${numberFormat.format(goal.remainingAmount)}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status
                  Expanded(
                    child: _buildStatChip(
                      icon: Icons.calendar_today,
                      label: 'Status',
                      value: _getStatusText(),
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Suggested contribution
              if (!goal.isAchieved)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                            children: [
                              const TextSpan(text: 'Suggested: '),
                              TextSpan(
                                text:
                                    '৳${numberFormat.format(goal.suggestedMonthlyContribution)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const TextSpan(text: '/month'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Add contribution button
              if (!goal.isAchieved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddContribution,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Contribution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
