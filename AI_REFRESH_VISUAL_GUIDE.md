# AI Refresh Feature - Visual Guide & Usage

## 🎨 User Interface

### Before (Without Refresh Buttons)

```
┌─────────────────────────────────────────┐
│ Overall Analysis                        │
├─────────────────────────────────────────┤
│                                         │
│  Your financial health is stable...    │
│  Key strengths:                        │
│  - Good savings rate                   │
│  - Diversified spending                │
│                                         │
└─────────────────────────────────────────┘
```

### After (With Refresh Button)

```
┌─────────────────────────────────────────┐
│ 🔍 Overall Analysis             [↻]    │
├─────────────────────────────────────────┤
│                                         │
│  Your financial health is stable...    │
│  Key strengths:                        │
│  - Good savings rate                   │
│  - Diversified spending                │
│                                         │
└─────────────────────────────────────────┘
          ↑                        ↑
      Icon              Refresh Button
```

---

## 🔄 Refresh Flow Diagram

```
User Opens AI Screen
        ↓
   Check Cache
   /        \
Cache   No Cache
Valid    (or expired)
  ↓           ↓
Show      Generate from
Cached    Gemini API
Data       ↓
  ↓      Cache Result
  └──→ Display to User
        ↓
    User sees Refresh Button
        ↓
    User Clicks Refresh Button
        ↓
    Show Loading Spinner
        ↓
    Fetch Fresh Data (force bypass cache)
        ↓
    Update Card + Re-cache
        ↓
    Hide Spinner
        ↓
    Display New Insights
```

---

## 📱 Screens Affected

### 1. AI Screen (lib/features/ai/ai_screen.dart)

**Refreshable Insights:**

- Overall Analysis (SuggestionCard)
- Spending Advice (SuggestionCard)
- Financial Alerts (WarningsCard)
- Saving Tips (TipsCard)

**Each card has:**

```
[Card Title]                    [↻ Refresh Button]
─────────────────────────────────────────────────
Card content here...
```

### 2. Goals Screen (lib/features/goals/goals_screen.dart)

**Refreshable Insights:**

- AI Goal Insights (Custom Card)

**Card structure:**

```
[💡 AI Goal Insights]           [↻ Refresh Button]
─────────────────────────────────────────────────
Insights about your goals...
```

---

## 🔧 Implementation Details

### A. AIService - Cache Management

```dart
// Method signature with forceRefresh
Future<Map<String, dynamic>> getFinancialAnalysis({
  ...
  bool forceRefresh = false,
}) async {
  const cacheKey = 'ai_financial_analysis';

  // Step 1: Check cache (unless forced refresh)
  if (!forceRefresh && _cacheService != null) {
    if (_cacheService!.isCacheValid(cacheKey)) {
      final cached = await _cacheService!.getCachedData(...);
      if (cached != null) {
        print('[CACHE] Using cached financial analysis');
        return cached;
      }
    }
  }

  // Step 2: Generate fresh data
  final response = await _model.generateContent([...]);
  final result = _parseFinancialAnalysis(response.text ?? '');

  // Step 3: Cache for future use
  if (_cacheService != null) {
    await _cacheService!.cacheData(cacheKey, result);
    print('[CACHE] Cached financial analysis');
  }

  return result;
}
```

### B. Screen - Handling Refresh

```dart
class _AIScreenState extends State<AIScreen> {
  // Generate insights with optional force refresh
  Future<void> _generateAIAnalysis({bool forceRefresh = false}) async {
    setState(() => _analyzingLoading = true);

    try {
      // Generate all insights
      final analysis = await _aiService.getFinancialAnalysis(
        ...
        forceRefresh: forceRefresh,
      );

      setState(() {
        _overallAnalysis = analysis['analysis'] ?? '';
        _analyzingLoading = false;
      });
    } catch (e) {
      print('[AI ERROR] Error: $e');
      setState(() => _analyzingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuggestionCard(
      title: 'Overall Analysis',
      content: _overallAnalysis,
      isLoading: _analyzingLoading,
      // Pass callback for refresh button
      onRetry: () async {
        await _generateAIAnalysis(forceRefresh: true);
      },
    );
  }
}
```

### C. Widget - Displaying Refresh Button

```dart
class SuggestionCard extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Refresh button (only show if callback provided & not loading)
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
            // Show spinner or content
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SelectableText(content),
          ],
        ),
      ),
    );
  }
}
```

---

## ⏱️ Timeline Example

