#!/usr/bin/env node

/**
 * Appwrite Collections Setup Script
 *
 * This script creates the required collections and attributes in Appwrite
 * for the Smart Expense Tracker application.
 *
 * Prerequisites:
 * - Node.js installed
 * - npm package manager
 * - Access to Appwrite server
 * - Admin credentials or API key
 *
 * Usage:
 * node setup_appwrite_collections.js
 */

const https = require('https')

// Configuration
const APPWRITE_ENDPOINT = 'https://fra.cloud.appwrite.io/v1'
const APPWRITE_PROJECT_ID = 'YOUR_PROJECT_ID' // Replace with your project ID
const APPWRITE_API_KEY = 'YOUR_API_KEY' // Replace with your API key
const DATABASE_ID = '143973bc-3217-4b7e-a1ca-05082dfde404'

// Helper function to make HTTP requests
function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(APPWRITE_ENDPOINT + path)
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': APPWRITE_PROJECT_ID,
        'X-Appwrite-Key': APPWRITE_API_KEY,
      },
    }

    const req = https.request(options, (res) => {
      let responseData = ''

      res.on('data', (chunk) => {
        responseData += chunk
      })

      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData)
          if (res.statusCode >= 400) {
            reject(
              new Error(
                `HTTP ${res.statusCode}: ${parsed.message || responseData}`
              )
            )
          } else {
            resolve(parsed)
          }
        } catch (e) {
          reject(new Error(`Failed to parse response: ${responseData}`))
        }
      })
    })

    req.on('error', reject)

    if (data) {
      req.write(JSON.stringify(data))
    }

    req.end()
  })
}

// Create or verify collection
async function createCollection(collectionId, collectionName) {
  try {
    console.log(`\nCreating collection: ${collectionName} (${collectionId})...`)
    const result = await makeRequest(
      'POST',
      `/databases/${DATABASE_ID}/collections`,
      {
        collectionId: collectionId,
        name: collectionName,
        permissions: [
          'read("user:*")',
          'write("user:*")',
          'create("user:*")',
          'update("user:*")',
          'delete("user:*")',
        ],
      }
    )
    console.log(`✓ Collection created: ${collectionName}`)
    return result
  } catch (error) {
    if (error.message.includes('already exists')) {
      console.log(`✓ Collection already exists: ${collectionName}`)
      return
    }
    throw error
  }
}

// Create attribute
async function createAttribute(collectionId, attribute) {
  try {
    const path = `/databases/${DATABASE_ID}/collections/${collectionId}/attributes/${attribute.type}`
    console.log(`  - Adding attribute: ${attribute.name}...`)

    const payload = {
      key: attribute.key,
      type: attribute.type,
      size: attribute.size || undefined,
      required: attribute.required || false,
      default: attribute.default || undefined,
      min: attribute.min !== undefined ? attribute.min : undefined,
      max: attribute.max !== undefined ? attribute.max : undefined,
      xmin: attribute.xmin !== undefined ? attribute.xmin : undefined,
      xmax: attribute.xmax !== undefined ? attribute.xmax : undefined,
      regex: attribute.regex || undefined,
    }

    // Remove undefined fields
    Object.keys(payload).forEach(
      (key) => payload[key] === undefined && delete payload[key]
    )

    await makeRequest('POST', path, payload)
    console.log(`    ✓ Attribute added: ${attribute.name}`)
  } catch (error) {
    if (error.message.includes('already exists')) {
      console.log(`    ✓ Attribute already exists: ${attribute.name}`)
      return
    }
    throw error
  }
}

// Create index
async function createIndex(collectionId, indexKey, attributes, type = 'key') {
  try {
    console.log(`  - Adding index: ${indexKey}...`)
    await makeRequest(
      'POST',
      `/databases/${DATABASE_ID}/collections/${collectionId}/indexes`,
      {
        key: indexKey,
        type: type,
        attributes: attributes,
      }
    )
    console.log(`    ✓ Index created: ${indexKey}`)
  } catch (error) {
    if (error.message.includes('already exists')) {
      console.log(`    ✓ Index already exists: ${indexKey}`)
      return
    }
    throw error
  }
}

// Main setup function
async function setup() {
  try {
    console.log('🚀 Starting Appwrite Collections Setup...\n')
    console.log(`Database ID: ${DATABASE_ID}`)
    console.log(`Endpoint: ${APPWRITE_ENDPOINT}\n`)

    // ==================== BUDGETS COLLECTION ====================
    await createCollection('budgets', 'Budgets')

    const budgetsAttributes = [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'category', type: 'string', size: 100, required: true },
      { key: 'amount', type: 'float', required: true, min: 0 },
      { key: 'month', type: 'integer', required: true, min: 1, max: 12 },
      { key: 'year', type: 'integer', required: true, min: 2020, max: 2100 },
      { key: 'createdAt', type: 'datetime', required: false },
      { key: 'updatedAt', type: 'datetime', required: false },
    ]

    for (const attr of budgetsAttributes) {
      await createAttribute('budgets', attr)
    }

    await createIndex('budgets', 'userId_idx', ['userId'])
    await createIndex('budgets', 'category_idx', ['category'])
    await createIndex('budgets', 'month_year_idx', ['month', 'year'])

    // ==================== ACCOUNTS COLLECTION ====================
    await createCollection('accounts', 'Accounts')

    const accountsAttributes = [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'name', type: 'string', size: 100, required: true },
      { key: 'type', type: 'string', size: 50, required: true },
      { key: 'initialBalance', type: 'float', required: true },
      {
        key: 'currency',
        type: 'string',
        size: 10,
        required: false,
        default: 'BDT',
      },
      { key: 'isActive', type: 'boolean', required: false, default: true },
      { key: 'createdAt', type: 'datetime', required: false },
      { key: 'updatedAt', type: 'datetime', required: false },
    ]

    for (const attr of accountsAttributes) {
      await createAttribute('accounts', attr)
    }

    await createIndex('accounts', 'userId_idx', ['userId'])
    await createIndex('accounts', 'isActive_idx', ['isActive'])

    console.log('\n✅ Setup completed successfully!')
    console.log('\nNext steps:')
    console.log(
      '1. Update the APPWRITE_PROJECT_ID and APPWRITE_API_KEY in this script'
    )
    console.log('2. Run: node setup_appwrite_collections.js')
    console.log('3. Verify collections in Appwrite Console')
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message)
    process.exit(1)
  }
}

// Check if credentials are set
if (
  APPWRITE_PROJECT_ID === 'YOUR_PROJECT_ID' ||
  APPWRITE_API_KEY === 'YOUR_API_KEY'
) {
  console.error(
    '❌ Error: Please update APPWRITE_PROJECT_ID and APPWRITE_API_KEY in the script'
  )
  console.error('\nTo find your credentials:')
  console.error('1. Go to https://fra.cloud.appwrite.io/console')
  console.error('2. Project ID: Settings → Project ID')
  console.error('3. API Key: Settings → API Keys → Create API Key')
  process.exit(1)
}

setup()
