# Smart Expense Tracker - Setup & Debugging Guide

## Issues and Solutions

### Issue 1: Collection Not Found (404)

**Error:** `Collection with the requested ID 'budgets' could not be found. (404)`

**Cause:** The Appwrite collections `budgets` and `accounts` don't exist in your database.

**Solution:** Create these collections using one of the methods below.

---

## Setup Methods

### Method 1: Using Appwrite Console (Recommended for Beginners)

1. Go to [Appwrite Console](https://fra.cloud.appwrite.io/console)
2. Log in with your credentials
3. Select your project
4. Go to **Databases** → **smart_expense_tracker** (or your database name)
5. Click **Create Collection**

#### Create "budgets" Collection:

- **Collection ID:** `budgets`
- **Collection Name:** `Budgets`

**Add these attributes:**
| Key | Type | Size | Required | Min | Max |
|-----|------|------|----------|-----|-----|
| userId | String | 255 | Yes | - | - |
| category | String | 100 | Yes | - | - |
| amount | Float | - | Yes | 0 | - |
| month | Integer | - | Yes | 1 | 12 |
| year | Integer | - | Yes | 2020 | 2100 |
| createdAt | DateTime | - | No | - | - |
| updatedAt | DateTime | - | No | - | - |

**Add indexes:**

- userId
- category
- month, year (composite)

---

#### Create "accounts" Collection:

- **Collection ID:** `accounts`
- **Collection Name:** `Accounts`

**Add these attributes:**
| Key | Type | Size | Required |
|-----|------|------|----------|
| userId | String | 255 | Yes |
| name | String | 100 | Yes |
| type | String | 50 | Yes |
| initialBalance | Float | - | Yes |
| currency | String | 10 | No |
| isActive | Boolean | - | No |
| createdAt | DateTime | - | No |
| updatedAt | DateTime | - | No |

**Add indexes:**

- userId
- isActive

---

### Method 2: Using Python Script

1. Install Appwrite SDK:

```bash
pip3 install appwrite
```

2. Get your credentials:

   - Go to [Appwrite Console](https://fra.cloud.appwrite.io/console)
   - Settings → Project ID (copy this)
   - Settings → API Keys → Create API Key (copy this)

3. Edit the script:

```bash
nano setup_appwrite_collections.py
```

4. Replace these lines:

```python
APPWRITE_PROJECT_ID = 'YOUR_PROJECT_ID'  # Paste your Project ID
APPWRITE_API_KEY = 'YOUR_API_KEY'        # Paste your API Key
```

5. Run the script:

```bash
python3 setup_appwrite_collections.py
```

---

### Method 3: Using Node.js Script

1. Install Node.js (if not already installed)

2. Get your credentials:

   - Go to [Appwrite Console](https://fra.cloud.appwrite.io/console)
   - Settings → Project ID (copy this)
   - Settings → API Keys → Create API Key (copy this)

3. Edit the script:

```bash
nano setup_appwrite_collections.js
```

4. Replace these lines:

```javascript
const APPWRITE_PROJECT_ID = 'YOUR_PROJECT_ID' // Paste your Project ID
const APPWRITE_API_KEY = 'YOUR_API_KEY' // Paste your API Key
```

5. Run the script:

```bash
node setup_appwrite_collections.js
```

---

## Issue 2: Gemini Model Not Found

**Error:** `models/gemini-1.5-flash is not found for API version v1beta`

**Cause:** The model name was incorrect for the Google Generative AI API v1beta.

**Solution:** ✅ Already fixed! The model has been updated to `gemini-1.5-flash-latest`.

---

## Issue 3: Health Check Scope Warning

**Error:** `User (role: guests) missing scopes (["health.read"])`

**Cause:** Appwrite is checking server health but the user doesn't have permission.

**Solution:** This is a minor warning and won't affect functionality. Ignore it.

---

## Verification Steps

After setup, verify everything works:

1. **Check Collections in Appwrite Console:**

   - Go to Databases → Your Database
   - You should see `budgets` and `accounts` collections

2. **Restart Flutter App:**

```bash
flutter run -v
```

3. **Check Logs:**

   - You should see AI analysis generating without errors
   - Example: `[AI] Analysis generated successfully`

4. **Test in App:**
   - Add some transactions (Income/Expense)
   - Go to the AI tab
   - You should see financial analysis with Gemini insights

---

## Troubleshooting

### Still getting "collection_not_found"?

1. Verify collection was created in Appwrite Console
2. Check the collection ID matches exactly: `budgets` (lowercase)
3. Try refreshing the app (hot restart): `r` in Flutter console

### AI analysis still not working?

1. Check .env file has `GEMINI_API_KEY` set correctly
2. Run `flutter pub get` to update dependencies
3. Check internet connection
4. Try running with verbose logging: `flutter run -v`

### How to find your Appwrite credentials?

**Project ID:**

1. Go to [https://fra.cloud.appwrite.io/console](https://fra.cloud.appwrite.io/console)
2. Click **Settings** (gear icon)
3. Look for **Project ID** at the top
4. Click copy icon

**API Key:**

1. From Settings, scroll down to **API Keys**
2. Click **Create API Key**
3. Name it (e.g., "Setup Script")
4. Select all scopes or at least: `databases.read`, `databases.write`, `collections.read`, `collections.write`
5. Click **Create**
6. Copy the key immediately (it won't be shown again)

---

## Quick Start After Setup

1. Run setup script (Python or Node.js)
2. Verify collections in Appwrite Console
3. Restart Flutter app
4. Add transactions in app
5. Check AI tab for Gemini-powered insights

---

## Need Help?

- **Appwrite Docs:** https://appwrite.io/docs
- **Google Generative AI:** https://ai.google.dev
- **Flutter Docs:** https://flutter.dev/docs
