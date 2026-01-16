import 'package:flutter/material.dart';

/// Widget to display AI suggestions with formatted text
class SuggestionCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onRetry;

  const SuggestionCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRetry != null && !isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: color,
                    onPressed: onRetry,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SelectableText(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey[800],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
