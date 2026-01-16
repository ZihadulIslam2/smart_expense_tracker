import 'package:flutter/material.dart';
import '../../../core/widgets/markdown_text_widget.dart';

/// Widget to display tips and advice
class TipsCard extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onRetry;

  const TipsCard({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    required this.icon,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.05),
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
              MarkdownTextWidget(
                markdown: content,
                accentColor: color,
                baseStyle: TextStyle(
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
