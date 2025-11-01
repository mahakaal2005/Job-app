import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Debug logging helper
  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('🔵 [AUTH_SERVICE] $message');
    }
  }
  
  static void _errorLog(String message, dynamic error) {
    if (kDebugMode) {
      debugPrint('🔴 [AUTH_SERVICE] $message');
      debugPrint('🔴 [AUTH_SERVICE] Error: $error');
      debugPrint('🔴 [AUTH_SERVICE] Error Type: ${error.runtimeType}');
    }
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges {
    print('🔵 [AUTH_SERVICE] authStateChanges stream requested');
    return _auth.authStateChanges().map((user) {
      print('🔵 [AUTH_SERVICE] Auth state changed - User: ${user?.uid ?? 'null'}');
      return user;
    });
  }

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'employer' or 'user'
  }) async {
    try {
      _debugLog('Starting email signup for: $email with role: $role');
      
      // Check if email is already registered before creating account
      bool isRegistered = await isEmailRegistered(email);
      if (isRegistered) {
        _debugLog('Email already registered: $email');
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account already exists for this email address.',
        );
      }

      // Create user with email and password
      _debugLog('Creating Firebase Auth user...');
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);
      _debugLog('User created with UID: ${userCredential.user?.uid}');

      // Prepare user data
      Map<String, dynamic> userData = {
        'uid': userCredential.user?.uid,
        'email': email,
        'fullName': fullName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'onboardingCompleted': false, // Both roles need onboarding now
        'skippedOnboarding': false, // NEW - tracks if they skipped
      };

      // Save to role-specific collection only
      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';
      _debugLog('Saving user data to Firestore collection: $collectionName');
      await _firestore
          .collection(collectionName)
          .doc(userCredential.user?.uid)
          .set(userData);

      _debugLog('Email signup completed successfully');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _errorLog('Firebase Auth error during signup', e);
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      _errorLog('Unexpected error during signup', e);
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // CRITICAL: Sign out first to force account picker
      // This ensures the user is always prompted to choose an account
      // even if they previously signed in with Google
      try {
        await _googleSignIn.signOut();
        print(
          'ðŸ”„ Signed out from Google before sign-in to force account picker',
        );
      } catch (e) {
        print('âš ï¸ Pre-signin signOut failed (this is okay): $e');
        // Continue even if signOut fails
      }

      // Trigger the authentication flow
      // This will now ALWAYS show the account picker
      // signIn() (not signInSilently()) ensures the picker is shown
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if this is a new user or existing user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // This is a new user, they need to complete profile setup
        // We'll handle this in the UI by checking if user document exists
        return userCredential;
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code);
    } catch (e) {
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  // Sign up with Google (creates user document with role)
  static Future<UserCredential?> signUpWithGoogle({
    required String role, // 'employer' or 'user'
  }) async {
    try {
      // First, sign in with Google
      UserCredential? userCredential = await signInWithGoogle();

      if (userCredential == null) return null;

      // Create user document with the specified role
      await _createOrUpdateGoogleUser(userCredential.user!, role);

      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-Up failed: ${e.toString()}');
    }
  }

  // Create or update Google user document
  static Future<void> _createOrUpdateGoogleUser(User user, String role) async {
    try {
      // Check if user already exists in either collection (without creating default)
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(user.uid).get();

      if (employerDoc.exists) {
        // User already exists as employer, don't change their role
        print('ðŸ” DEBUG: User already exists as employer');
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users_specific').doc(user.uid).get();

      if (userDoc.exists) {
        // User already exists as user, don't change their role
        print('ðŸ” DEBUG: User already exists as user');
        return;
      }

      // Create new user document in the correct collection
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'fullName': user.displayName ?? '',
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'onboardingCompleted': false,
        'skippedOnboarding': false, // NEW - tracks if they skipped
        'signInMethod': 'google',
        'photoURL': user.photoURL,
      };

      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';

      print(
        'ðŸ” DEBUG: Creating Google user with role=$role in collection=$collectionName',
      );

      await _firestore.collection(collectionName).doc(user.uid).set(userData);

      print('âœ… DEBUG: Successfully created user document');
    } catch (e) {
      print('âŒ ERROR: Failed to create user document: ${e.toString()}');
      throw Exception('Failed to create user document: ${e.toString()}');
    }
  }

  // Check if Google user needs role selection
  static Future<bool> doesGoogleUserNeedRoleSelection() async {
    try {
      if (currentUser == null) return false;

      // Check if user document exists in either collection
      String? role = await getUserRole();
      return role == null;
    } catch (e) {
      return true; // If error, assume they need role selection
    }
  }

  // Sign out (handles both email and Google sign out)
  static Future<void> signOut() async {
    try {
      // Use disconnect() instead of signOut() to completely remove the Google account
      // This forces the account picker to show on next sign-in
      // disconnect() revokes access and clears all cached credentials
      await _googleSignIn.disconnect();
      print(
        'âœ… Google Sign-In disconnected - account picker will show on next sign-in',
      );
    } catch (e) {
      // If disconnect fails (e.g., user wasn't signed in with Google), try signOut
      print('âš ï¸ Google disconnect failed, trying signOut: $e');
      try {
        await _googleSignIn.signOut();
      } catch (e2) {
        print('âš ï¸ Google signOut also failed: $e2');
        // Continue with Firebase signOut even if Google signOut fails
      }
    }

    try {
      // Always sign out from Firebase Auth
      await _auth.signOut();
      print('âœ… Firebase Auth signed out');
    } catch (e) {
      throw Exception('Failed to sign out from Firebase: ${e.toString()}');
    }
  }

  // Migration helper: Check old 'employees' collection and migrate to 'employers'
  static Future<bool> _migrateEmployeeToEmployer(String uid) async {
    try {
      print('DEBUG [MIGRATION] Starting migration check for user: $uid');

      print('DEBUG [MIGRATION] About to query employees collection...');
      
      // Add shorter timeout and better error handling
      DocumentSnapshot oldEmployeeDoc = await _firestore
          .collection('employees')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        print('DEBUG [MIGRATION] Timeout checking employees collection - skipping migration');
        throw Exception('Timeout checking employees collection');
      });

      print('DEBUG [MIGRATION] Employees collection query completed');

      if (!oldEmployeeDoc.exists) {
        print('DEBUG [MIGRATION] User not found in old employees collection');
        return false;
      }

      print('DEBUG [MIGRATION] Found user in old employees collection, migrating...');

      // Get the data
      Map<String, dynamic> userData = oldEmployeeDoc.data() as Map<String, dynamic>;

      // Add migration timestamp and ensure role is set correctly
      userData['migratedAt'] = FieldValue.serverTimestamp();
      userData['migratedFrom'] = 'employees';
      userData['role'] = 'employer'; // Ensure role is set correctly

      // Copy to new 'employers' collection with timeout
      print('DEBUG [MIGRATION] About to copy data to employers collection...');
      await _firestore
          .collection('employers')
          .doc(uid)
          .set(userData)
          .timeout(const Duration(seconds: 5));
      print('DEBUG [MIGRATION] Data copied to employers collection');

      // Mark old document as migrated (don't fail if this fails)
      try {
        print('DEBUG [MIGRATION] About to mark old document as migrated...');
        await _firestore.collection('employees').doc(uid).update({
          'migrated': true,
          'migratedAt': FieldValue.serverTimestamp(),
          'migratedTo': 'employers',
        }).timeout(const Duration(seconds: 3));
        print('DEBUG [MIGRATION] Old document marked as migrated');
      } catch (e) {
        print('DEBUG [MIGRATION] Failed to mark old document as migrated (non-critical): $e');
        // Don't fail the migration if we can't mark the old document
      }

      return true;
    } catch (e) {
      print('DEBUG [MIGRATION] Error during migration: $e');
      print('DEBUG [MIGRATION] Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Get user role with better error handling and migration support
  static Future<String?> getUserRole() async {
    try {
      print('\n🔵 ═══════════════════════════════════════════════════════');
      print('🔵 [GET_ROLE] Starting getUserRole');
      print('🔵 ═══════════════════════════════════════════════════════');

      if (currentUser == null) {
        print('🔴 [GET_ROLE] No current user - returning null');
        return null;
      }

      print('📧 [GET_ROLE] User Email: ${currentUser!.email}');
      print('🆔 [GET_ROLE] User UID: ${currentUser!.uid}');
      print('👤 [GET_ROLE] Display Name: ${currentUser!.displayName}');

      // STEP 1: Check employers collection FIRST
      print('\n📁 [GET_ROLE] STEP 1: Checking EMPLOYERS collection...');
      try {
        final startTime = DateTime.now();
        DocumentSnapshot employerDoc = await _firestore
            .collection('employers')
            .doc(currentUser!.uid)
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          print('⏱️ [GET_ROLE] TIMEOUT checking employers collection (5 seconds)');
          throw Exception('Timeout checking employers collection');
        });
        final duration = DateTime.now().difference(startTime);
        print('⏱️ [GET_ROLE] Query completed in ${duration.inMilliseconds}ms');

        if (employerDoc.exists) {
          print('✅ [GET_ROLE] FOUND in employers collection');
          final data = employerDoc.data() as Map<String, dynamic>?;
          print('📋 [GET_ROLE] Document data:');
          data?.forEach((key, value) {
            print('   $key: $value');
          });
          print('🎯 [GET_ROLE] Returning role: EMPLOYER');
          print('🔵 ═══════════════════════════════════════════════════════\n');
          return 'employer';
        } else {
          print('❌ [GET_ROLE] Document does NOT exist in employers collection');
        }
      } catch (e) {
        print('⚠️ [GET_ROLE] ERROR checking employers collection:');
        print('   Error: $e');
        print('   Type: ${e.runtimeType}');
        print('   Continuing to check users_specific...');
      }

      // STEP 2: Check users_specific collection
      print('\n📁 [GET_ROLE] STEP 2: Checking USERS_SPECIFIC collection...');
      try {
        final startTime = DateTime.now();
        DocumentSnapshot userDoc = await _firestore
            .collection('users_specific')
            .doc(currentUser!.uid)
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          print('⏱️ [GET_ROLE] TIMEOUT checking users_specific collection (5 seconds)');
          throw Exception('Timeout checking users_specific collection');
        });
        final duration = DateTime.now().difference(startTime);
        print('⏱️ [GET_ROLE] Query completed in ${duration.inMilliseconds}ms');

        if (userDoc.exists) {
          print('✅ [GET_ROLE] FOUND in users_specific collection');
          final data = userDoc.data() as Map<String, dynamic>?;
          print('📋 [GET_ROLE] Document data:');
          data?.forEach((key, value) {
            print('   $key: $value');
          });
          print('🎯 [GET_ROLE] Returning role: USER');
          print('🔵 ═══════════════════════════════════════════════════════\n');
          return 'user';
        } else {
          print('❌ [GET_ROLE] Document does NOT exist in users_specific collection');
          print('📊 [GET_ROLE] Document ID checked: ${currentUser!.uid}');
        }
      } catch (e) {
        print('⚠️ [GET_ROLE] ERROR checking users_specific collection:');
        print('   Error: $e');
        print('   Type: ${e.runtimeType}');
      }

      // STEP 3: Check old employees collection for migration
      print('\n📁 [GET_ROLE] STEP 3: Checking EMPLOYEES collection (legacy)...');
      try {
        bool migrated = await _migrateEmployeeToEmployer(currentUser!.uid);
        if (migrated) {
          print('✅ [GET_ROLE] Successfully migrated from employees to employers');
          print('🎯 [GET_ROLE] Returning role: EMPLOYER');
          print('🔵 ═══════════════════════════════════════════════════════\n');
          return 'employer';
        }
      } catch (e) {
        print('⚠️ [GET_ROLE] Migration failed: $e');
      }

      // User document doesn't exist - create default
      print('\n🔨 [GET_ROLE] No user document found - creating default document...');
      print('📧 [GET_ROLE] Email: ${currentUser!.email}');
      print('🆔 [GET_ROLE] UID: ${currentUser!.uid}');
      print('👤 [GET_ROLE] Name: ${currentUser!.displayName ?? "Unknown"}');
      
      try {
        print('⏳ [GET_ROLE] Calling _createUserDocument with role: user');
        await _createUserDocument('user'); // Default to regular user
        print('✅ [GET_ROLE] Default user document created successfully');
        print('🎯 [GET_ROLE] Returning role: user');
        print('🔵 ═══════════════════════════════════════════════════════\n');
        return 'user';
      } catch (e) {
        print('⚠️ [GET_ROLE] FAILED to create default user document:');
        print('   Error: $e');
        print('   Type: ${e.runtimeType}');
        print('🎯 [GET_ROLE] Returning fallback role: user');
        print('🔵 ═══════════════════════════════════════════════════════\n');
        return 'user';
      }
    } catch (e) {
      print('\n🔴 ═══════════════════════════════════════════════════════');
      print('🔴 [GET_ROLE] CRITICAL ERROR in getUserRole');
      print('🔴 ═══════════════════════════════════════════════════════');
      print('❌ Error: $e');
      print('📝 Error type: ${e.runtimeType}');
      print('📚 Stack trace:');
      print(StackTrace.current);
      print('🔴 ═══════════════════════════════════════════════════════\n');
      throw Exception('Failed to get user role: ${e.toString()}');
    }
  }


  static Future<String?> getCurrentUserId() async {
    try {
      if (currentUser == null) return null;
      return currentUser!.uid;
    } catch (e) {
      throw Exception('Failed to get current user ID: ${e.toString()}');
    }
  }

  // Alias for getUserRole() for consistency
  static Future<String?> getCurrentUserRole() async {
    return await getUserRole();
  }

  // Check if user has completed onboarding
  static Future<bool> hasUserCompletedOnboarding(String uid) async {
    try {
      // Check in EMPLOYERs collection first
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(uid).get();

      if (employerDoc.exists) {
        Map<String, dynamic> employerData =
            employerDoc.data() as Map<String, dynamic>;
        print(
          'DEBUG [ONBOARDING_CHECK] Found in employers - onboardingCompleted: ${employerData['onboardingCompleted']}',
        );
        return employerData['onboardingCompleted'] ?? false;
      }

      print(
        'DEBUG [ONBOARDING_CHECK] Not in employers, checking old employees collection...',
      );

      // Try migration from old employees collection
      bool migrated = await _migrateEmployeeToEmployer(uid);
      if (migrated) {
        // After migration, check again
        DocumentSnapshot newEmployerDoc =
            await _firestore.collection('employers').doc(uid).get();
        if (newEmployerDoc.exists) {
          Map<String, dynamic> employerData =
              newEmployerDoc.data() as Map<String, dynamic>;
          print(
            'DEBUG [ONBOARDING_CHECK] After migration - onboardingCompleted: ${employerData['onboardingCompleted']}',
          );
          return employerData['onboardingCompleted'] ?? false;
        }
      }

      // Check in users_specific collection
      print('DEBUG [ONBOARDING_CHECK] Checking users_specific collection...');
      DocumentSnapshot userDoc =
          await _firestore.collection('users_specific').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print(
          'DEBUG [ONBOARDING_CHECK] Found in users_specific - onboardingCompleted: ${userData['onboardingCompleted']}',
        );
        return userData['onboardingCompleted'] ?? false;
      }

      print('DEBUG [ONBOARDING_CHECK] User not found in any collection');
      return false;
    } catch (e) {
      print('DEBUG [ONBOARDING_CHECK] Error: $e');
      // If there's an error, assume onboarding is not completed
      return false;
    }
  }

  // Check if current user has completed onboarding
  static Future<bool> hasCurrentUserCompletedOnboarding() async {
    if (currentUser == null) return false;
    return await hasUserCompletedOnboarding(currentUser!.uid);
  }

  // Complete user onboarding (works for both EMPLOYERs and users)
  static Future<void> completeUserOnboarding(
    Map<String, dynamic> onboardingData,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      // Try to find user in both collections
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      DocumentSnapshot userDoc =
          await _firestore
              .collection('users_specific')
              .doc(currentUser!.uid)
              .get();

      String collectionName;
      bool documentExists = false;

      if (employerDoc.exists) {
        collectionName = 'employers';
        documentExists = true;
      } else if (userDoc.exists) {
        collectionName = 'users_specific';
        documentExists = true;
      } else {
        // Document doesn't exist - determine role from onboarding data
        // Default to 'user' if not specified (most onboarding flows are for users/students)
        print(
          'âš ï¸ WARNING: User document not found during onboarding for ${currentUser!.uid}',
        );
        print('ðŸ“ Creating user document from onboarding data...');

        // Determine collection based on onboarding data or default to users_specific
        String userType = onboardingData['userType'] ?? 'student';
        collectionName =
            (userType == 'employer') ? 'employers' : 'users_specific';
        documentExists = false;
      }

      // Prepare complete user data
      Map<String, dynamic> userData = {
        ...onboardingData,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add basic fields if document doesn't exist
      if (!documentExists) {
        userData.addAll({
          'uid': currentUser!.uid,
          'email': currentUser!.email ?? '',
          'fullName': currentUser!.displayName ?? onboardingData['name'] ?? '',
          'role': collectionName == 'employers' ? 'employer' : 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Create new document
        await _firestore
            .collection(collectionName)
            .doc(currentUser!.uid)
            .set(userData);
        print('âœ… Successfully created user document in $collectionName');
      } else {
        // Update existing document
        await _firestore
            .collection(collectionName)
            .doc(currentUser!.uid)
            .update(userData);
        print('âœ… Successfully updated user document in $collectionName');
      }
    } catch (e) {
      print('âŒ ERROR in completeUserOnboarding: ${e.toString()}');
      throw Exception('Failed to complete onboarding: ${e.toString()}');
    }
  }

  // Complete EMPLOYER onboarding specifically
  static Future<void> completeEMPLOYEROnboarding(
    Map<String, dynamic> employerOnboardingData,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? userRole = await getUserRole();
      if (userRole != 'employer') {
        throw Exception('User is not an EMPLOYER');
      }

      // Get current EMPLOYER data
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      if (!employerDoc.exists) {
        throw Exception('EMPLOYER document not found');
      }

      // Update EMPLOYER document with onboarding data
      await _firestore.collection('employers').doc(currentUser!.uid).update({
        ...employerOnboardingData,
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(
        'Failed to complete EMPLOYER onboarding: ${e.toString()}',
      );
    }
  }

  // Get EMPLOYER company information
  static Future<Map<String, dynamic>?> getEMPLOYERCompanyInfo() async {
    try {
      if (currentUser == null) return null;

      String? userRole = await getUserRole();
      if (userRole != 'employer') return null;

      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      if (employerDoc.exists) {
        Map<String, dynamic> data = employerDoc.data() as Map<String, dynamic>;
        return data['companyInfo'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get company info: ${e.toString()}');
    }
  }

  // Get EMPLOYER work information
  static Future<Map<String, dynamic>?> getEMPLOYERWorkInfo() async {
    try {
      if (currentUser == null) return null;

      String? userRole = await getUserRole();
      if (userRole != 'employer') return null;

      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      if (employerDoc.exists) {
        Map<String, dynamic> data = employerDoc.data() as Map<String, dynamic>;
        return data['employerInfo'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get work info: ${e.toString()}');
    }
  }

  // Update EMPLOYER company information
  static Future<void> updateEMPLOYERCompanyInfo(
    Map<String, dynamic> companyInfo,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? userRole = await getUserRole();
      if (userRole != 'employer') {
        throw Exception('User is not an EMPLOYER');
      }

      await _firestore.collection('employers').doc(currentUser!.uid).update({
        'companyInfo': companyInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update company info: ${e.toString()}');
    }
  }

  // Update EMPLOYER work information
  static Future<void> updateEMPLOYERWorkInfo(
    Map<String, dynamic> workInfo,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? userRole = await getUserRole();
      if (userRole != 'employer') {
        throw Exception('User is not an EMPLOYER');
      }

      await _firestore.collection('employers').doc(currentUser!.uid).update({
        'employerInfo': workInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update work info: ${e.toString()}');
    }
  }

  // Get EMPLOYERs by company (for company admin features)
  static Future<List<Map<String, dynamic>>> getEMPLOYERsByCompany(
    String companyName,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('employers')
              .where('companyInfo.companyName', isEqualTo: companyName)
              .where('isActive', isEqualTo: true)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get company EMPLOYERs: ${e.toString()}');
    }
  }

  // Create user document if it doesn't exist
  static Future<void> _createUserDocument(String defaultRole) async {
    print('\n🔨 [CREATE_USER_DOC] Starting document creation...');
    
    if (currentUser == null) {
      print('🔴 [CREATE_USER_DOC] No current user - aborting');
      return;
    }

    print('📧 [CREATE_USER_DOC] Email: ${currentUser!.email}');
    print('🆔 [CREATE_USER_DOC] UID: ${currentUser!.uid}');
    print('🎭 [CREATE_USER_DOC] Role: $defaultRole');

    Map<String, dynamic> userData = {
      'uid': currentUser!.uid,
      'email': currentUser!.email,
      'fullName': currentUser!.displayName ?? '',
      'role': defaultRole,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'onboardingCompleted': false,
    };

    print('📋 [CREATE_USER_DOC] User data to be saved:');
    userData.forEach((key, value) {
      print('   $key: $value');
    });

    String collectionName =
        defaultRole == 'employer' ? 'employers' : 'users_specific';
    print('📁 [CREATE_USER_DOC] Target collection: $collectionName');
    print('🆔 [CREATE_USER_DOC] Document ID: ${currentUser!.uid}');
    
    try {
      print('⏳ [CREATE_USER_DOC] Writing to Firestore...');
      await _firestore
          .collection(collectionName)
          .doc(currentUser!.uid)
          .set(userData);
      print('✅ [CREATE_USER_DOC] Document created successfully!');
    } catch (e) {
      print('🔴 [CREATE_USER_DOC] ERROR creating document:');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Update user role
  static Future<void> _updateUserRole(String newRole) async {
    if (currentUser == null) return;

    String? currentRole = await getUserRole();
    if (currentRole == newRole) return; // No change needed

    Map<String, dynamic> userData =
        await _getUserDataFromRoleCollection() ?? {};
    userData.addAll({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
      'onboardingCompleted': false, // Reset onboarding for role change
    });

    // Add to new role-specific collection
    String newCollection =
        newRole == 'employer' ? 'employers' : 'users_specific';
    await _firestore
        .collection(newCollection)
        .doc(currentUser!.uid)
        .set(userData);

    // Remove from old role-specific collection if it exists
    if (currentRole != null) {
      String oldCollection =
          currentRole == 'employer' ? 'employers' : 'users_specific';
      await _firestore.collection(oldCollection).doc(currentUser!.uid).delete();
    }
  }

  // Check if user is EMPLOYER
  static Future<bool> isEMPLOYER() async {
    try {
      String? role = await getUserRole();
      return role == 'employer';
    } catch (e) {
      return false;
    }
  }

  // Check if user is regular user
  static Future<bool> isUser() async {
    try {
      String? role = await getUserRole();
      return role == 'user';
    } catch (e) {
      return true; // Default to user
    }
  }

  // Reset password
  static Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code);
    } catch (e) {
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  // Check if this is user's first login
  static Future<bool> isFirstLogin() async {
    try {
      if (currentUser == null) return false;

      final role = await getUserRole();
      final collectionName = role == 'employer' ? 'employers' : 'users_specific';

      final userDoc = await _firestore
          .collection(collectionName)
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return true; // New user

      final data = userDoc.data();
      // If lastLoginDate doesn't exist or is null, it's first login
      return data?['lastLoginDate'] == null;
    } catch (e) {
      _errorLog('Error checking first login', e);
      return false; // Default to returning user on error
    }
  }

  // Update last login date
  static Future<void> updateLastLoginDate() async {
    try {
      if (currentUser == null) return;

      final role = await getUserRole();
      final collectionName = role == 'employer' ? 'employers' : 'users_specific';

      await _firestore
          .collection(collectionName)
          .doc(currentUser!.uid)
          .update({
        'lastLoginDate': FieldValue.serverTimestamp(),
      });

      _debugLog('Last login date updated successfully');
    } catch (e) {
      _errorLog('Error updating last login date', e);
      // Don't throw - this is not critical
    }
  }

  // Check if email exists (enhanced to check both Auth and Firestore)
  static Future<bool> isEmailRegistered(String email) async {
    try {
      // First check Firebase Auth
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(
        email,
      );
      if (signInMethods.isNotEmpty) {
        return true;
      }

      // Also check Firestore collections for existing email
      // This handles cases where the user might exist in Firestore but not in Auth
      final employerQuery =
          await _firestore
              .collection('employers')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (employerQuery.docs.isNotEmpty) {
        return true;
      }

      final userQuery =
          await _firestore
              .collection('users_specific')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      return userQuery.docs.isNotEmpty;
    } catch (e) {
      // If there's an error, assume email might be registered to be safe
      return false;
    }
  }

  static Future<Map<String, dynamic>> getProfileData() async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      final role = await getUserRole();
      final collectionName =
          role == 'employer' ? 'employers' : 'users_specific';

      final doc =
          await _firestore
              .collection(collectionName)
              .doc(currentUser!.uid)
              .get();

      if (!doc.exists) throw Exception('User document not found');

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get profile data: ${e.toString()}');
    }
  }

  // Get user data from role-specific collection
  static Future<Map<String, dynamic>?> getUserData() async {
    return await _getUserDataFromRoleCollection();
  }

  // Private method to get user data from the appropriate role collection
  static Future<Map<String, dynamic>?> _getUserDataFromRoleCollection() async {
    try {
      print('\n🔍 [GET_USER_DATA] Fetching user data from role-specific collection...');
      
      if (currentUser == null) {
        print('🔴 [GET_USER_DATA] No current user');
        return null;
      }

      print('🆔 [GET_USER_DATA] UID: ${currentUser!.uid}');

      // Check EMPLOYERS collection first
      print('📁 [GET_USER_DATA] Checking employers collection...');
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      if (employerDoc.exists) {
        print('✅ [GET_USER_DATA] FOUND in employers collection');
        final data = employerDoc.data() as Map<String, dynamic>?;
        print('📋 [GET_USER_DATA] Role from data: ${data?['role']}');
        return data;
      } else {
        print('❌ [GET_USER_DATA] NOT found in employers collection');
      }

      // Check users_specific collection
      print('📁 [GET_USER_DATA] Checking users_specific collection...');
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users_specific')
              .doc(currentUser!.uid)
              .get();

      if (userDoc.exists) {
        print('✅ [GET_USER_DATA] FOUND in users_specific collection');
        final data = userDoc.data() as Map<String, dynamic>?;
        print('📋 [GET_USER_DATA] Role from data: ${data?['role']}');
        return data;
      } else {
        print('❌ [GET_USER_DATA] NOT found in users_specific collection');
      }

      print('🔴 [GET_USER_DATA] User data not found in any collection');
      return null;
    } catch (e) {
      print('🔴 [GET_USER_DATA] ERROR: $e');
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Get user data from role-specific collection (alias for consistency)
  static Future<Map<String, dynamic>?> getRoleSpecificUserData() async {
    return await getUserData();
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? fullName,
    String? role,
  }) async {
    try {
      if (currentUser == null) return;

      String? currentRole = await getUserRole();
      Map<String, dynamic>? currentData = await getUserData();

      if (currentData == null) {
        throw Exception('User data not found');
      }

      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fullName != null) {
        updates['fullName'] = fullName;
        await currentUser!.updateDisplayName(fullName);
      }

      if (role != null && (role == 'employer' || role == 'user')) {
        if (role != currentRole) {
          // Role is changing, handle collection migration
          await _updateUserRole(role);
          return; // _updateUserRole handles the complete update
        } else {
          updates['role'] = role;
        }
      }

      // Update in current role-specific collection
      String collectionName =
          (currentRole ?? 'user') == 'employer'
              ? 'employers'
              : 'users_specific';
      await _firestore
          .collection(collectionName)
          .doc(currentUser!.uid)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Get all users by role (utility method for admin features)
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';
      QuerySnapshot snapshot =
          await _firestore
              .collection(collectionName)
              .where('isActive', isEqualTo: true)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: ${e.toString()}');
    }
  }

  // Deactivate user account
  static Future<void> deactivateUser() async {
    try {
      if (currentUser == null) return;

      String? role = await getUserRole();
      if (role == null) return;

      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';
      await _firestore.collection(collectionName).doc(currentUser!.uid).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      // Sign out the user after deactivation
      await signOut();
    } catch (e) {
      throw Exception('Failed to deactivate user: ${e.toString()}');
    }
  }

  // ============================================================================
  // PROFILE COMPLETION METHODS (Skip Onboarding Feature)
  // ============================================================================

  /// Mark onboarding as skipped and navigate user to home
  /// This allows users to skip the lengthy onboarding process during signup
  static Future<void> skipOnboarding() async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? role = await getUserRole();
      if (role == null) {
        throw Exception('User role not found');
      }

      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';

      await _firestore.collection(collectionName).doc(currentUser!.uid).update({
        'skippedOnboarding': true,
        'onboardingCompleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to skip onboarding: ${e.toString()}');
    }
  }

  /// Calculate profile completion percentage for current user
  /// Returns 0-100 based on filled fields
  /// Returns 100 if onboardingCompleted is true
  static Future<int> calculateProfileCompletionPercentage() async {
    try {
      if (currentUser == null) return 0;

      String? role = await getUserRole();
      if (role == null) return 0;

      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';

      final userDoc = await _firestore
          .collection(collectionName)
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return 0;

      final data = userDoc.data();
      if (data == null) return 0;

      // If onboarding is completed, return 100%
      if (data['onboardingCompleted'] == true) {
        return 100;
      }

      // Calculate based on role
      if (role == 'employer') {
        return _calculateEmployerCompletionPercentage(data);
      } else {
        return _calculateUserCompletionPercentage(data);
      }
    } catch (e) {
      debugPrint('Error calculating profile completion: $e');
      return 0;
    }
  }

  /// Calculate completion percentage for regular users
  /// Based on ACTUAL Firestore structure from student onboarding
  /// All 5 pages are REQUIRED for 100% completion (20% each)
  static int _calculateUserCompletionPercentage(Map<String, dynamic> data) {
    int completion = 0;

    debugPrint('🔍 [COMPLETION] User data keys: ${data.keys.toList()}');

    // Page 0: Personal Info (phone, gender, DOB, age) - 20%
    if (_isFieldNotEmpty(data['phone']) &&
        _isFieldNotEmpty(data['gender']) &&
        data['dateOfBirth'] != null &&
        data['age'] != null) {
      completion += 20;
      debugPrint('✅ [COMPLETION] Personal Info section complete (+20%)');
    } else {
      debugPrint('❌ [COMPLETION] Personal Info incomplete');
      if (!_isFieldNotEmpty(data['phone'])) debugPrint('   Missing: phone');
      if (!_isFieldNotEmpty(data['gender'])) debugPrint('   Missing: gender');
      if (data['dateOfBirth'] == null) debugPrint('   Missing: dateOfBirth');
      if (data['age'] == null) debugPrint('   Missing: age');
    }

    // Page 1: Address (address, city, state, zipCode, country) - 20%
    if (_isFieldNotEmpty(data['address']) &&
        _isFieldNotEmpty(data['city']) &&
        _isFieldNotEmpty(data['state']) &&
        _isFieldNotEmpty(data['zipCode'])) {
      completion += 20;
      debugPrint('✅ [COMPLETION] Address section complete (+20%)');
    } else {
      debugPrint('❌ [COMPLETION] Address incomplete');
      if (!_isFieldNotEmpty(data['address'])) debugPrint('   Missing: address');
      if (!_isFieldNotEmpty(data['city'])) debugPrint('   Missing: city');
      if (!_isFieldNotEmpty(data['state'])) debugPrint('   Missing: state');
      if (!_isFieldNotEmpty(data['zipCode'])) debugPrint('   Missing: zipCode');
    }

    // Page 2: Education (educationLevel, college, bio) - 20%
    if (_isFieldNotEmpty(data['educationLevel']) &&
        _isFieldNotEmpty(data['college'])) {
      completion += 20;
      debugPrint('✅ [COMPLETION] Education section complete (+20%)');
    } else {
      debugPrint('❌ [COMPLETION] Education incomplete');
      if (!_isFieldNotEmpty(data['educationLevel'])) debugPrint('   Missing: educationLevel');
      if (!_isFieldNotEmpty(data['college'])) debugPrint('   Missing: college');
    }

    // Page 3: Skills & Availability - 20%
    final skills = data['skills'];
    final availability = data['availability'];
    bool hasSkillsAndAvailability = false;
    
    if (skills is List && skills.isNotEmpty) {
      // Check availability - can be object or string
      if (availability != null) {
        if (availability is Map) {
          // Availability stored as object with weeklyHours and preferredSlots
          hasSkillsAndAvailability = true;
        } else if (availability is String && availability.isNotEmpty) {
          // Availability stored as string
          hasSkillsAndAvailability = true;
        }
      }
    }
    
    if (hasSkillsAndAvailability) {
      completion += 20;
      debugPrint('✅ [COMPLETION] Skills & Availability section complete (+20%)');
    } else {
      debugPrint('❌ [COMPLETION] Skills & Availability incomplete');
      if (skills == null || (skills is List && skills.isEmpty)) {
        debugPrint('   Missing: skills');
      }
      if (availability == null) debugPrint('   Missing: availability');
    }

    // Page 4: Profile Image & Resume - 20% (BOTH REQUIRED)
    bool hasProfileAndResume = _isFieldNotEmpty(data['profileImageUrl']) && 
                                _isFieldNotEmpty(data['resumeUrl']);
    
    if (hasProfileAndResume) {
      completion += 20;
      debugPrint('✅ [COMPLETION] Profile & Resume section complete (+20%)');
    } else {
      debugPrint('❌ [COMPLETION] Profile & Resume incomplete');
      if (!_isFieldNotEmpty(data['profileImageUrl'])) debugPrint('   Missing: profileImageUrl');
      if (!_isFieldNotEmpty(data['resumeUrl'])) debugPrint('   Missing: resumeUrl');
    }

    debugPrint('📊 [COMPLETION] User total: $completion%');
    return completion;
  }

  /// Calculate completion percentage for employers (5 sections = 20% each)
  /// Based on ACTUAL Firestore structure
  static int _calculateEmployerCompletionPercentage(Map<String, dynamic> data) {
    int completedSections = 0;

    debugPrint('🔍 [COMPLETION] Full employer data keys: ${data.keys.toList()}');

    // Get nested objects safely
    final companyInfo = data['companyInfo'] as Map<String, dynamic>?;
    final employerInfo = data['employerInfo'] as Map<String, dynamic>?;

    debugPrint('🔍 [COMPLETION] companyInfo exists: ${companyInfo != null}');
    if (companyInfo != null) {
      debugPrint('🔍 [COMPLETION] companyInfo keys: ${companyInfo.keys.toList()}');
    }

    debugPrint('🔍 [COMPLETION] employerInfo exists: ${employerInfo != null}');
    if (employerInfo != null) {
      debugPrint('🔍 [COMPLETION] employerInfo keys: ${employerInfo.keys.toList()}');
    }

    // Section 1: Company Basic Info (name, address, industry) - 20%
    if (companyInfo != null &&
        _isFieldNotEmpty(companyInfo['companyName']) &&
        _isFieldNotEmpty(companyInfo['companyAddress']) &&
        _isFieldNotEmpty(companyInfo['industry'])) {
      completedSections++;
      debugPrint('✅ [COMPLETION] Company Basic Info section complete');
    } else {
      debugPrint('❌ [COMPLETION] Company Basic Info incomplete');
    }

    // Section 2: Company Details (size, year, description) - 20%
    if (companyInfo != null &&
        _isFieldNotEmpty(companyInfo['companySize']) &&
        _isFieldNotEmpty(companyInfo['establishedYear']) &&
        _isFieldNotEmpty(companyInfo['companyDescription'])) {
      completedSections++;
      debugPrint('✅ [COMPLETION] Company Details section complete');
    } else {
      debugPrint('❌ [COMPLETION] Company Details incomplete');
    }

    // Section 3: Contact Information (email, phone, website) - 20%
    if (companyInfo != null &&
        _isFieldNotEmpty(companyInfo['companyEmail']) &&
        _isFieldNotEmpty(companyInfo['companyPhone'])) {
      completedSections++;
      debugPrint('✅ [COMPLETION] Contact Info section complete');
    } else {
      debugPrint('❌ [COMPLETION] Contact Info incomplete');
      if (companyInfo != null) {
        if (!_isFieldNotEmpty(companyInfo['companyEmail'])) debugPrint('   Missing: companyEmail');
        if (!_isFieldNotEmpty(companyInfo['companyPhone'])) debugPrint('   Missing: companyPhone');
      }
    }

    // Section 4: Company Logo - 20%
    if (companyInfo != null &&
        _isFieldNotEmpty(companyInfo['companyLogo'])) {
      completedSections++;
      debugPrint('✅ [COMPLETION] Company Logo section complete');
    } else {
      debugPrint('❌ [COMPLETION] Company Logo incomplete');
    }

    // Section 5: Personal Information (fullName and employerInfo if exists) - 20%
    bool hasPersonalInfo = false;
    
    if (employerInfo != null &&
        _isFieldNotEmpty(employerInfo['jobTitle']) &&
        _isFieldNotEmpty(employerInfo['department'])) {
      // Has detailed employer info
      hasPersonalInfo = true;
      debugPrint('✅ [COMPLETION] Personal Info section complete (employerInfo)');
    } else if (_isFieldNotEmpty(data['fullName']) &&
               _isFieldNotEmpty(data['email'])) {
      // Has basic personal info at root level
      hasPersonalInfo = true;
      debugPrint('✅ [COMPLETION] Personal Info section complete (basic)');
    } else {
      debugPrint('❌ [COMPLETION] Personal Info incomplete');
    }
    
    if (hasPersonalInfo) {
      completedSections++;
    }

    // Calculate percentage (20%, 40%, 60%, 80%, or 100%)
    final percentage = completedSections * 20;
    
    debugPrint('📊 [COMPLETION] Employer: $completedSections/5 sections = $percentage%');
    return percentage;
  }

  /// Helper to check if a field value is not empty
  static bool _isFieldNotEmpty(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return true;
  }

  /// Get count of jobs posted by current employer
  /// Used for analytics access check
  static Future<int> getEmployerJobCount() async {
    try {
      if (currentUser == null) return 0;

      // Get employer's company name
      final employerData = await getEMPLOYERCompanyInfo();
      if (employerData == null || employerData['companyName'] == null) {
        return 0;
      }

      final companyName = employerData['companyName'];

      // Query jobs collection for this company
      final jobsSnapshot = await _firestore
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .get();

      return jobsSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting employer job count: $e');
      return 0;
    }
  }

  /// Update profile completion status in Firestore
  /// Call this after user saves any profile data
  /// Waits 1 second before updating to avoid rapid successive calls
  static Future<void> updateProfileCompletionStatus() async {
    try {
      // Wait 1 second as per requirement
      await Future.delayed(const Duration(seconds: 1));

      if (currentUser == null) {
        debugPrint('⚠️ [PROFILE_COMPLETION] No user logged in');
        return;
      }

      final role = await getUserRole();
      if (role == null) {
        debugPrint('⚠️ [PROFILE_COMPLETION] No role found');
        return;
      }

      final collectionName = role == 'employer' ? 'employers' : 'users_specific';
      
      // Get current data
      final userDoc = await _firestore
          .collection(collectionName)
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('⚠️ [PROFILE_COMPLETION] User document not found');
        return;
      }

      final data = userDoc.data();
      if (data == null) return;

      // Check if already marked as complete - if so, don't recalculate
      if (data['onboardingCompleted'] == true) {
        debugPrint('✅ [PROFILE_COMPLETION] Already 100% complete, skipping update');
        return;
      }

      // Calculate new percentage
      final percentage = role == 'employer'
          ? _calculateEmployerCompletionPercentage(data)
          : _calculateUserCompletionPercentage(data);

      debugPrint('📊 [PROFILE_COMPLETION] Calculated: $percentage%');

      // Determine if profile is now complete
      final isComplete = percentage >= 100;

      // Update Firestore
      await _firestore.collection(collectionName).doc(currentUser!.uid).update({
        'profileCompletionPercentage': percentage,
        'onboardingCompleted': isComplete,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [PROFILE_COMPLETION] Updated: $percentage% (Complete: $isComplete)');
    } catch (e) {
      debugPrint('❌ [PROFILE_COMPLETION] Error: $e');
    }
  }

  // Debug method to check user existence in all collections
  static Future<void> debugCheckUserInAllCollections() async {
    if (currentUser == null) {
      print('🔴 [CHECK_USER] No current user');
      return;
    }

    final uid = currentUser!.uid;
    final email = currentUser!.email;
    print('═══════════════════════════════════════════════════════');
    print('🔍 [CHECK_USER] FULL USER DATA CHECK');
    print('═══════════════════════════════════════════════════════');
    print('📧 Email: $email');
    print('🆔 UID: $uid');
    print('👤 Display Name: ${currentUser!.displayName}');
    print('📱 Phone: ${currentUser!.phoneNumber}');
    print('📸 Photo URL: ${currentUser!.photoURL}');
    print('✅ Email Verified: ${currentUser!.emailVerified}');
    print('───────────────────────────────────────────────────────');

    // Check employers collection with timeout
    print('\n📁 Checking EMPLOYERS collection...');
    try {
      final employerDoc = await _firestore
          .collection('employers')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      
      if (employerDoc.exists) {
        print('✅ FOUND in employers collection');
        final data = employerDoc.data();
        print('   📋 Full Data:');
        data?.forEach((key, value) {
          print('      $key: $value');
        });
      } else {
        print('❌ NOT FOUND in employers collection');
      }
    } catch (e) {
      print('⚠️ ERROR checking employers: $e');
    }

    // Check users_specific collection with timeout
    print('\n📁 Checking USERS_SPECIFIC collection...');
    try {
      final userDoc = await _firestore
          .collection('users_specific')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      
      if (userDoc.exists) {
        print('✅ FOUND in users_specific collection');
        final data = userDoc.data();
        print('   📋 Full Data:');
        data?.forEach((key, value) {
          print('      $key: $value');
        });
      } else {
        print('❌ NOT FOUND in users_specific collection');
      }
    } catch (e) {
      print('⚠️ ERROR checking users_specific: $e');
    }

    // Check old employees collection with timeout
    print('\n📁 Checking EMPLOYEES collection (legacy)...');
    try {
      final employeeDoc = await _firestore
          .collection('employees')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      
      if (employeeDoc.exists) {
        print('✅ FOUND in employees collection');
        final data = employeeDoc.data();
        print('   📋 Full Data:');
        data?.forEach((key, value) {
          print('      $key: $value');
        });
      } else {
        print('❌ NOT FOUND in employees collection');
      }
    } catch (e) {
      print('⚠️ ERROR checking employees: $e');
    }

    // Check old users collection with timeout
    print('\n📁 Checking USERS collection (legacy)...');
    try {
      final oldUserDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      
      if (oldUserDoc.exists) {
        print('✅ FOUND in users collection');
        final data = oldUserDoc.data();
        print('   📋 Full Data:');
        data?.forEach((key, value) {
          print('      $key: $value');
        });
      } else {
        print('❌ NOT FOUND in users collection');
      }
    } catch (e) {
      print('⚠️ ERROR checking users: $e');
    }

    print('\n═══════════════════════════════════════════════════════');
    print('✅ [CHECK_USER] Collection check completed');
    print('═══════════════════════════════════════════════════════\n');
  }
}
