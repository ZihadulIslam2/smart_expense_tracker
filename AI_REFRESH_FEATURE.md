# AI Refresh Feature Implementation

## Overview

This document describes the implementation of the AI refresh feature for the Smart Expense Tracker application. The feature allows users to manually refresh AI-generated insights (analysis, spending advice, saving tips, financial alerts, and goal insights) by clicking a refresh button on each card.

## Changes Made

### 1. AIService (`lib/services/ai_service.dart`)

**Major Changes:**

- **Added `forceRefresh` parameter** to all AI generation methods:

  - `getFinancialAnalysis()`
  - `getSpendingAdvice()`
  - `getSavingTips()`
  - `getFinancialWarnings()`
  - `getGoalInsights()`

- **Implemented smart caching** using `DataCacheService`:

  - Caches AI responses for 1 hour (matches existing cache TTL)
  - On first load (`forceRefresh: false`), uses cached data if available
  - When user clicks refresh button (`forceRefresh: true`), bypasses cache and fetches fresh insights
  - Each insight type has its own cache key:
    - `ai_financial_analysis`
    - `ai_spending_advice`
    - `ai_saving_tips`
    - `ai_financial_warnings`
    - `ai_goal_insights`

- **Fixed type safety issues**:
  - Fixed `fold()` operation to use explicit `<double>` type parameter
  - Added `await` keywords for async `getCachedData()` calls
  - Ensured all cache retrieval calls are properly awaited

### 2. AI Screen (`lib/features/ai/ai_screen.dart`)

**Changes:**

- **Updated `_generateAIAnalysis()` method**:

  - Added `forceRefresh` parameter (default: `false`)
  - Passes `forceRefresh` to all AIService method calls
  - Only generates analysis on initial load unless forced

- **Modified `_fetchData()` method**:

  - Only triggers AI analysis generation if `forceRefresh` is true or if analysis is empty
  - Prevents unnecessary API calls on simple data refreshes

- **Updated UI widgets** with `onRetry` callbacks:
  - `WarningsCard`: Added refresh button that calls `_generateAIAnalysis(forceRefresh: true)`
  - `SuggestionCard`: Added refresh button (for Overall Analysis and Spending Advice cards)
  - `TipsCard`: Added refresh button (for Saving Tips card)

### 3. Widget Components

#### Suggestion Card (`lib/features/ai/widgets/suggestion_card.dart`)

- Added `onRetry` callback parameter (nullable)
- Added refresh button that appears when `onRetry` is provided and not loading
- Shows loading spinner during AI generation

#### Warnings Card (`lib/features/ai/widgets/warnings_card.dart`)

- Added `onRetry` callback parameter (nullable)
- Added refresh button in the header
- Only shows refresh button when not loading and callback is provided

#### Tips Card (`lib/features/ai/widgets/tips_card.dart`)

- Added `onRetry` callback parameter (nullable)
- Added refresh button matching the design of other cards
- Maintains consistent UI/UX across all AI insight cards

### 4. Goals Screen (`lib/features/goals/goals_screen.dart`)

**Changes:**

- **Updated `_fetchData()` method**:

  - Added conditional logic to only generate AI insights on first load or if forced
  - Prevents unnecessary AI calls on regular data refreshes

- **Modified `_generateAIInsights()` method**:

  - Added `forceRefresh` parameter (default: `false`)
  - Passes `forceRefresh` to AIService's `getGoalInsights()`

- **Enhanced AI Insights Card UI**:
  - Added refresh button in the card header
  - Shows loading spinner during AI generation
  - Refresh button is conditionally hidden during loading

## User Experience

### Before

- AI insights were generated only on first screen load
- Users had no way to refresh insights if they wanted fresh analysis
- Had to navigate away and back to get new insights

### After

- AI insights are still generated on first load (efficient, uses cache)
- Each AI card now has a visible refresh button (↻ icon)
- Clicking refresh button:
  - Shows loading spinner
  - Fetches fresh insights from Gemini AI (bypasses cache)
  - Updates the card with new content
  - Hides loading spinner when done
- Pull-to-refresh on the screen still updates data without generating new AI insights (unless forced)

## Performance Considerations

### Caching Strategy

1. **Default Behavior**: Uses cached insights if available (1-hour TTL)
2. **Manual Refresh**: Bypasses cache when user clicks refresh button
3. **Smart Loading**: Only generates AI once per session unless user explicitly refreshes

### Cache Keys

All AI caches follow a consistent naming pattern: `ai_<insight_type>`

### Cost Optimization

- Reduces unnecessary API calls to Gemini AI
- Uses existing DataCacheService infrastructure
- Honors user intent:
  - Regular pulls/loads use cache
  - Manual refreshes fetch fresh data

## Testing Recommendations

1. **Cache Functionality**:

   - First load should generate and cache insights
   - Second load without refresh should use cache
   - Clearing app data should regenerate on next load

2. **Refresh Button**:

   - Clicking refresh should show loading spinner
   - New insights should appear after generation
   - Multiple rapid refreshes should work smoothly

3. **Error Handling**:

   - Network errors during refresh should display error message
   - Cache should fallback if refresh fails

4. **UI/UX**:
   - Refresh button should only appear on AI insight cards
   - Loading spinner should be visible during generation
   - All buttons should be responsive

## File Structure

```
lib/
├── services/
│   └── ai_service.dart (updated with caching & forceRefresh)
└── features/
    ├── ai/
    │   ├── ai_screen.dart (updated with refresh logic)
    │   └── widgets/
    │       ├── suggestion_card.dart (added onRetry callback)
    │       ├── warnings_card.dart (added onRetry callback)
    │       └── tips_card.dart (added onRetry callback)
    └── goals/
        └── goals_screen.dart (added refresh button)
```

## Future Enhancements

1. **Analytics**: Track how often users click refresh buttons
2. **Adaptive Caching**: Adjust TTL based on user preferences
3. **Background Refresh**: Automatically refresh insights when cache is about to expire
4. **Offline Support**: Queue refresh requests when offline, execute when back online
5. **User Feedback**: Show toast/snackbar when insights are updated

## API Reference

### AIService Methods

All methods now accept an optional `forceRefresh` parameter:

```dart
// Example: Get financial analysis with cache bypass
final analysis = await _aiService.getFinancialAnalysis(
  totalIncome: 50000,
  totalExpense: 30000,
  categorySpending: {...},
  monthlyTrend: [...],
  budgetStatus: {...},
  totalTransactions: 150,
  forceRefresh: true, // Force fresh insights
);
```

### Widget Callbacks

Widgets can now accept `onRetry` callbacks:

```dart
SuggestionCard(
  title: 'Overall Analysis',
  content: _overallAnalysis,
  onRetry: () async {
    await _generateAIAnalysis(forceRefresh: true);
  },
)
```

## Conclusion

The AI refresh feature provides users with the ability to get fresh financial insights on demand while maintaining efficient caching to minimize API costs and improve app responsiveness. The implementation is backward-compatible and doesn't break any existing functionality.
