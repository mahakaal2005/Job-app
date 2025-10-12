# Backend Changes Required

This document lists all backend/infrastructure changes that cannot be done through code modifications alone and require Firebase Console access or external configuration.

---

## 1. Firestore Composite Indexes

### Status
🔴 **REQUIRED** - App shows errors without these indexes

### What's Needed
Create 2 composite indexes in Firestore to enable job statistics queries.

### Why Required
- Firestore requires indexes for queries with multiple `where` clauses on collection groups
- Without indexes: `FAILED_PRECONDITION` errors
- With indexes: Efficient count aggregation queries work properly

### Indexes to Create

#### Index 1: Employment Type Filter
```
Collection Group: jobPostings
Query Scope: Collection group
Fields:
  - isActive (Ascending)
  - employmentType (Ascending)
```

#### Index 2: Work Location Filter
```
Collection Group: jobPostings
Query Scope: Collection group
Fields:
  - isActive (Ascending)
  - workFrom (Ascending)
```

### How to Create

**Method 1: Automatic (Recommended)**
1. Run the app and navigate to home screen
2. Check console/logcat for error messages
3. Copy the Firebase Console URLs from error messages
4. Open URLs in browser - Firebase auto-fills the configuration
5. Click "Create Index" button
6. Wait 5-10 minutes for indexes to build

**Method 2: Manual**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `get-work-48682`
3. Navigate to: Firestore Database → Indexes tab
4. Click "Create Index"
5. Configure as specified above
6. Click "Create"

**Method 3: Firebase CLI**
```bash
# Create firestore.indexes.json in project root
firebase deploy --only firestore:indexes
```

### Access Required
- Firebase Console access with "Editor" or "Owner" role
- Project: `get-work-48682`

### Impact
- **Without indexes**: Statistics show counts from loaded jobs only (fallback mode)
- **With indexes**: Statistics show accurate total counts from entire database

### Time Required
- Creation: 2 minutes
- Building: 5-10 minutes
- One-time setup

### Risk Level
🟢 **LOW** - Indexes don't modify data, only improve query performance

### Verification
```bash
# After creation, check Firebase Console
# Status should show "Enabled" (not "Building")
```

---

## 2. Firebase Authentication Configuration

### Status
🟢 **CONFIGURED** - Already set up, no action needed

### Current Setup
- Email/Password authentication enabled
- Password reset emails configured
- Firebase Auth working correctly

### Future Considerations
- If adding new auth providers (Google, Facebook, etc.), requires Firebase Console configuration
- Email templates can be customized in Firebase Console → Authentication → Templates

---

## 3. Firebase Storage Rules (If Applicable)

### Status
🟡 **REVIEW RECOMMENDED**

### What to Check
If the app uploads profile pictures or resumes to Firebase Storage:

```javascript
// Recommended Storage Rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /companies/{companyId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Access Required
- Firebase Console → Storage → Rules tab

### Risk Level
🟡 **MEDIUM** - Incorrect rules can expose user data

---

## 4. Firestore Security Rules

### Status
🟡 **REVIEW RECOMMENDED**

### Current Concern
Ensure proper security rules are in place for:
- User data access
- Job postings access
- Application submissions
- Company data

### Recommended Rules Structure
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own data
    match /users_specific/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Employees can read/write their own data
    match /employees/{employeeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == employeeId;
    }
    
    // Job postings - read by all authenticated, write by company owner
    match /jobs/{companyId}/jobPostings/{jobId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Add company ownership check
    }
    
    // Applications - read/write by applicant and company
    match /jobs/{companyId}/jobPostings/{jobId}/applicants/{applicantId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == applicantId || 
                      request.auth.uid == companyId);
      allow write: if request.auth != null && request.auth.uid == applicantId;
    }
  }
}
```

### Access Required
- Firebase Console → Firestore Database → Rules tab

### Risk Level
🔴 **HIGH** - Incorrect rules can expose sensitive data

---

## 5. Environment Variables / API Keys

### Status
🟢 **CONFIGURED** - Firebase config in code

### Current Setup
- Firebase configuration in `lib/firebase_options.dart`
- API keys properly configured

### Security Note
- Ensure `firebase_options.dart` is not committed to public repositories
- API keys should be restricted in Firebase Console → Project Settings → API Keys

### Access Required
- Firebase Console → Project Settings

---

## 6. Cloud Functions (If Needed in Future)

### Status
⚪ **NOT IMPLEMENTED** - Optional for future

### Potential Use Cases
1. **Job Statistics Aggregation**
   - Maintain real-time counts in a separate document
   - Update counts when jobs are created/deleted
   - Eliminates need for count queries

2. **Email Notifications**
   - Send job application confirmations
   - Notify employers of new applications
   - Send job recommendations

3. **Data Cleanup**
   - Archive old job postings
   - Clean up expired applications
   - Maintain data consistency

### If Implementing
```bash
# Initialize Cloud Functions
firebase init functions

# Deploy functions
firebase deploy --only functions
```

### Access Required
- Firebase Console with Blaze (pay-as-you-go) plan
- Cloud Functions enabled

---

## 7. Firebase Hosting (If Deploying Web Version)

### Status
⚪ **NOT APPLICABLE** - Mobile app only

### If Needed
```bash
firebase init hosting
firebase deploy --only hosting
```

---

## Summary Checklist

### Immediate Action Required
- [ ] **Create Firestore Indexes** (2 indexes) - 🔴 HIGH PRIORITY
  - Required for job statistics to work properly
  - 10 minutes setup time
  - No risk to data

### Recommended Reviews
- [ ] **Review Firestore Security Rules** - 🟡 MEDIUM PRIORITY
  - Ensure data is properly secured
  - Prevent unauthorized access
  - 30 minutes review time

- [ ] **Review Firebase Storage Rules** (if using Storage) - 🟡 MEDIUM PRIORITY
  - Secure user uploads
  - 15 minutes review time

### Optional Optimizations
- [ ] **Implement Cloud Functions for Statistics** - ⚪ OPTIONAL
  - Would eliminate need for indexes
  - More complex setup
  - Better for large scale

---

## Access Requirements Summary

| Task | Access Level | Project |
|------|-------------|---------|
| Create Firestore Indexes | Editor/Owner | get-work-48682 |
| Review Security Rules | Editor/Owner | get-work-48682 |
| Configure Storage Rules | Editor/Owner | get-work-48682 |
| Deploy Cloud Functions | Owner + Blaze Plan | get-work-48682 |

---

## Getting Firebase Console Access

If you don't have access:

1. **Request Access**
   - Ask project owner to add you
   - Provide your Google account email
   - Request "Editor" role minimum

2. **Verify Access**
   ```
   1. Go to https://console.firebase.google.com/
   2. Look for project: get-work-48682
   3. You should see Firestore, Authentication, etc.
   ```

3. **If Owner**
   - You can add team members in Project Settings → Users and Permissions

---

## Support Resources

- **Firestore Indexes**: [Firebase Docs](https://firebase.google.com/docs/firestore/query-data/indexing)
- **Security Rules**: [Firebase Docs](https://firebase.google.com/docs/firestore/security/get-started)
- **Cloud Functions**: [Firebase Docs](https://firebase.google.com/docs/functions)
- **Firebase CLI**: [Installation Guide](https://firebase.google.com/docs/cli)

---

**Document Version**: 1.0  
**Last Updated**: 10/12/2025  
**Project**: Look Gig Job App  
**Firebase Project ID**: get-work-48682  
**Maintained By**: Development Team
