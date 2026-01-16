#!/bin/bash

# Quick Appwrite Collections Verification Script
# Checks if budgets and accounts collections exist in your Appwrite database

echo "🔍 Appwrite Collections Verification"
echo "===================================="
echo ""
echo "This script will check if your Appwrite collections are properly set up."
echo ""
echo "Prerequisites:"
echo "1. You need Appwrite SDK installed: pip3 install appwrite"
echo "2. Update the credentials in this script"
echo ""

# Create a Python script inline
python3 << 'PYTHON_SCRIPT'
import sys
try:
    from appwrite.client import Client
    from appwrite.services.databases import Databases
    
    # Update these with your credentials
    APPWRITE_ENDPOINT = 'https://fra.cloud.appwrite.io/v1'
    APPWRITE_PROJECT_ID = 'YOUR_PROJECT_ID'  # Replace
    APPWRITE_API_KEY = 'YOUR_API_KEY'        # Replace
    DATABASE_ID = '143973bc-3217-4b7e-a1ca-05082dfde404'
    
    if APPWRITE_PROJECT_ID == 'YOUR_PROJECT_ID':
        print('❌ Error: Update APPWRITE_PROJECT_ID in the script')
        sys.exit(1)
    
    if APPWRITE_API_KEY == 'YOUR_API_KEY':
        print('❌ Error: Update APPWRITE_API_KEY in the script')
        sys.exit(1)
    
    print('Connecting to Appwrite...')
    client = Client()
    client.set_endpoint(APPWRITE_ENDPOINT)
    client.set_project(APPWRITE_PROJECT_ID)
    client.set_key(APPWRITE_API_KEY)
    
    databases = Databases(client)
    
    print('Checking collections...\n')
    
    # Check for budgets collection
    try:
        budgets_collection = databases.get_collection(
            database_id=DATABASE_ID,
            collection_id='budgets'
        )
        print('✅ Budgets collection found')
        print(f'   Name: {budgets_collection["name"]}')
        print(f'   Attributes: {len(budgets_collection.get("attributes", []))}')
    except Exception as e:
        print(f'❌ Budgets collection not found: {str(e)}')
    
    # Check for accounts collection
    try:
        accounts_collection = databases.get_collection(
            database_id=DATABASE_ID,
            collection_id='accounts'
        )
        print('\n✅ Accounts collection found')
        print(f'   Name: {accounts_collection["name"]}')
        print(f'   Attributes: {len(accounts_collection.get("attributes", []))}')
    except Exception as e:
        print(f'\n❌ Accounts collection not found: {str(e)}')
    
    print('\n' + '='*50)
    print('Next steps:')
    print('1. If collections are missing, run: python3 setup_appwrite_collections.py')
    print('2. Restart your Flutter app: flutter run')
    print('3. Add some transactions to test AI analysis')
    
except ImportError:
    print('❌ Error: Appwrite SDK not installed')
    print('Install it with: pip3 install appwrite')
except Exception as e:
    print(f'❌ Error: {str(e)}')

PYTHON_SCRIPT
