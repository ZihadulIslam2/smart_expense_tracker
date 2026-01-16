# AI Refresh Feature - Developer Quick Reference

## 🚀 Quick Start

### Enable Refresh on a Card

```dart
SuggestionCard(
  title: 'My Insight',
  content: _insightData,
  isLoading: _isLoading,
  onRetry: () async {
    await _generateInsight(forceRefresh: true);
  },
)
```

### Generate Insight with Refresh Support

```dart
Future<void> _generateInsight({bool forceRefresh = false}) async {
  setState(() => _isLoading = true);

  try {
    final result = await _aiService.getFinancialAnalysis(
      // ... parameters ...
      forceRefresh: forceRefresh,
    );

    setState(() {
      _insightData = result['analysis'];
      _isLoading = false;
    });
  } catch (e) {
    print('Error: $e');
    setState(() => _isLoading = false);
  }
}
```

---

## 📋 Checklist: Adding Refresh to New Card

- [ ] Add `VoidCallback? onRetry` parameter to widget
- [ ] Add `bool isLoading` parameter to widget
- [ ] Add refresh button to widget UI
- [ ] Show button only when `onRetry != null && !isLoading`
- [ ] Pass `onRetry: () async { await method(forceRefresh: true) }` from screen
- [ ] Add `forceRefresh = false` parameter to generation method
- [ ] Pass `forceRefresh: forceRefresh` to AIService methods
- [ ] Test both cache (no refresh) and fresh (with refresh) paths

---

## 🔗 Method Signatures

### AIService Methods with forceRefresh

```dart
// Financial Analysis
Future<Map<String, dynamic>> getFinancialAnalysis({
  required double totalIncome,
  required double totalExpense,
  required Map<String, double> categorySpending,
  required List<Map<String, dynamic>> monthlyTrend,
  required Map<String, double> budgetStatus,
  required int totalTransactions,
  bool forceRefresh = false,  // ← NEW
}) async

// Spending Advice
Future<String> getSpendingAdvice({
  required Map<String, double> categorySpending,
  required double totalIncome,
  bool forceRefresh = false,  // ← NEW
}) async

// Saving Tips
Future<String> getSavingTips({
  required double totalIncome,
  required double totalExpense,
  required Map<String, double> categorySpending,
  bool forceRefresh = false,  // ← NEW
}) async

// Financial Warnings
Future<List<String>> getFinancialWarnings({
  required double totalIncome,
  required double totalExpense,
  required Map<String, double> categorySpending,
  required Map<String, double> budgetStatus,
  bool forceRefresh = false,  // ← NEW
}) async

// Goal Insights
Future<Map<String, dynamic>> getGoalInsights({
  required List<Map<String, dynamic>> goals,
  required double totalIncome,
  required double totalExpense,
  required Map<String, double> categorySpending,
  bool forceRefresh = false,  // ← NEW
}) async
```

---

## 📦 Widget Signatures

### SuggestionCard

```dart
SuggestionCard({
  required String title,
  required String content,
  required IconData icon,
  required Color color,
  bool isLoading = false,
  VoidCallback? onRetry,  // ← NEW
})
```

### WarningsCard

```dart
WarningsCard({
  required List<String> warnings,
  bool isLoading = false,
  VoidCallback? onRetry,  // ← NEW
})
```

### TipsCard

```dart
TipsCard({
  required String title,
  required String content,
  required Color color,
  required IconData icon,
  bool isLoading = false,
  VoidCallback? onRetry,  // ← NEW
})
```

---

## 🎯 Common Patterns

### Pattern 1: Single Insight

```dart
// In screen state
Future<void> _generateAnalysis({bool forceRefresh = false}) async {
  setState(() => _loading = true);
  try {
    final result = await _aiService.getFinancialAnalysis(
      // ... params ...
      forceRefresh: forceRefresh,
    );
    setState(() {
      _analysis = result['analysis'];
      _loading = false;
    });
  } catch (e) {
    setState(() => _loading = false);
  }
}

// In widget
SuggestionCard(
  content: _analysis,
  isLoading: _loading,
  onRetry: () => _generateAnalysis(forceRefresh: true),
)
```

### Pattern 2: Multiple Insights

```dart
// Single method handles all
Future<void> _generateAllInsights({bool forceRefresh = false}) async {
  setState(() => _loading = true);
  try {
    final analysis = await _aiService.getFinancialAnalysis(
      // ...,
      forceRefresh: forceRefresh,
    );
    final advice = await _aiService.getSpendingAdvice(
      // ...,
      forceRefresh: forceRefresh,
    );

    setState(() {
      _analysis = analysis['analysis'];
      _advice = advice;
      _loading = false;
    });
  } catch (e) {
    setState(() => _loading = false);
  }
}

// Each card has same callback
onRetry: () => _generateAllInsights(forceRefresh: true),
```

### Pattern 3: Selective Refresh

