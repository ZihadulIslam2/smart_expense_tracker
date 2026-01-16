import 'package:flutter/material.dart';

/// A widget that renders Markdown-formatted text as rich Flutter widgets
/// Supports:
/// - Headers (# text)
/// - Bold text (**text**)
/// - Bullet points (- text)
/// - Numbered lists (1. text)
/// - Line breaks
class MarkdownTextWidget extends StatelessWidget {
  final String markdown;
  final TextStyle? baseStyle;
  final Color? accentColor;
  final double bulletPointSize;

  const MarkdownTextWidget({
    super.key,
    required this.markdown,
    this.baseStyle,
    this.accentColor,
    this.bulletPointSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split('\n');
    final widgets = <Widget>[];

    TextStyle defaultStyle =
        baseStyle ??
        TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[800]);

    Color defaultAccentColor = accentColor ?? Colors.blue.shade700;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Header (# text or ## text, etc.)
      if (line.startsWith('#')) {
        int headerLevel = 0;
        for (int i = 0; i < line.length && line[i] == '#'; i++) {
          headerLevel++;
        }
        final headerText = line.substring(headerLevel).trim();
        final headerSize = 18 - (headerLevel * 1.5).clamp(0, 10).toDouble();

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: headerSize,
                fontWeight: FontWeight.bold,
                color: defaultAccentColor,
              ),
            ),
          ),
        );
      }
      // Bullet point (- text)
      else if (line.trimLeft().startsWith('-') && line.startsWith('  ')) {
        final bulletText = line.substring(line.indexOf('-') + 1).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: bulletPointSize,
                    color: defaultAccentColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(bulletText, style: defaultStyle)),
              ],
            ),
          ),
        );
      }
      // Numbered list (1. text, 2. text, etc.)
      else if (RegExp(r'^\s*\d+\.\s').hasMatch(line)) {
        final numberMatch = RegExp(r'^\s*(\d+)\.\s(.*)').firstMatch(line);
        if (numberMatch != null) {
          final number = numberMatch.group(1);
          final listText = numberMatch.group(2) ?? '';

          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: defaultAccentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(listText, style: defaultStyle)),
                ],
              ),
            ),
          );
        }
      }
      // Regular text (can contain **bold** formatting)
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _RichTextFormatter(
              text: line,
              baseStyle: defaultStyle,
              accentColor: defaultAccentColor,
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}

/// Helper widget to format text with bold (**text**) formatting
class _RichTextFormatter extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final Color accentColor;

  const _RichTextFormatter({
    required this.text,
    required this.baseStyle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.*?)\*\*');

    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add text before bold
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
