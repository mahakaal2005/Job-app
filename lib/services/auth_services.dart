import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'employee' or 'user'
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
        'onboardingCompleted':
            role == 'employee', // Employees don't need onboarding
      };

      // Save to role-specific collection only
      String collectionName =
          role == 'employee' ? 'employees' : 'users_specific';
      await _firestore
          .collection(collectionName)
          .doc(userCredential.user?.uid)
          .set(userData);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
      );
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
      throw FirebaseAuthException(
        code: e.code,
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Get user role with better error handling
  static Future<String?> getUserRole() async {
    try {
      if (currentUser == null) return null;

      // Check employees collection first
      DocumentSnapshot employeeDoc =
          await _firestore.collection('employees').doc(currentUser!.uid).get();

      if (employeeDoc.exists) {
        return 'employee';
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

      // User document doesn't exist in either collection, create one with default role
      await _createUserDocument('user');
      return 'user';
    } catch (e) {
      throw Exception('Failed to get user role: ${e.toString()}');
    }
  }

  // Alias for getUserRole() for consistency
  static Future<String?> getCurrentUserRole() async {
    return await getUserRole();
  }

  // Check if user has completed onboarding
  static Future<bool> hasUserCompletedOnboarding(String uid) async {
    try {
      // Check in users_specific collection
      DocumentSnapshot userDoc =
          await _firestore.collection('users_specific').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['onboardingCompleted'] ?? false;
      }

      return false;
    } catch (e) {
      // If there's an error, assume onboarding is not completed
      return false;
    }
  }

  // Complete user onboarding
  static Future<void> completeUserOnboarding(
    Map<String, dynamic> onboardingData,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      // Get current user data
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users_specific')
              .doc(currentUser!.uid)
              .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Update user document with onboarding data
      await _firestore
          .collection('users_specific')
          .doc(currentUser!.uid)
          .update({
            ...onboardingData,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to complete onboarding: ${e.toString()}');
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
      'onboardingCompleted': defaultRole == 'employee',
    };

    String collectionName =
        defaultRole == 'employee' ? 'employees' : 'users_specific';
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
      'onboardingCompleted': newRole == 'employee',
    });

    // Add to new role-specific collection
    String newCollection =
        newRole == 'employee' ? 'employees' : 'users_specific';
    await _firestore
        .collection(newCollection)
        .doc(currentUser!.uid)
        .set(userData);

    // Remove from old role-specific collection if it exists
    if (currentRole != null) {
      String oldCollection =
          currentRole == 'employee' ? 'employees' : 'users_specific';
      await _firestore.collection(oldCollection).doc(currentUser!.uid).delete();
    }
  }

  // Check if user is employee
  static Future<bool> isEmployee() async {
    try {
      String? role = await getUserRole();
      return role == 'employee';
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

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Reset password
  static Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        
      );
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
      final employeeQuery =
          await _firestore
              .collection('employees')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (employeeQuery.docs.isNotEmpty) {
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

  // Get user data from role-specific collection
  static Future<Map<String, dynamic>?> getUserData() async {
    return await _getUserDataFromRoleCollection();
  }

  // Private method to get user data from the appropriate role collection
  static Future<Map<String, dynamic>?> _getUserDataFromRoleCollection() async {
    try {
      if (currentUser == null) return null;

      // Check employees collection first
      DocumentSnapshot employeeDoc =
          await _firestore.collection('employees').doc(currentUser!.uid).get();

      if (employeeDoc.exists) {
        return employeeDoc.data() as Map<String, dynamic>?;
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

      if (role != null && (role == 'employee' || role == 'user')) {
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
          (currentRole ?? 'user') == 'employee'
              ? 'employees'
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
          role == 'employee' ? 'employees' : 'users_specific';
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
  // Deactivate user account
  static Future<void> deactivateUser() async {
    try {
      if (currentUser == null) return;

      String? role = await getUserRole();
      if (role == null) return;

      String collectionName =
          role == 'employee' ? 'employees' : 'users_specific';
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
}
