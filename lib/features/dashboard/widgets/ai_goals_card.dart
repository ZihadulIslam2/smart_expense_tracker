import 'package:flutter/material.dart';
import '../../../core/widgets/markdown_text_widget.dart';

class AIGoalsCard extends StatelessWidget {
  final String goalsAdvice;
  final bool isLoading;

  const AIGoalsCard({
    super.key,
    required this.goalsAdvice,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Savings Goals & Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            isLoading
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : goalsAdvice.isEmpty
                ? Text(
                    'Waiting for savings recommendations...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : MarkdownTextWidget(
                    markdown: goalsAdvice,
                    accentColor: Colors.green[700],
                    baseStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.green[900],
                      height: 1.5,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
