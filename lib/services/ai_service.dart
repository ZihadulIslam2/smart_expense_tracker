import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// AI Service for financial analysis using Google Gemini
class AIService {
  late final GenerativeModel _model;
  final String _apiKey;

  AIService({String? apiKey})
    : _apiKey = apiKey ?? (dotenv.env['GEMINI_API_KEY'] ?? '') {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    _initializeModel();
  }

  void _initializeModel() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  /// Get comprehensive financial analysis and suggestions
  Future<Map<String, dynamic>> getFinancialAnalysis({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required List<Map<String, dynamic>> monthlyTrend,
    required Map<String, double> budgetStatus, // category -> spent/budget ratio
    required int totalTransactions,
  }) async {
    try {
      final prompt = _buildFinancialAnalysisPrompt(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: monthlyTrend,
        budgetStatus: budgetStatus,
        totalTransactions: totalTransactions,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // Parse the response
      return _parseFinancialAnalysis(text);
    } catch (e) {
      print('[AI ERROR] Error generating financial analysis: $e');
      return {
        'error': 'Unable to generate analysis: ${e.toString()}',
        'suggestions': [],
        'warnings': [],
        'tips': [],
      };
    }
  }

  /// Get spending advice based on category analysis
  Future<String> getSpendingAdvice({
    required Map<String, double> categorySpending,
    required double totalIncome,
  }) async {
    try {
      final topCategory = _getTopCategory(categorySpending);
      final savingsRate = totalIncome > 0
          ? (((totalIncome - categorySpending.values.fold(0, (a, b) => a + b)) /
                    totalIncome) *
                100)
          : 0;

      final prompt =
          '''Based on this spending profile:
- Top spending category: $topCategory
- Savings rate: ${savingsRate.toStringAsFixed(1)}%
- Categories: ${categorySpending.entries.map((e) => '${e.key}: ৳${e.value.toStringAsFixed(0)}').join(', ')}

Provide 2-3 specific, actionable spending advice points to optimize spending. Be concise and practical.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate advice';
    } catch (e) {
      print('[AI ERROR] Error generating spending advice: $e');
      return 'Unable to generate advice at this time';
    }
  }

  /// Get saving tips based on current financial situation
  Future<String> getSavingTips({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
  }) async {
    try {
      final savings = totalIncome - totalExpense;
      final savingsPercentage = totalIncome > 0
          ? ((savings / totalIncome) * 100)
          : 0;

      final prompt =
          '''Given this financial situation:
- Monthly income: ৳${totalIncome.toStringAsFixed(0)}
- Monthly expense: ৳${totalExpense.toStringAsFixed(0)}
- Current savings: ৳${savings.toStringAsFixed(0)} (${savingsPercentage.toStringAsFixed(1)}%)
- Spending breakdown: ${categorySpending.entries.map((e) => '${e.key}: ৳${e.value.toStringAsFixed(0)}').join(', ')}

Provide 3-4 practical saving tips specific to this financial profile. Include one emergency fund tip.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate tips';
    } catch (e) {
      print('[AI ERROR] Error generating saving tips: $e');
      return 'Unable to generate tips at this time';
    }
  }

  /// Get financial warnings
  Future<List<String>> getFinancialWarnings({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required Map<String, double> budgetStatus,
  }) async {
    try {
      final warnings = <String>[];

      // Check if overspending
      if (totalExpense > totalIncome) {
        warnings.add(
          '⚠️ OVERSPENDING: You\'re spending ৳${(totalExpense - totalIncome).toStringAsFixed(2)} more than income',
        );
      }

      // Check over-budget categories
      final overBudgetCategories = budgetStatus.entries
          .where((e) => e.value > 1.0)
          .map((e) => e.key)
          .toList();
      if (overBudgetCategories.isNotEmpty) {
        warnings.add(
          '🔴 OVER BUDGET: ${overBudgetCategories.join(", ")} exceeded limits',
        );
      }

      // Check if spending is too high in any category
      final totalSpending = categorySpending.values.fold(
        0.0,
        (sum, a) => sum + a,
      );
      if (totalSpending > 0) {
        for (var entry in categorySpending.entries) {
          final percentage = (entry.value / totalSpending) * 100;
          if (percentage > 40) {
            warnings.add(
              '📊 ALERT: ${entry.key} represents ${percentage.toStringAsFixed(1)}% of spending',
            );
          }
        }
      }

      // Check savings rate
      if (totalIncome > 0) {
        final savingsRate = ((totalIncome - totalExpense) / totalIncome) * 100;
        if (savingsRate < 10) {
          warnings.add(
            '💾 LOW SAVINGS: Only saving ${savingsRate.toStringAsFixed(1)}% of income',
          );
        }
      }

      return warnings;
    } catch (e) {
      print('[AI ERROR] Error generating warnings: $e');
      return ['Unable to generate warnings'];
    }
  }

  /// Build detailed financial analysis prompt
  String _buildFinancialAnalysisPrompt({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required List<Map<String, dynamic>> monthlyTrend,
    required Map<String, double> budgetStatus,
    required int totalTransactions,
  }) {
    final savings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? ((savings / totalIncome) * 100) : 0;

    final trendAnalysis = monthlyTrend.isNotEmpty
        ? 'Recent trend: ${monthlyTrend.map((m) => '${m['month']}: ${m['expense']}').join(', ')}'
        : 'No trend data';

    return '''You are a professional financial advisor. Analyze this person's finances and provide insights:

FINANCIAL SUMMARY:
- Total Income: ৳${totalIncome.toStringAsFixed(2)}
- Total Expense: ৳${totalExpense.toStringAsFixed(2)}
- Net Savings: ৳${savings.toStringAsFixed(2)}
- Savings Rate: ${savingsRate.toStringAsFixed(1)}%
- Total Transactions: $totalTransactions

SPENDING BREAKDOWN:
${categorySpending.entries.map((e) => '- ${e.key}: ৳${e.value.toStringAsFixed(2)}').join('\n')}

BUDGET STATUS:
${budgetStatus.entries.map((e) => '- ${e.key}: ${(e.value * 100).toStringAsFixed(0)}% of budget used').join('\n')}

TRENDS:
$trendAnalysis

Please provide:
1. Overall financial health assessment (1-2 sentences)
2. Key strengths (2-3 bullet points)
3. Areas of concern (2-3 bullet points)
4. Specific action items (3-4 recommendations)
5. Positive note (1 encouraging sentence)

Format your response clearly with headers. Be specific and use the actual numbers provided.''';
  }

  /// Parse financial analysis response
  Map<String, dynamic> _parseFinancialAnalysis(String response) {
    return {
      'analysis': response,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get top spending category
  String _getTopCategory(Map<String, double> categorySpending) {
    if (categorySpending.isEmpty) return 'N/A';
    return categorySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get AI insights for financial goals
  Future<Map<String, dynamic>> getGoalInsights({
    required List<Map<String, dynamic>> goals,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
  }) async {
    try {
      final prompt = _buildGoalInsightsPrompt(
        goals: goals,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      return {'insights': text, 'timestamp': DateTime.now().toIso8601String()};
    } catch (e) {
      print('[AI ERROR] Error generating goal insights: $e');
      return {
        'insights': 'Unable to generate goal insights at this time.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  String _buildGoalInsightsPrompt({
    required List<Map<String, dynamic>> goals,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('As a financial advisor AI, analyze these financial goals:');
    buffer.writeln();
    buffer.writeln('FINANCIAL CONTEXT:');
    buffer.writeln('- Monthly Income: ৳${totalIncome.toStringAsFixed(0)}');
    buffer.writeln('- Monthly Expense: ৳${totalExpense.toStringAsFixed(0)}');
    buffer.writeln(
      '- Available for Savings: ৳${(totalIncome - totalExpense).toStringAsFixed(0)}',
    );
    buffer.writeln();
    buffer.writeln('GOALS:');

    for (var i = 0; i < goals.length; i++) {
      final goal = goals[i];
      buffer.writeln('${i + 1}. ${goal['title']}');
      buffer.writeln('   Target: ৳${goal['targetAmount']}');
      buffer.writeln('   Current: ৳${goal['currentAmount']}');
      buffer.writeln('   Remaining: ৳${goal['remaining']}');
      buffer.writeln('   Progress: ${goal['progress']}%');
      buffer.writeln('   Deadline: ${goal['deadline']}');
      buffer.writeln('   Suggested Monthly: ৳${goal['suggestedMonthly']}');
      buffer.writeln();
    }

    buffer.writeln('Please provide:');
    buffer.writeln('1. Assessment of goal achievability (realistic or not)');
    buffer.writeln(
      '2. Priority recommendations (which goals to focus on first)',
    );
    buffer.writeln(
      '3. Adjustment suggestions (if monthly contributions seem too high/low)',
    );
    buffer.writeln('4. Motivational insights to stay on track');
    buffer.writeln('5. Spending adjustments to meet goals faster');
    buffer.writeln();
    buffer.writeln('Keep response concise and actionable (max 200 words).');

    return buffer.toString();
  }
}
