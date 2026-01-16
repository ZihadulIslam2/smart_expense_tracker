# AI Feature Debugging & Setup Guide

## Quick Summary of Fixes

✅ **Fixed Issues:**

1. **Gemini Model Error** - Updated from `gemini-1.5-flash` to `gemini-1.5-flash-latest`
2. **Collection Not Found** - Made error handling graceful, script to create collections
3. **Package Missing** - Added `google_generative_ai` to pubspec.yaml

---

## Getting Your Appwrite Credentials

### Step 1: Find Your Project ID

1. Go to https://fra.cloud.appwrite.io/console
2. Click the **Settings** icon (gear) in top right
3. Look for **Project ID** - this is what you need
4. Click the copy icon next to it

### Step 2: Create an API Key

1. From Settings, scroll down to **API Keys** section
2. Click **Create API Key**
3. Give it a name like "Setup Script"
4. Select at least these scopes:
   - `databases.read`
   - `databases.write`
   - `collections.read`
   - `collections.write`
5. Click **Create**
6. **Copy the key immediately** - it won't be shown again!

---

## Creating Appwrite Collections

### Option 1: Automatic Setup (Recommended)

#### Using Python:

```bash
# Install Appwrite SDK
pip3 install appwrite

# Edit the setup script
nano setup_appwrite_collections.py

# Find these lines and replace with your credentials:
# APPWRITE_PROJECT_ID = 'YOUR_PROJECT_ID'
# APPWRITE_API_KEY = 'YOUR_API_KEY'

# Run the script
python3 setup_appwrite_collections.py
```

#### Using Node.js:

```bash
# Edit the setup script
nano setup_appwrite_collections.js

# Find these lines and replace with your credentials:
# const APPWRITE_PROJECT_ID = 'YOUR_PROJECT_ID';
# const APPWRITE_API_KEY = 'YOUR_API_KEY';

# Run the script
node setup_appwrite_collections.js
```

### Option 2: Manual Setup in Appwrite Console

#### Create "budgets" Collection:

1. Go to Appwrite Console → Your Database
2. Click **Create Collection**
3. Set ID to: `budgets`
4. Set Name to: `Budgets`
5. Click **Create**

**Add these attributes:**

```
userId      | String    | Size: 255  | Required: Yes
category    | String    | Size: 100  | Required: Yes
amount      | Float     | Required: Yes | Min: 0
month       | Integer   | Required: Yes | Min: 1, Max: 12
year        | Integer   | Required: Yes | Min: 2020, Max: 2100
createdAt   | DateTime  | Required: No
updatedAt   | DateTime  | Required: No
```

**Add indexes:**

- `userId` (key index)
- `category` (key index)
- `month, year` (composite index)

#### Create "accounts" Collection:

1. Click **Create Collection** again
2. Set ID to: `accounts`
3. Set Name to: `Accounts`
4. Click **Create**

**Add these attributes:**

```
userId         | String    | Size: 255  | Required: Yes
name           | String    | Size: 100  | Required: Yes
type           | String    | Size: 50   | Required: Yes
initialBalance | Float     | Required: Yes
currency       | String    | Size: 10   | Required: No
isActive       | Boolean   | Required: No
createdAt      | DateTime  | Required: No
updatedAt      | DateTime  | Required: No
```

**Add indexes:**

- `userId` (key index)
- `isActive` (key index)

---

## Verifying Your Setup

### Check Collections Exist:

```bash
bash verify_appwrite_setup.sh
```

### Run App with Verbose Logging:

```bash
flutter run -v 2>&1 | grep -E "\[AI\]|\[Appwrite\]|Error|error"
```

### Look for These Log Messages (Success):

```
✓ [Appwrite] Collections initialized
✓ [AI] Analysis generated successfully
✓ Warnings card rendered
```

### Look for These Log Messages (Issues):

```
❌ collection_not_found → Create collections using setup script
❌ models/gemini-1.5-flash → Should be fixed now (check ai_service.dart)
❌ GEMINI_API_KEY not found → Check .env file
```

---

## Testing the AI Feature

### Step 1: Add Sample Data

1. Open the app
2. Go to **Records** tab
3. Add 5-10 transactions:
   - At least one Income transaction
   - Several Expense transactions with different categories
4. Wait for data to sync to Appwrite

### Step 2: Check AI Tab

1. Go to **AI** tab
2. You should see:
   - Financial Summary card (Income/Expense/Savings)
   - Loading spinner while AI is analyzing
   - After ~5 seconds:
     - Overall Analysis
     - Spending Advice
     - Saving Tips
     - Any Financial Warnings

### Step 3: Verify Results

- AI analysis should be specific to your transactions
- Should mention categories you've used
- Should give actionable advice

---

## Common Issues & Solutions

### Issue: Still getting "collection_not_found"

```
Solution:
1. Run the setup script again: python3 setup_appwrite_collections.py
2. Verify in Appwrite Console that collections exist
3. Restart Flutter: flutter run
4. Check app logs for errors
```

### Issue: AI analysis says "Unable to generate analysis"

```
Solution:
1. Check GEMINI_API_KEY in .env file is correct
2. Check you have internet connection
3. Try again (Gemini API might be temporarily unavailable)
4. Check flutter logs: flutter run -v
```

### Issue: App crashes when opening AI tab

```
Solution:
1. Run: flutter clean
2. Run: flutter pub get
3. Run: flutter run -v
4. Check error in console output
```

### Issue: "Health check error" warning

```
This is normal and won't affect functionality.
It's just Appwrite checking server status without permission.
You can safely ignore it.
```

---

## Directory Structure

```
smart_expense_tracker/
├── setup_appwrite_collections.py    ← Use this to setup collections
├── setup_appwrite_collections.js    ← Or this (Node.js version)
├── verify_appwrite_setup.sh         ← Check if setup worked
├── SETUP_GUIDE.md                   ← Detailed setup instructions
├── lib/
│   ├── services/
│   │   └── ai_service.dart          ← Gemini AI integration
│   └── features/
│       └── ai/
│           ├── ai_screen.dart       ← Main AI page
│           └── widgets/
│               ├── suggestion_card.dart
│               ├── warnings_card.dart
│               └── tips_card.dart
└── pubspec.yaml                     ← Contains google_generative_ai
```

---

## Environment Variables

Make sure your `.env` file has:

```
GEMINI_API_KEY=AIzaSyBsDrO175TjvQgNH7fN6GWrsDfHFrdSpU0
```

If this key expires, get a new one from: https://aistudio.google.com/

---

## Next Steps

1. **Setup Collections:**

   ```bash
   python3 setup_appwrite_collections.py
   ```

2. **Restart App:**

   ```bash
   flutter run
   ```

3. **Add Transactions:**

   - Go to Records tab
   - Add income and expense transactions

4. **Check AI Tab:**
   - Should show financial analysis
   - Should work without errors

---

## Getting Help

**If you're stuck:**

1. Check the logs:

   ```bash
   flutter run -v 2>&1 | head -100
   ```

2. Verify collections exist:

   ```bash
   bash verify_appwrite_setup.sh
   ```

3. Check Appwrite Console:

   - https://fra.cloud.appwrite.io/console
   - Verify collections are there
   - Check permissions

4. Check .env file:
   - Make sure GEMINI_API_KEY is set
   - Make sure it's not expired

---

## References

- **Appwrite Docs:** https://appwrite.io/docs
- **Google Generative AI:** https://ai.google.dev
- **Flutter Docs:** https://flutter.dev/docs
