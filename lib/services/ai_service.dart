import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/services/data_cache_service.dart';

/// AI Service for financial analysis using Google Gemini
class AIService {
  late final GenerativeModel _model;
  final String _apiKey;
  final DataCacheService? _cacheService;

  AIService({String? apiKey, DataCacheService? cacheService})
    : _apiKey = apiKey ?? (dotenv.env['GEMINI_API_KEY'] ?? ''),
      _cacheService = cacheService {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    _initializeModel();
  }

  void _initializeModel() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
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
    required Map<String, double> budgetStatus,
    required int totalTransactions,
    bool forceRefresh = false,
  }) async {
    try {
      final comprehensiveData = await _getComprehensiveAnalysis(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: monthlyTrend,
        budgetStatus: budgetStatus,
        totalTransactions: totalTransactions,
        forceRefresh: forceRefresh,
      );

      return {
        'analysis': comprehensiveData['financial_analysis'] ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('[AI ERROR] Error getting financial analysis: $e');
      return {
        'analysis': 'Unable to generate analysis',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get spending advice based on category analysis
  Future<String> getSpendingAdvice({
    required Map<String, double> categorySpending,
    required double totalIncome,
    bool forceRefresh = false,
  }) async {
    try {
      final comprehensiveData = await _getComprehensiveAnalysis(
        totalIncome: totalIncome,
        totalExpense: categorySpending.values.fold(0.0, (a, b) => a + b),
        categorySpending: categorySpending,
        monthlyTrend: [],
        budgetStatus: {},
        totalTransactions: 0,
        forceRefresh: forceRefresh,
      );

      return comprehensiveData['spending_advice'] ??
          'Unable to generate advice';
    } catch (e) {
      print('[AI ERROR] Error getting spending advice: $e');
      return 'Unable to generate advice at this time';
    }
  }

  /// Get saving tips based on current financial situation
  Future<String> getSavingTips({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    bool forceRefresh = false,
  }) async {
    try {
      final comprehensiveData = await _getComprehensiveAnalysis(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: [],
        budgetStatus: {},
        totalTransactions: 0,
        forceRefresh: forceRefresh,
      );

      return comprehensiveData['saving_tips'] ?? 'Unable to generate tips';
    } catch (e) {
      print('[AI ERROR] Error getting saving tips: $e');
      return 'Unable to generate tips at this time';
    }
  }

  /// Get financial warnings based on budget and spending patterns
  Future<List<String>> getFinancialWarnings({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required Map<String, double> budgetStatus,
    bool forceRefresh = false,
  }) async {
    try {
      final comprehensiveData = await _getComprehensiveAnalysis(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: [],
        budgetStatus: budgetStatus,
        totalTransactions: 0,
        forceRefresh: forceRefresh,
      );

      final warningsText = comprehensiveData['financial_warnings'] ?? '';
      if (warningsText.isEmpty) return [];

      return warningsText
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
    } catch (e) {
      print('[AI ERROR] Error getting financial warnings: $e');
      return ['Unable to generate warnings'];
    }
  }

  /// Build comprehensive prompt for all financial analysis in one go
  String _buildComprehensivePrompt({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required List<Map<String, dynamic>> monthlyTrend,
    required Map<String, double> budgetStatus,
    required int totalTransactions,
    required List<Map<String, dynamic>> goals,
  }) {
    final savings = totalIncome - totalExpense;
    final savingsPercentage = totalIncome > 0
        ? ((savings / totalIncome) * 100)
        : 0;

    // Build trend analysis
    String trendAnalysis = '';
    if (monthlyTrend.isNotEmpty) {
      trendAnalysis =
          'Monthly trend: ${monthlyTrend.map((m) => '${m['month']}: ৳${(m['expense'] as num).toStringAsFixed(0)}').join(', ')}';
    }

    final topCategory = _getTopCategory(categorySpending);
    final totalSpending = categorySpending.values.fold<double>(
      0.0,
      (a, b) => a + b,
    );

    return '''You are a financial advisor AI. Analyze this comprehensive financial data and provide insights in the exact format below. Respond with ONLY these sections in this order.

[FINANCIAL_OVERVIEW_DATA]
- Total Income: ৳${totalIncome.toStringAsFixed(0)}
- Total Expenses: ৳${totalExpense.toStringAsFixed(0)}
- Savings: ৳${savings.toStringAsFixed(0)} (${savingsPercentage.toStringAsFixed(1)}%)
- Total Transactions: $totalTransactions

[SPENDING_DATA]
${categorySpending.entries.map((e) => '- ${e.key}: ৳${e.value.toStringAsFixed(2)}').join('\n')}

[BUDGET_STATUS]
${budgetStatus.entries.map((e) => '- ${e.key}: ${(e.value * 100).toStringAsFixed(0)}% of budget').join('\n')}

[TRENDS]
$trendAnalysis

[GOALS_DATA]
${goals.isNotEmpty ? goals.asMap().entries.map((entry) {
            final goal = entry.value;
            return '${entry.key + 1}. ${goal['title']} - Target: ৳${goal['targetAmount']}, Current: ৳${goal['currentAmount']}, Progress: ${goal['progress']}%';
          }).join('\n') : 'No goals set'}

---

Now provide responses for each section. Use these exact headers for each section:

[FINANCIAL_ANALYSIS]
Provide: 1) Overall financial health assessment (1-2 short sentences), 2) Key strengths (2-3 bullet points), 3) Areas of concern (2-3 bullet points), 4) Specific action items (2 recommendations), 5) Positive note (1 encouraging sentence)

[SPENDING_ADVICE]
Provide: 2-3 specific, actionable spending advice points based on the spending profile. Top category: $topCategory. Savings rate: ${savingsPercentage.toStringAsFixed(1)}%. Be concise and practical.

[SAVING_TIPS]
Provide: 3-4 practical saving tips specific to this financial profile. Include one emergency fund tip. Total spending: ৳${totalSpending.toStringAsFixed(0)}

[FINANCIAL_WARNINGS]
Provide: List each warning on a new line. Check: 1) Overspending (expense > income), 2) Over-budget categories, 3) Categories > 40% of spending, 4) Savings rate < 10%. Format: ⚠️ or 🔴 or 📊 or 💾 + warning text

[GOAL_INSIGHTS]
Provide: 1) Assessment of goal achievability, 2) Priority recommendations (which goals first), 3) Adjustment suggestions for monthly contributions, 4) Motivational insights, 5) Spending adjustments to meet goals faster. Keep to max 150 words.''';
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
    bool forceRefresh = false,
  }) async {
    try {
      final comprehensiveData = await _getComprehensiveAnalysis(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: [],
        budgetStatus: {},
        totalTransactions: 0,
        forceRefresh: forceRefresh,
        goals: goals,
      );

      return {
        'insights': comprehensiveData['goal_insights'] ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('[AI ERROR] Error getting goal insights: $e');
      return {
        'insights': 'Unable to generate goal insights at this time.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Main method: Get comprehensive analysis with a single API call
  Future<Map<String, dynamic>> _getComprehensiveAnalysis({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categorySpending,
    required List<Map<String, dynamic>> monthlyTrend,
    required Map<String, double> budgetStatus,
    required int totalTransactions,
    List<Map<String, dynamic>>? goals,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'ai_comprehensive_analysis';

    // Check cache first
    if (!forceRefresh && _cacheService != null) {
      if (_cacheService!.isCacheValid(cacheKey)) {
        try {
          final cached = await _cacheService!
              .getCachedData<Map<String, dynamic>>(
                cacheKey,
                (json) => Map<String, dynamic>.from(json as Map),
              );
          if (cached != null) {
            print('[CACHE] Using cached comprehensive analysis');
            return cached;
          }
        } catch (e) {
          print('[CACHE] Error reading cached comprehensive analysis: $e');
        }
      }
    }

    try {
      final prompt = _buildComprehensivePrompt(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        categorySpending: categorySpending,
        monthlyTrend: monthlyTrend,
        budgetStatus: budgetStatus,
        totalTransactions: totalTransactions,
        goals: goals ?? [],
      );

      print('[AI] Making single comprehensive API call...');
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse the response into sections
      final result = _parseComprehensiveResponse(responseText);

      // Cache the result
      if (_cacheService != null) {
        await _cacheService!.cacheData(cacheKey, result);
        print('[CACHE] Cached comprehensive analysis');
      }

      return result;
    } catch (e) {
      print('[AI ERROR] Error generating comprehensive analysis: $e');
      return {
        'financial_analysis': 'Unable to generate analysis',
        'spending_advice': 'Unable to generate advice',
        'saving_tips': 'Unable to generate tips',
        'financial_warnings': '',
        'goal_insights': 'Unable to generate insights',
      };
    }
  }

  /// Parse comprehensive response into sections
  Map<String, dynamic> _parseComprehensiveResponse(String response) {
    final sections = <String, String>{};

    // Extract each section
    final sectionKeys = [
      'FINANCIAL_ANALYSIS',
      'SPENDING_ADVICE',
      'SAVING_TIPS',
      'FINANCIAL_WARNINGS',
      'GOAL_INSIGHTS',
    ];

    for (final key in sectionKeys) {
      final pattern = RegExp(r'\[' + key + r'\](.*?)(?=\[|$)', dotAll: true);
      final match = pattern.firstMatch(response);
      if (match != null) {
        sections[key.toLowerCase()] = match.group(1)?.trim() ?? '';
      }
    }

    return {
      'financial_analysis': sections['financial_analysis'] ?? '',
      'spending_advice': sections['spending_advice'] ?? '',
      'saving_tips': sections['saving_tips'] ?? '',
      'financial_warnings': sections['financial_warnings'] ?? '',
      'goal_insights': sections['goal_insights'] ?? '',
    };
  }
}
