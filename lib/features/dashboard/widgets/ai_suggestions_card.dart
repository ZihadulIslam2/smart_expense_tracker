import 'package:flutter/material.dart';
import '../../../core/widgets/markdown_text_widget.dart';

class AISuggestionsCard extends StatelessWidget {
  final String suggestions;
  final bool isLoading;

  const AISuggestionsCard({
    super.key,
    required this.suggestions,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Financial Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
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
                : suggestions.isEmpty
                ? Text(
                    'Waiting for AI suggestions...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : MarkdownTextWidget(
                    markdown: suggestions,
                    accentColor: Colors.blue[700],
                    baseStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                      height: 1.5,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
