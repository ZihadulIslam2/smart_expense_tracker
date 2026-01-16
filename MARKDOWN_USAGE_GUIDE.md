# 🚀 How to Use the Markdown Renderer

## 📋 Overview

The `MarkdownTextWidget` automatically converts markdown-formatted text from your AI service into beautifully rendered Flutter widgets with proper formatting, colors, and spacing.

---

## 🛠️ Using the Widget

### Basic Usage:

```dart
MarkdownTextWidget(
  markdown: content,  // String with markdown formatting
)
```

### With Custom Colors:

```dart
MarkdownTextWidget(
  markdown: content,
  accentColor: Colors.blue[700],  // Color for headers, bold, bullets
)
```

### With Custom Text Style:

```dart
MarkdownTextWidget(
  markdown: content,
  baseStyle: TextStyle(
    fontSize: 14,
    color: Colors.grey[800],
    height: 1.6,
  ),
  accentColor: Colors.purple,
)
```

---

## ✍️ Markdown Syntax Supported

### 1. Headers

```markdown
# Main Title

## Subtitle

### Sub-subtitle

#### Small Header
```

**Result:**

- Automatically sized (18px → 8px)
- Bold, colored text
- Proper spacing

---

### 2. Bold Text

```markdown
This is **bold text** in a paragraph.
Save **$200 per month** to reach your goal.
```

**Result:**

- Text between `**` is bold and colored
- Works inline within paragraphs

---

### 3. Bullet Points

```markdown
- First point
- Second point
- Third point
```

**Result:**

- Colored bullet (•)
- Proper indentation
- Clean layout

**Note:** Bullet lines must start with 2 spaces before the dash!

---

### 4. Numbered Lists

```markdown
1. First item
2. Second item
3. Third item
```

**Result:**

- Numbered (1. 2. 3.)
- Bold, colored numbers
- Same indentation as bullets

---

### 5. Line Breaks

```markdown
First paragraph.

Second paragraph.
```

**Result:**

- Empty lines create vertical spacing
- Content is more readable

---

## 📝 Complete Example

```markdown
# Savings Goals & Tips

## 1. Monthly Savings Target

Save an additional **$200 per month** to reach your 20% savings goal.

## 2. Reduce Spending

- Cut Food expenses by $150/month
- Limit dining out to weekends
- Try meal prepping

## 3. Timeline

Achieve **20% savings rate** in **3 months**.

1. Start tracking daily
2. Cut 1 category per month
3. Celebrate your progress
```

---

## 🎨 Default Colors

If no `accentColor` is specified:

- Headers → Blue (Colors.blue.shade700)
- Bold text → Blue
- Bullets → Blue
- Numbers → Blue

The widget automatically uses the accent color for visual hierarchy.

---

## 🔄 Integration Points

### In Dashboard Cards:

```dart
AIFinancialInsightsCard(
  suggestions: aiResponse,  // String from API
)

// Inside the card:
MarkdownTextWidget(
  markdown: suggestions,
  accentColor: Colors.blue[700],
)
```

### In AI Screen:

```dart
SuggestionCard(
  title: 'Overall Analysis',
  content: _overallAnalysis,  // String from API
  color: Colors.purple,
)

// Inside SuggestionCard:
MarkdownTextWidget(
  markdown: content,
  accentColor: color,  // Uses card's color theme
)
```

---

## 💡 Tips for AI Service

When your AI service generates responses, format them with markdown:

```dart
// Good ✅
"""
# Savings Strategy

## Your Current Situation
- Income: \$5,000/month
- Expenses: \$4,200/month
- Savings: **16%** (target: **20%**)

## Action Items
1. Reduce Food by \$150/month
2. Cut Entertainment by \$100/month
3. Save extra \$200/month
"""

// Plain text ❌ (still works but not pretty)
"""
Your current situation: Income $5000, Expenses $4200.
Action items: Reduce food, cut entertainment, save more.
"""
```

---

## 🎯 Best Practices

### 1. Use Headers for Sections

```markdown
# Main Topic

## Subtopic

### Details
```

### 2. Emphasize Numbers

```markdown
Save **$200 per month** to reach **20%** savings rate.
```

### 3. Use Bullets for Lists

```markdown
- Point one
- Point two
- Point three
```

### 4. Use Numbers for Steps

```markdown
1. First step
2. Second step
3. Third step
```

### 5. Add Spacing Between Sections

```markdown
# Section 1

Details here.

# Section 2

More details here.
```

---

## ⚡ Performance

The widget is optimized for:

- ✅ Smooth scrolling (uses SingleChildScrollView)
- ✅ Efficient rendering (only renders visible content)
- ✅ No dependencies (pure Flutter)
- ✅ Fast parsing (regex-based)

---

## 🐛 Common Issues

### Headers not styled?

**Fix:** Make sure header line starts with `#`

```dart
✅ # Title (correct)
❌  # Title (extra space - becomes regular text)
```

### Bullets not rendering?

**Fix:** Bullet lines must have 2+ leading spaces

```dart
✅   - Point (has spaces)
❌ - Point (no spaces - becomes regular text)
```

### Bold not working?

**Fix:** Use exactly `**text**`

```dart
✅ **bold** (correct)
❌ * bold * (single asterisks - wrong)
❌ __bold__ (underscores - not supported)
```

---

## 🔍 Testing Markdown

To test your markdown:

1. Create a test string with markdown:

```dart
const testMarkdown = """
# Test Header

This is **bold** text.

  - Bullet one
  - Bullet two

1. Number one
2. Number two
""";
```

2. Use it in the widget:

```dart
MarkdownTextWidget(
  markdown: testMarkdown,
  accentColor: Colors.blue,
)
```

3. Check the output visually on screen

---

## 📚 Additional Resources

For more advanced markdown rendering, consider:

1. `markdown` package - Full markdown support
2. `markdown_widget` package - Advanced rendering
3. `flutter_markdown` package - Comprehensive solution

However, the current implementation provides:

- ✅ Headers, bold, bullets, numbers
- ✅ Color customization
- ✅ Proper spacing
- ✅ No external dependencies (besides Flutter)
- ✅ Lightweight and fast

---

## ✅ Checklist

Before using in production:

- [ ] Test with your AI responses
- [ ] Verify headers render correctly
- [ ] Check bold text highlights properly
- [ ] Ensure bullets display with proper indentation
- [ ] Test with different accent colors
- [ ] Verify on both light and dark modes (if applicable)
- [ ] Check scrolling performance with long content

---

**Status:** Ready to use! Your app now displays financial advice beautifully! 🎉
