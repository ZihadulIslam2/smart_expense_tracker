# Accounts Feature - Appwrite Setup Guide

## Collection Setup

You need to create a new collection in your Appwrite database for storing accounts.

### Collection Details

- **Database ID**: `143973bc-3217-4b7e-a1ca-05082dfde404` (use your existing database)
- **Collection Name**: `accounts`
- **Collection ID**: `accounts` (or generate a new ID)

### Attributes to Create

Create the following attributes in the `accounts` collection:

1. **userId** (String)

   - Type: String
   - Size: 255
   - Required: Yes
   - Array: No

2. **name** (String)

   - Type: String
   - Size: 255
   - Required: Yes
   - Array: No
   - Example: "My Savings", "Daily Cash", "Business Account"

3. **type** (String)

   - Type: String
   - Size: 50
   - Required: Yes
   - Array: No
   - Values: "cash", "bank", "mobile_wallet"

4. **initialBalance** (Float)

   - Type: Float
   - Required: Yes
   - Min: 0
   - Max: Leave empty

5. **currency** (String)

   - Type: String
   - Size: 10
   - Required: Yes
   - Array: No
   - Default: "BDT"

6. **isActive** (Boolean)
   - Type: Boolean
   - Required: Yes
   - Default: true

### Indexes to Create

Create the following indexes for better query performance:

1. **idx_userId**

   - Type: Key
   - Attributes: userId
   - Order: ASC

2. **idx_userId_isActive**
   - Type: Key
   - Attributes: userId, isActive
   - Order: ASC, ASC

### Permissions

Set the following permissions:

- **Create**: Users (role:users)
- **Read**: Users (role:users)
- **Update**: Users (role:users)
- **Delete**: Users (role:users)

Or for stricter security, use document-level security:

- Allow users to only access documents where `userId` matches their user ID

## After Creating the Collection

Update the collection ID in the code if you used a different ID:

```dart
_accountService = AccountService(
  databases: databases,
  databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
  collectionId: 'YOUR_COLLECTION_ID_HERE', // Update this
);
```

## Updating Transactions Collection

Add the following attribute to your existing `expenses`/`transactions` collection:

### New Attribute

**accountId** (String)

- Type: String
- Size: 255
- Required: No (optional)
- Array: No
- Description: Links transaction to specific account

This allows transactions to be associated with specific accounts for better tracking.

## Features

✅ **Multiple Account Types**: Cash, Bank Account, Mobile Wallet
✅ **Real-time Balance Tracking**: Current balance updates with transactions
✅ **Net Balance Calculation**: Shows total across all accounts
✅ **Account Management**: Create, update, delete accounts
✅ **Visual Indicators**: Icons and colors for account types
✅ **Account History**: Tracks initial balance and current balance

## Testing

After setup, you can test by:

1. Opening the app
2. Navigating to the Accounts tab
3. Clicking the + button to create an account
4. Select account type and enter initial balance
5. Verify account appears with correct balance
6. Add transactions and watch balance update
