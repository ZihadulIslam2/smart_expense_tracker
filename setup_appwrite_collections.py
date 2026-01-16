#!/usr/bin/env python3
"""
Appwrite Collections Setup Script

This script creates the required collections and attributes in Appwrite
for the Smart Expense Tracker application.

Prerequisites:
- Python 3.7+
- Appwrite SDK: pip install appwrite

Usage:
1. Set your Appwrite credentials below
2. Run: python3 setup_appwrite_collections.py
"""

import json
import sys
from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.query import Query

# Configuration
APPWRITE_ENDPOINT = 'https://fra.cloud.appwrite.io/v1'
APPWRITE_PROJECT_ID = 'YOUR_PROJECT_ID'  # Replace with your project ID
APPWRITE_API_KEY = 'YOUR_API_KEY'  # Replace with your API key
DATABASE_ID = '143973bc-3217-4b7e-a1ca-05082dfde404'

def setup_appwrite():
    """Initialize Appwrite client and set up collections"""
    
    # Verify credentials
    if APPWRITE_PROJECT_ID == 'YOUR_PROJECT_ID' or APPWRITE_API_KEY == 'YOUR_API_KEY':
        print('❌ Error: Please update APPWRITE_PROJECT_ID and APPWRITE_API_KEY')
        print('\nTo find your credentials:')
        print('1. Go to https://fra.cloud.appwrite.io/console')
        print('2. Project ID: Settings → Project ID')
        print('3. API Key: Settings → API Keys → Create API Key')
        sys.exit(1)
    
    # Initialize client
    client = Client()
    client.set_endpoint(APPWRITE_ENDPOINT)
    client.set_project(APPWRITE_PROJECT_ID)
    client.set_key(APPWRITE_API_KEY)
    
    databases = Databases(client)
    
    print('🚀 Starting Appwrite Collections Setup...\n')
    print(f'Database ID: {DATABASE_ID}')
    print(f'Endpoint: {APPWRITE_ENDPOINT}\n')
    
    try:
        # ==================== BUDGETS COLLECTION ====================
        print('Creating collection: Budgets (budgets)...')
        try:
            databases.create_collection(
                database_id=DATABASE_ID,
                collection_id='budgets',
                name='Budgets',
                permissions=[
                    'read("user:*")',
                    'write("user:*")',
                    'create("user:*")',
                    'update("user:*")',
                    'delete("user:*")',
                ],
            )
            print('✓ Collection created: Budgets')
        except Exception as e:
            if 'already exists' in str(e):
                print('✓ Collection already exists: Budgets')
            else:
                raise
        
        # Add attributes to budgets collection
        budgets_attributes = [
            ('userId', 'string', 255, True),
            ('category', 'string', 100, True),
            ('amount', 'float', None, True),
            ('month', 'integer', None, True),
            ('year', 'integer', None, True),
            ('createdAt', 'datetime', None, False),
            ('updatedAt', 'datetime', None, False),
        ]
        
        for attr_key, attr_type, size, required in budgets_attributes:
            print(f'  - Adding attribute: {attr_key}...')
            try:
                if attr_type == 'string':
                    databases.create_string_attribute(
                        database_id=DATABASE_ID,
                        collection_id='budgets',
                        key=attr_key,
                        size=size,
                        required=required,
                    )
                elif attr_type == 'float':
                    databases.create_float_attribute(
                        database_id=DATABASE_ID,
                        collection_id='budgets',
                        key=attr_key,
                        required=required,
                        min=0 if attr_key == 'amount' else None,
                    )
                elif attr_type == 'integer':
                    databases.create_integer_attribute(
                        database_id=DATABASE_ID,
                        collection_id='budgets',
                        key=attr_key,
                        required=required,
                        min=1 if attr_key == 'month' else 2020,
                        max=12 if attr_key == 'month' else 2100,
                    )
                elif attr_type == 'datetime':
                    databases.create_datetime_attribute(
                        database_id=DATABASE_ID,
                        collection_id='budgets',
                        key=attr_key,
                        required=required,
                    )
                print(f'    ✓ Attribute added: {attr_key}')
            except Exception as e:
                if 'already exists' in str(e):
                    print(f'    ✓ Attribute already exists: {attr_key}')
                else:
                    raise
        
        # Add indexes to budgets
        print('  - Adding indexes...')
        try:
            databases.create_index(
                database_id=DATABASE_ID,
                collection_id='budgets',
                key='userId_idx',
                type='key',
                attributes=['userId'],
            )
        except:
            pass
        
        # ==================== ACCOUNTS COLLECTION ====================
        print('\nCreating collection: Accounts (accounts)...')
        try:
            databases.create_collection(
                database_id=DATABASE_ID,
                collection_id='accounts',
                name='Accounts',
                permissions=[
                    'read("user:*")',
                    'write("user:*")',
                    'create("user:*")',
                    'update("user:*")',
                    'delete("user:*")',
                ],
            )
            print('✓ Collection created: Accounts')
        except Exception as e:
            if 'already exists' in str(e):
                print('✓ Collection already exists: Accounts')
            else:
                raise
        
        # Add attributes to accounts collection
        accounts_attributes = [
            ('userId', 'string', 255, True),
            ('name', 'string', 100, True),
            ('type', 'string', 50, True),
            ('initialBalance', 'float', None, True),
            ('currency', 'string', 10, False),
            ('isActive', 'boolean', None, False),
            ('createdAt', 'datetime', None, False),
            ('updatedAt', 'datetime', None, False),
        ]
        
        for attr_key, attr_type, size, required in accounts_attributes:
            print(f'  - Adding attribute: {attr_key}...')
            try:
                if attr_type == 'string':
                    databases.create_string_attribute(
                        database_id=DATABASE_ID,
                        collection_id='accounts',
                        key=attr_key,
                        size=size,
                        required=required,
                    )
                elif attr_type == 'float':
                    databases.create_float_attribute(
                        database_id=DATABASE_ID,
                        collection_id='accounts',
                        key=attr_key,
                        required=required,
                    )
                elif attr_type == 'boolean':
                    databases.create_boolean_attribute(
                        database_id=DATABASE_ID,
                        collection_id='accounts',
                        key=attr_key,
                        required=required,
                    )
                elif attr_type == 'datetime':
                    databases.create_datetime_attribute(
                        database_id=DATABASE_ID,
                        collection_id='accounts',
                        key=attr_key,
                        required=required,
                    )
                print(f'    ✓ Attribute added: {attr_key}')
            except Exception as e:
                if 'already exists' in str(e):
                    print(f'    ✓ Attribute already exists: {attr_key}')
                else:
                    raise
        
        print('\n✅ Setup completed successfully!')
        print('\nNext steps:')
        print('1. Verify collections in Appwrite Console')
        print('2. Restart your Flutter app')
        print('3. Add some transactions to generate AI insights')
        
    except Exception as e:
        print(f'\n❌ Setup failed: {str(e)}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    setup_appwrite()
