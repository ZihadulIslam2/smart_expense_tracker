# Budget Feature - Appwrite Setup Guide

## Collection Setup

You need to create a new collection in your Appwrite database for storing budgets.

### Collection Details

- **Database ID**: `143973bc-3217-4b7e-a1ca-05082dfde404` (use your existing database)
- **Collection Name**: `budgets`
- **Collection ID**: `budgets` (or generate a new ID)

### Attributes to Create

Create the following attributes in the `budgets` collection:

1. **userId** (String)

   - Type: String
   - Size: 255
   - Required: Yes
   - Array: No

2. **category** (String)

   - Type: String
   - Size: 100
   - Required: Yes
   - Array: No

3. **amount** (Float)

   - Type: Float
   - Required: Yes
   - Min: 0
   - Max: Leave empty

4. **month** (Integer)

   - Type: Integer
   - Required: Yes
   - Min: 1
   - Max: 12

5. **year** (Integer)
   - Type: Integer
   - Required: Yes
   - Min: 2020
   - Max: 2100

### Indexes to Create

Create the following indexes for better query performance:

1. **idx_userId**

   - Type: Key
   - Attributes: userId
   - Order: ASC

2. **idx_month_year**

   - Type: Key
   - Attributes: month, year
   - Order: ASC, ASC

3. **idx_user_category_month**
   - Type: Key
   - Attributes: userId, category, month, year
   - Order: ASC, ASC, ASC, ASC

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
_budgetService = BudgetService(
  databases: databases,
  databaseId: '143973bc-3217-4b7e-a1ca-05082dfde404',
  collectionId: 'YOUR_COLLECTION_ID_HERE', // Update this
);
```

## Testing

After setup, you can test by:

1. Opening the app
2. Navigating to the Budgets tab
3. Clicking the + button to add a budget
4. Selecting a category and entering an amount
5. Verifying the budget appears in the list