```dart
// Refresh only specific insight
Future<void> _refreshAnalysis() async {
  setState(() => _analysisLoading = true);
  try {
    final result = await _aiService.getFinancialAnalysis(
      // ...,
      forceRefresh: true,
    );
    setState(() {
      _analysis = result['analysis'];
      _analysisLoading = false;
    });
  } catch (e) {
    setState(() => _analysisLoading = false);
  }
}
```

---

## 🔍 Cache Key Reference

```dart
const cacheKey = 'ai_financial_analysis';    // Financial Analysis
const cacheKey = 'ai_spending_advice';       // Spending Advice
const cacheKey = 'ai_saving_tips';           // Saving Tips
const cacheKey = 'ai_financial_warnings';    // Financial Warnings
const cacheKey = 'ai_goal_insights';         // Goal Insights
```

---

## ⚙️ Configuration

### Cache TTL

```dart
// In DataCacheService
static const Duration _cacheDuration = Duration(hours: 1);
```

To change TTL, modify in `lib/core/services/data_cache_service.dart`

---

## 🧪 Testing

### Test Cache (No Refresh)

```dart
test('should use cached data on second call', () async {
  // First call - generates fresh
  await aiService.getFinancialAnalysis(...);

  // Second call - uses cache
  final result = await aiService.getFinancialAnalysis(...);

  // Should be instant (cached)
  expect(callDuration, lessThan(100.milliseconds));
});
```

### Test Force Refresh

```dart
test('should bypass cache with forceRefresh=true', () async {
  // First call
  final first = await aiService.getFinancialAnalysis(...);

  // Force refresh
  final second = await aiService.getFinancialAnalysis(
    ...,
    forceRefresh: true,
  );

  // May have different content
  expect(second, isNotNull);
});
```

---

## 🐛 Debugging

### Check if using cache

```dart
// Enable debug logging in AIService
print('[CACHE] Using cached financial analysis');  // ← Cache hit
print('[CACHE] Cached financial analysis');        // ← Cache stored
print('[AI ERROR] Error generating...');           // ← Cache miss/error
```

### Monitor cache state

```dart
// In DataCacheService
bool isValid = _cacheService!.isCacheValid(cacheKey);
print('Cache valid: $isValid');
```

### Force clear cache (for testing)

```dart
// Not exposed in current implementation
// Would need to add method to DataCacheService if needed
```

---

## 📈 Performance Tips

### DO ✅

- Use caching by default (no forceRefresh)
- Call forceRefresh only on user interaction
- Handle errors gracefully
- Show loading spinner during refresh
- Cache all AI results immediately

### DON'T ❌

- Don't call forceRefresh on every load
- Don't refresh on background syncs
- Don't expose cache keys to UI
- Don't ignore errors
- Don't refresh multiple times rapidly

---

## 🚨 Error Handling

### Proper Pattern

```dart
Future<void> _generateInsight({bool forceRefresh = false}) async {
  setState(() => _loading = true);

  try {
    final result = await _aiService.getInsight(
      // ...,
      forceRefresh: forceRefresh,
    );
    setState(() {
      _insight = result;
      _loading = false;
    });
  } catch (e) {
    print('Error: $e');
    setState(() {
      _insight = 'Unable to generate insight';
      _loading = false;
    });

    // Optional: Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}
```

---

## 🔄 State Management

### Using setState (Current Implementation)

```dart
class _MyScreenState extends State<MyScreen> {
  bool _loading = false;
  String _insight = '';

  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}
```

### Future: Provider or Riverpod

If migrating to Provider:

```dart
final insightProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(aiServiceProvider).getInsight(
    forceRefresh: ref.watch(forceRefreshProvider),
  );
});
```

---

## 📚 Resources

- **AIService**: `lib/services/ai_service.dart`
- **AI Screen**: `lib/features/ai/ai_screen.dart`
- **Widgets**: `lib/features/ai/widgets/`
- **Cache Service**: `lib/core/services/data_cache_service.dart`
- **Documentation**: `AI_REFRESH_FEATURE.md`
- **Visual Guide**: `AI_REFRESH_VISUAL_GUIDE.md`

---

## 📞 Support

### Common Issues

**Q: Why is my refresh button not showing?**

```dart
// Make sure you have:
// 1. Added onRetry parameter
// 2. Added isLoading parameter
// 3. Passed both to widget
// 4. Widget is checking both conditions
```

**Q: Cache not updating?**

```dart
// Check:
// 1. Is await used for getCachedData?
// 2. Is cacheData called after generation?
// 3. Is cache TTL expired? (1 hour)
```

**Q: Loading spinner stuck?**

```dart
// Ensure:
// 1. setState is called to hide spinner
// 2. Try-catch handles all errors
// 3. isLoading set to false in finally block
```

---

**Last Updated**: 2024  
**Status**: Production Ready ✅
