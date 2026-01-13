import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  // Using v1beta with gemini-pro model (stable and widely available)
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

  /// Debug method to validate API configuration
  void debugGeminiSetup() {
    print('\n========== GEMINI API DEBUG ==========');
    print('[DEBUG] Model URL: $_baseUrl');
    print('[DEBUG] API Key configured: ${apiKey.isNotEmpty}');
    print('[DEBUG] API Key length: ${apiKey.length}');
    print(
      '[DEBUG] API Key starts with: ${apiKey.isNotEmpty ? apiKey.substring(0, 10) : 'N/A'}...',
    );
    print(
      '[DEBUG] Full API URL with key: $_baseUrl?key=${apiKey.isNotEmpty ? apiKey.substring(0, 10) : 'N/A'}...',
    );
    print('=====================================\n');
  }

  /// Prepares user financial data for AI analysis
  String prepareFinancialData({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required List<Map<String, dynamic>> monthlyTrend,
    required Map<String, double> goalsProgress,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('FINANCIAL DATA FOR ANALYSIS:');
    buffer.writeln('=============================');
    buffer.writeln('Total Monthly Income: \$$totalIncome');
    buffer.writeln('Total Monthly Expense: \$$totalExpense');
    buffer.writeln(
      'Net Savings: \$${(totalIncome - totalExpense).toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Savings Rate: ${((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln('\nSPENDING BY CATEGORY:');

    categorySpending.forEach((category, amount) {
      final percentage = totalExpense > 0 ? (amount / totalExpense * 100) : 0;
      buffer.writeln(
        '  - $category: \$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(2)}%)',
      );
    });

    if (monthlyTrend.isNotEmpty) {
      buffer.writeln('\nMONTHLY TREND (Last 6 months):');
      for (var month in monthlyTrend) {
        buffer.writeln(
          '  - ${month['month']}: Income: \$${month['income']}, Expense: \$${month['expense']}',
        );
      }
    }

    if (goalsProgress.isNotEmpty) {
      buffer.writeln('\nFINANCIAL GOALS PROGRESS:');
      goalsProgress.forEach((goal, progress) {
        buffer.writeln('  - $goal: ${progress.toStringAsFixed(1)}% achieved');
      });
    }

    return buffer.toString();
  }

  /// Calls Gemini API to get financial suggestions
  Future<String> getFinancialSuggestions({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required List<Map<String, dynamic>> monthlyTrend,
    required Map<String, double> goalsProgress,
  }) async {
    try {
      print('\n[GEMINI] ========== Financial Suggestions Request ==========');

      if (apiKey.isEmpty) {
        print('[GEMINI ERROR] API Key is empty!');
        return 'AI suggestions unavailable. Please configure your Gemini API key.';
      }

      print('[GEMINI] API Key configured: YES');
      print('[GEMINI] Preparing financial data...');

      final financialData = prepareFinancialData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: monthlyTrend,
        goalsProgress: goalsProgress,
      );

      final prompt =
          '''Based on the following financial data, provide 3-4 concise and actionable financial advice tips. 
Keep each tip under 2 sentences. Focus on practical improvements for spending habits and savings.

$financialData

Provide the tips in a numbered list format.''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 200,
        },
      };

      print(
        '[GEMINI] Request body prepared, size: ${jsonEncode(requestBody).length} bytes',
      );
      print('[GEMINI] Sending request to: $_baseUrl');
      print('[GEMINI] Full URL: $_baseUrl?key=${apiKey.substring(0, 10)}...');

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'SmartExpenseTracker/1.0',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('[GEMINI] Response Status: ${response.statusCode}');
      print('[GEMINI] Response Headers: ${response.headers}');
      print('[GEMINI] Response Body Length: ${response.body.length}');
      print('[GEMINI] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('[GEMINI] ✓ Success! Parsing response...');
        final decodedResponse = jsonDecode(response.body);
        print('[GEMINI] Decoded response keys: ${decodedResponse.keys}');

        final candidates = decodedResponse['candidates'] as List?;
        print('[GEMINI] Candidates found: ${candidates?.length ?? 0}');

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          print('[GEMINI] Content keys: ${content?.keys}');

          final parts = content?['parts'] as List?;
          print('[GEMINI] Parts found: ${parts?.length ?? 0}');

          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] ?? 'No suggestions available.';
            print(
              '[GEMINI] ✓ Successfully extracted text: ${text.substring(0, 50)}...',
            );
            print(
              '[GEMINI] ==========================================================\n',
            );
            return text;
          }
        }
        print('[GEMINI] No candidates or parts found in response');
        return 'No suggestions available at the moment.';
      } else {
        print('[GEMINI] ✗ API Error: ${response.statusCode}');
        print('[GEMINI] Error details: ${response.body}');
        print(
          '[GEMINI] ==========================================================\n',
        );
        return 'Unable to fetch AI suggestions (Error: ${response.statusCode}). Please check your API key in .env file.';
      }
    } catch (e, stackTrace) {
      print('[GEMINI] ✗ Exception occurred:');
      print('[GEMINI] Error: $e');
      print('[GEMINI] Stack trace: $stackTrace');
      print(
        '[GEMINI] ==========================================================\n',
      );
      return 'Error fetching AI suggestions: ${e.toString()}';
    }
  }

  /// Gets a quick financial tip based on highest spending category
  Future<String> getQuickTip({
    required Map<String, double> categorySpending,
    required double totalExpense,
  }) async {
    try {
      if (apiKey.isEmpty) {
        return 'Enable AI for quick tips.';
      }

      if (categorySpending.isEmpty) {
        return 'Start tracking expenses to get personalized tips.';
      }

      // Find highest spending category
      String highestCategory = '';
      double highestAmount = 0;

      categorySpending.forEach((category, amount) {
        if (amount > highestAmount) {
          highestAmount = amount;
          highestCategory = category;
        }
      });

      final percentage = totalExpense > 0
          ? (highestAmount / totalExpense * 100)
          : 0;

      final prompt =
          'Give a 1-sentence financial tip about reducing $highestCategory spending which is currently \$$highestAmount (${percentage.toStringAsFixed(1)}% of total expenses).';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 50},
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final candidates = decodedResponse['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          final parts = content?['parts'] as List?;

          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'Unable to generate tip.';
          }
        }
      } else {
        print('Quick tip API error: ${response.statusCode}');
      }
      return 'Unable to generate quick tip.';
    } catch (e) {
      print('Error getting quick tip: $e');
      return 'Error: ${e.toString()}';
    }
  }

  /// Gets AI-powered savings goals and category reduction advice
  Future<String> getSavingsGoalsAdvice({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
  }) async {
    try {
      print('\n[GEMINI] ========== Savings Goals Advice Request ==========');

      if (apiKey.isEmpty) {
        print('[GEMINI ERROR] API Key is empty!');
        return 'Enable AI for personalized savings goals.';
      }

      if (totalIncome == 0) {
        print('[GEMINI] Total income is 0');
        return 'Add income to get personalized savings recommendations.';
      }

      print('[GEMINI] API Key configured: YES');
      final currentSavingsRate = totalIncome > 0
          ? ((totalIncome - totalExpense) / totalIncome * 100)
          : 0;

      final targetSavingsRate = 20.0; // 20% savings goal
      final savingsGap = targetSavingsRate - currentSavingsRate;

      // Find top 3 spending categories
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      String topCategories = sortedCategories
          .take(3)
          .map((e) {
            final percentage = totalExpense > 0
                ? (e.value / totalExpense * 100)
                : 0;
            return '${e.key} (${percentage.toStringAsFixed(1)}%)';
          })
          .join(', ');

      final prompt =
          '''Based on the following financial situation, provide 3-4 specific, actionable savings goals:

CURRENT SITUATION:
- Monthly Income: \$$totalIncome
- Monthly Expense: \$$totalExpense
- Current Savings Rate: ${currentSavingsRate.toStringAsFixed(1)}%
- Target Savings Rate: ${targetSavingsRate.toStringAsFixed(1)}%
- Amount to Save More: \$${(totalIncome * savingsGap / 100).toStringAsFixed(2)} per month
- Top Spending Categories: $topCategories

PROVIDE:
1. Monthly savings target (specific amount)
2. Which category to reduce and by how much
3. Realistic timeline to reach 20% savings rate
4. One bonus money-saving habit

Keep responses concise and specific to their spending.''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 250,
        },
      };

      print(
        '[GEMINI] Request body prepared, size: ${jsonEncode(requestBody).length} bytes',
      );
      print('[GEMINI] Sending request to: $_baseUrl');

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'SmartExpenseTracker/1.0',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('[GEMINI] Response Status: ${response.statusCode}');
      print('[GEMINI] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('[GEMINI] ✓ Success! Parsing response...');
        final decodedResponse = jsonDecode(response.body);
        final candidates = decodedResponse['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          final parts = content?['parts'] as List?;

          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] ?? 'No goals generated.';
            print(
              '[GEMINI] ✓ Successfully extracted text: ${text.substring(0, 50)}...',
            );
            print(
              '[GEMINI] ==========================================================\n',
            );
            return text;
          }
        }
        print('[GEMINI] No candidates or parts found');
        return 'Unable to generate savings goals.';
      } else {
        print('[GEMINI] ✗ API Error: ${response.statusCode}');
        print('[GEMINI] Error Body: ${response.body}');
        print(
          '[GEMINI] ==========================================================\n',
        );
        return 'Unable to generate goals (Error: ${response.statusCode})';
      }
    } catch (e, stackTrace) {
      print('[GEMINI] ✗ Exception occurred:');
      print('[GEMINI] Error: $e');
      print('[GEMINI] Stack trace: $stackTrace');
      print(
        '[GEMINI] ==========================================================\n',
      );
      return 'Error: ${e.toString()}';
    }
  }

  /// Gets quick savings target recommendation
  Future<String> getQuickSavingsTarget({
    required double totalIncome,
    required double totalExpense,
  }) async {
    try {
      if (apiKey.isEmpty || totalIncome == 0) {
        return 'Aim for 20% monthly savings';
      }

      final currentSavingsRate = totalIncome > 0
          ? ((totalIncome - totalExpense) / totalIncome * 100)
          : 0;

      final targetAmount = totalIncome * 0.20; // 20% of income
      final currentSavings = totalIncome - totalExpense;
      final needToSave = (targetAmount - currentSavings).toStringAsFixed(0);

      final prompt =
          'In one sentence, motivate someone to save \$$needToSave more monthly to reach their 20% savings goal (currently at ${currentSavingsRate.toStringAsFixed(1)}% savings).';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 40},
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('Quick Savings Target API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final candidates = decodedResponse['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          final parts = content?['parts'] as List?;

          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'Keep saving towards 20%!';
          }
        }
      } else {
        print('Quick Savings Target API Error: ${response.statusCode}');
      }
      return 'Keep saving towards 20%!';
    } catch (e) {
      print('Error getting quick savings target: $e');
      return 'Error: ${e.toString()}';
    }
  }
}
