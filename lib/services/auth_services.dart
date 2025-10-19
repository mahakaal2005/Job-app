import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'employer' or 'user'
  }) async {
    try {
      // Check if email is already registered before creating account
      bool isRegistered = await isEmailRegistered(email);
      if (isRegistered) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account already exists for this email address.',
        );
      }

      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Prepare user data
      Map<String, dynamic> userData = {
        'uid': userCredential.user?.uid,
        'email': email,
        'fullName': fullName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'onboardingCompleted': false, // Both roles need onboarding now
        'profileCompleted': false, // NEW - tracks if profile is fully filled
        'profileCompletionPercentage': 0, // NEW - 0-100 percentage
        'skippedOnboarding': false, // NEW - tracks if they skipped
      };

      // Save to role-specific collection only
      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';
      await _firestore
          .collection(collectionName)
          .doc(userCredential.user?.uid)
          .set(userData);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code);
    } catch (e) {
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
        'profileCompleted': false, // NEW - tracks if profile is fully filled
        'profileCompletionPercentage': 0, // NEW - 0-100 percentage
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
      print(
        'DEBUG [MIGRATION] Checking for user in old employees collection: $uid',
      );

      // Check if user exists in old 'employees' collection
      DocumentSnapshot oldEmployeeDoc =
          await _firestore.collection('employees').doc(uid).get();

      if (!oldEmployeeDoc.exists) {
        print('DEBUG [MIGRATION] User not found in old employees collection');
        return false;
      }

      print(
        'DEBUG [MIGRATION] Found user in old employees collection, migrating...',
      );

      // Get the data
      Map<String, dynamic> userData =
          oldEmployeeDoc.data() as Map<String, dynamic>;

      // Add migration timestamp
      userData['migratedAt'] = FieldValue.serverTimestamp();
      userData['migratedFrom'] = 'employees';

      // Copy to new 'employers' collection
      await _firestore.collection('employers').doc(uid).set(userData);
      print('DEBUG [MIGRATION] Data copied to employers collection');

      // Mark old document as migrated
      await _firestore.collection('employees').doc(uid).update({
        'migrated': true,
        'migratedAt': FieldValue.serverTimestamp(),
        'migratedTo': 'employers',
      });
      print('DEBUG [MIGRATION] Old document marked as migrated');

      return true;
    } catch (e) {
      print('DEBUG [MIGRATION] Error during migration: $e');
      return false;
    }
  }

  // Get user role with better error handling and migration support
  static Future<String?> getUserRole() async {
    try {
      print('DEBUG [GET_ROLE] Starting getUserRole');

      if (currentUser == null) {
        print('DEBUG [GET_ROLE] No current user');
        return null;
      }

      print('DEBUG [GET_ROLE] Getting role for user: ${currentUser!.uid}');

      // Check employers collection first
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      if (employerDoc.exists) {
        print(
          'DEBUG [GET_ROLE] Found in employers collection - role: employer',
        );
        return 'employer';
      }

      print(
        'DEBUG [GET_ROLE] Not found in employers collection, checking old employees collection...',
      );

      // Try to migrate from old 'employees' collection
      bool migrated = await _migrateEmployeeToEmployer(currentUser!.uid);
      if (migrated) {
        print('DEBUG [GET_ROLE] Migration successful - role: employer');
        return 'employer';
      }

      // Check users_specific collection
      print('DEBUG [GET_ROLE] Checking users_specific collection...');
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users_specific')
              .doc(currentUser!.uid)
              .get();

      if (userDoc.exists) {
        print(
          'DEBUG [GET_ROLE] Found in users_specific collection - role: user',
        );
        return 'user';
      }

      // User document doesn't exist in any collection
      print(
        'DEBUG [GET_ROLE] No user document found in any collection for ${currentUser!.uid}',
      );
      return null;
    } catch (e) {
      print('DEBUG [GET_ROLE] Error: $e');
      throw Exception('Failed to get user role: ${e.toString()}');
    }
  }

  static Future<String?> getCurrentUserId() async {
    try {
      if (currentUser == null) return null;

      // Check EMPLOYERs collection first
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      if (employerDoc.exists) {
        return 'employer';
      }

      // Check users_specific collection
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users_specific')
              .doc(currentUser!.uid)
              .get();

      if (userDoc.exists) {
        return 'user';
      }

      // User document doesn't exist in either collection
      // Don't create a default - return null to indicate no role found
      print('âš ï¸ WARNING: No user document found for ${currentUser!.uid}');
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: ${e.toString()}');
    }
  }

  // static Future<String?> getCurrentUserId() async {
  //   try {
  //     if (currentUser == null) return null;
  //     return currentUser!.uid;
  //   } catch (e) {
  //     throw Exception('Failed to get current user ID: ${e.toString()}');
  //   }
  // }

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
    if (currentUser == null) return;

    Map<String, dynamic> userData = {
      'uid': currentUser!.uid,
      'email': currentUser!.email,
      'fullName': currentUser!.displayName ?? '',
      'role': defaultRole,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'onboardingCompleted': false,
    };

    String collectionName =
        defaultRole == 'employer' ? 'employers' : 'users_specific';
    await _firestore
        .collection(collectionName)
        .doc(currentUser!.uid)
        .set(userData);
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
      if (currentUser == null) return null;

      // Check EMPLOYERs collection first
      DocumentSnapshot employerDoc =
          await _firestore.collection('employers').doc(currentUser!.uid).get();

      if (employerDoc.exists) {
        return employerDoc.data() as Map<String, dynamic>?;
      }

      // Check users_specific collection
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users_specific')
              .doc(currentUser!.uid)
              .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
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
        'profileCompleted': false,
        'profileCompletionPercentage': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to skip onboarding: ${e.toString()}');
    }
  }

  /// Get profile completion status including percentage and flags
  /// Returns a map with profileCompleted, completionPercentage, and skippedOnboarding
  static Future<Map<String, dynamic>> getProfileCompletionStatus() async {
    try {
      if (currentUser == null) {
        return {
          'profileCompleted': false,
          'completionPercentage': 0,
          'skippedOnboarding': false,
        };
      }

      String? role = await getUserRole();
      if (role == null) {
        return {
          'profileCompleted': false,
          'completionPercentage': 0,
          'skippedOnboarding': false,
        };
      }

      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';

      DocumentSnapshot doc =
          await _firestore
              .collection(collectionName)
              .doc(currentUser!.uid)
              .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Calculate completion percentage if not already set
        int percentage = data['profileCompletionPercentage'] ?? 0;
        if (percentage == 0) {
          percentage = await calculateProfileCompletion();
        }

        return {
          'profileCompleted': data['profileCompleted'] ?? false,
          'completionPercentage': percentage,
          'skippedOnboarding': data['skippedOnboarding'] ?? false,
          'onboardingCompleted': data['onboardingCompleted'] ?? false,
        };
      }

      return {
        'profileCompleted': false,
        'completionPercentage': 0,
        'skippedOnboarding': false,
      };
    } catch (e) {
      throw Exception(
        'Failed to get profile completion status: ${e.toString()}',
      );
    }
  }

  /// Calculate profile completion percentage based on filled fields
  /// Returns 0-100 percentage
  static Future<int> calculateProfileCompletion() async {
    try {
      if (currentUser == null) return 0;

      String? role = await getUserRole();
      if (role == null) return 0;

      String collectionName =
          role == 'employer' ? 'employers' : 'users_specific';

      DocumentSnapshot doc =
          await _firestore
              .collection(collectionName)
              .doc(currentUser!.uid)
              .get();

      if (!doc.exists) return 0;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (role == 'employer') {
        // EMPLOYER profile has 3 main sections
        int completedSections = 0;
        int totalSections = 3;

        // Section 1: Company Info
        if (data['companyInfo'] != null) {
          Map<String, dynamic> companyInfo =
              data['companyInfo'] as Map<String, dynamic>;
          if (companyInfo['companyName'] != null &&
              companyInfo['companyEmail'] != null &&
              companyInfo['companyPhone'] != null) {
            completedSections++;
          }
        }

        // Section 2: EMPLOYER Info
        if (data['employerInfo'] != null) {
          Map<String, dynamic> employerInfo =
              data['employerInfo'] as Map<String, dynamic>;
          if (employerInfo['jobTitle'] != null &&
              employerInfo['department'] != null &&
              employerInfo['EMPLOYERId'] != null) {
            completedSections++;
          }
        }

        // Section 3: Documents
        if (data['companyInfo'] != null) {
          Map<String, dynamic> companyInfo =
              data['companyInfo'] as Map<String, dynamic>;
          if (companyInfo['companyLogo'] != null &&
              companyInfo['businessLicense'] != null) {
            completedSections++;
          }
        }

        int percentage = ((completedSections / totalSections) * 100).round();

        // Update the percentage in Firestore
        await _firestore
            .collection(collectionName)
            .doc(currentUser!.uid)
            .update({
              'profileCompletionPercentage': percentage,
              'profileCompleted': percentage == 100,
            });

        return percentage;
      } else {
        // User/Student profile has 5 main sections
        int completedSections = 0;
        int totalSections = 5;

        // Section 1: Personal Info (phone, gender, dateOfBirth)
        if (data['phone'] != null &&
            data['gender'] != null &&
            data['dateOfBirth'] != null) {
          completedSections++;
        }

        // Section 2: Address (address, city, state, zipCode)
        if (data['address'] != null &&
            data['city'] != null &&
            data['state'] != null &&
            data['zipCode'] != null) {
          completedSections++;
        }

        // Section 3: Education (educationLevel, college)
        if (data['educationLevel'] != null && data['college'] != null) {
          completedSections++;
        }

        // Section 4: Skills & Availability
        if (data['skills'] != null &&
            (data['skills'] as List).isNotEmpty &&
            data['availability'] != null) {
          completedSections++;
        }

        // Section 5: Resume
        if (data['resumeUrl'] != null) {
          completedSections++;
        }

        int percentage = ((completedSections / totalSections) * 100).round();

        // Update the percentage in Firestore
        await _firestore
            .collection(collectionName)
            .doc(currentUser!.uid)
            .update({
              'profileCompletionPercentage': percentage,
              'profileCompleted': percentage == 100,
            });

        return percentage;
      }
    } catch (e) {
      throw Exception(
        'Failed to calculate profile completion: ${e.toString()}',
      );
    }
  }

  /// Update profile completion percentage manually
  /// Useful when profile is updated from various screens
  static Future<void> updateProfileCompletionPercentage() async {
    try {
      await calculateProfileCompletion();
    } catch (e) {
      throw Exception('Failed to update profile completion: ${e.toString()}');
    }
  }
}