```
10:00 AM - User opens AI Screen
         └─ No cache → Generates insights from Gemini
         └─ Caches results
         └─ Shows content with Refresh buttons

10:05 AM - User navigates away

10:10 AM - User returns to AI Screen
         └─ Cache valid → Uses cached insights
         └─ No Gemini API call
         └─ Instant display

10:15 AM - User clicks Refresh button
         └─ Shows loading spinner
         └─ Fetches fresh data from Gemini (cache bypassed)
         └─ Re-caches new data
         └─ Shows updated insights

11:15 AM - Cache expires (1 hour TTL)
         └─ If user returns, will generate fresh data
```

---

## 🎯 Cache Keys Reference

```
┌──────────────────────────────────────────────────┐
│           AI Insight Cache Keys                  │
├──────────────────────────────────────────────────┤
│ Insight              │ Cache Key                │
├──────────────────────┼───────────────────────────┤
│ Financial Analysis   │ ai_financial_analysis   │
│ Spending Advice      │ ai_spending_advice      │
│ Saving Tips          │ ai_saving_tips          │
│ Financial Warnings   │ ai_financial_warnings   │
│ Goal Insights        │ ai_goal_insights        │
└──────────────────────┴───────────────────────────┘

TTL (Time To Live): 1 hour
Storage: SharedPreferences
Location: Local device storage
```

---

## 🔌 API Cost Impact

### Before Feature

```
User Session (1 hour):
- Open AI Screen → 5 API calls
- Navigate away & return 3 times → 15 API calls
- Total: 20 API calls per user per session
- Cost: High ❌
```

### After Feature

```
User Session (1 hour):
- Open AI Screen → 5 API calls
- Navigate away & return 3 times → 0 API calls (cache)
- Manual refresh 1 time → 5 API calls
- Total: 10 API calls per user per session
- Cost: 50% reduction ✅

With 10,000 active users:
- Before: 200,000 API calls/hour
- After: 100,000 API calls/hour
- Savings: 100,000 calls/hour = ~$0.75/hour = $18/day
```

---

## 🐛 Error Handling

### Scenario: Network Error During Refresh

```
User Clicks Refresh
      ↓
Loading spinner shows
      ↓
Network error occurs
      ↓
Show error message:
"Unable to generate analysis. Please try again later."
      ↓
Keep old cached data visible
      ↓
Spinner disappears
```

---

## 📊 Loading States

### State 1: Initial Load (No Cache)

```
┌──────────────────────┐
│ Overall Analysis     │
├──────────────────────┤
│   ⏳ Loading...      │
└──────────────────────┘
```

### State 2: Cached Content Ready

```
┌──────────────────────┐
│ Overall Analysis [↻] │
├──────────────────────┤
│ Your financial...    │
│ Key strengths:       │
│ - Good savings rate  │
└──────────────────────┘
```

### State 3: Refreshing

```
┌──────────────────────┐
│ Overall Analysis     │
├──────────────────────┤
│   ⏳ Loading...      │
│                      │
│   (Spinner visible)  │
└──────────────────────┘
```

### State 4: Refresh Complete

```
┌──────────────────────┐
│ Overall Analysis [↻] │
├──────────────────────┤
│ Your financial...    │
│ (Updated content)    │
└──────────────────────┘
```

---

## ✨ User Stories

### Story 1: Quick Check

**User wants to quickly check their financial analysis**

1. Opens AI Screen
2. Sees cached analysis from last session
3. ✅ No wait, instant view

### Story 2: Fresh Insights

**User wants fresh analysis after major spending**

1. Opens AI Screen
2. Sees cached analysis
3. Clicks refresh button
4. Waits for new analysis
5. ✅ Gets updated insights

### Story 3: Regular Check-in

**User checks in periodically**

1. First visit: Gets fresh insights (1st API call)
2. 5 mins later: Returns, sees cached (no API call)
3. 1 hour later: Cache expired, gets fresh (1 API call)
4. ✅ Efficient usage pattern

---

## 🎓 Developer Notes

### When to Use forceRefresh

```dart
// Cache-first (default)
await _aiService.getFinancialAnalysis(...);

// Force fresh data
await _aiService.getFinancialAnalysis(..., forceRefresh: true);
```

### When NOT to Use forceRefresh

- Screen initialization (let cache work)
- Pull-to-refresh for data (not AI insights)
- Background syncs (use cache)

### When to USE forceRefresh

- User explicitly clicks refresh button
- Manual request for new insights
- Testing/debugging

---

## 🚀 Next Steps for Users

1. **Open App** → AI Screen loads with cached insights
2. **Review Content** → Read analysis, advice, tips, warnings
3. **Want Fresh Data?** → Click refresh button on any card
4. **Wait** → Spinner shows loading
5. **Enjoy** → Updated insights appear

---

**Conclusion**: The refresh feature provides a balance between performance (caching) and user control (manual refresh). It's designed to be intuitive, efficient, and responsive to user needs.
