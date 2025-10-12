# Firestore Indexes Required

## Overview
The job statistics feature requires Firestore composite indexes to function properly. These indexes enable efficient querying across the `jobPostings` collection group.

## Required Indexes

### 1. Full Time Jobs Index
**Collection Group**: `jobPostings`
**Fields**:
- `isActive` (Ascending)
- `employmentType` (Ascending)

### 2. Part Time Jobs Index
**Collection Group**: `jobPostings`
**Fields**:
- `isActive` (Ascending)
- `employmentType` (Ascending)

**Note**: This is the same index as Full Time (both use employmentType field)

### 3. Remote Jobs Index
**Collection Group**: `jobPostings`
**Fields**:
- `isActive` (Ascending)
- `workFrom` (Ascending)

## How to Create Indexes

### Option 1: Automatic (Recommended)
1. Run the app and navigate to the home screen
2. Check the console/logcat for error messages
3. Click the Firebase Console URLs provided in the error messages
4. Firebase will automatically create the required indexes

### Option 2: Manual Creation
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `get-work-48682`
3. Navigate to **Firestore Database** → **Indexes** tab
4. Click **Create Index**
5. Configure each index:
   - **Collection Group ID**: `jobPostings`
   - **Fields to index**:
     - Add `isActive` (Ascending)
     - Add `employmentType` (Ascending) OR `workFrom` (Ascending)
   - **Query scope**: Collection group
6. Click **Create**
7. Wait for indexes to build (usually takes a few minutes)

### Option 3: Using Firebase CLI
```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy indexes from firestore.indexes.json
firebase deploy --only firestore:indexes
```

## Index Configuration File

Create a `firestore.indexes.json` file in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "jobPostings",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "employmentType",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "jobPostings",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "workFrom",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## Current Status

### Without Indexes
- ⚠️ Job statistics will show counts from loaded jobs only (fallback mode)
- ⚠️ Console will show `FAILED_PRECONDITION` errors
- ✅ App still functions normally
- ✅ Statistics update as jobs load

### With Indexes
- ✅ Job statistics show accurate total counts from entire database
- ✅ No console errors
- ✅ Efficient count() aggregation queries
- ✅ Fast performance

## Verification

After creating indexes:
1. Wait for indexes to finish building (check Firebase Console)
2. Restart the app
3. Navigate to home screen
4. Check console - should see no index errors
5. Job statistics should display accurate counts

## Troubleshooting

### Indexes Still Building
- Check Firebase Console → Firestore → Indexes
- Status should show "Enabled" (not "Building")
- Building can take 5-30 minutes depending on data size

### Still Getting Errors
- Clear app cache and restart
- Verify index configuration matches exactly
- Check that indexes are for "Collection Group" not "Collection"

### Fallback Mode Working
- If indexes can't be created immediately, the app uses fallback
- Fallback calculates statistics from loaded jobs
- This is acceptable for development/testing

## Additional Resources

- [Firestore Index Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Collection Group Queries](https://firebase.google.com/docs/firestore/query-data/queries#collection-group-query)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

---

**Last Updated**: 10/12/2025
**Project**: Look Gig Job App
**Firebase Project**: get-work-48682
