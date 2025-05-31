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
        'onboardingCompleted': false, // Both roles need onboarding now
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
      // Check in employees collection first
      DocumentSnapshot employeeDoc =
          await _firestore.collection('employees').doc(uid).get();

      if (employeeDoc.exists) {
        Map<String, dynamic> employeeData = employeeDoc.data() as Map<String, dynamic>;
        return employeeData['onboardingCompleted'] ?? false;
      }

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

  // Check if current user has completed onboarding
  static Future<bool> hasCurrentUserCompletedOnboarding() async {
    if (currentUser == null) return false;
    return await hasUserCompletedOnboarding(currentUser!.uid);
  }

  // Complete user onboarding (works for both employees and users)
  static Future<void> completeUserOnboarding(
    Map<String, dynamic> onboardingData,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? userRole = await getUserRole();
      if (userRole == null) {
        throw Exception('User role not found');
      }

      String collectionName = userRole == 'employee' ? 'employees' : 'users_specific';

      // Get current user data
      DocumentSnapshot userDoc =
          await _firestore.collection(collectionName).doc(currentUser!.uid).get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Update user document with onboarding data
      await _firestore
          .collection(collectionName)
          .doc(currentUser!.uid)
          .update({
            ...onboardingData,
            'onboardingCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to complete onboarding: ${e.toString()}');
    }
  }

  // Complete employee onboarding specifically
  static Future<void> completeEmployeeOnboarding(
    Map<String, dynamic> employeeOnboardingData,
  ) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? userRole = await getUserRole();
      if (userRole != 'employee') {
        throw Exception('User is not an employee');
      }

      // Get current employee data
      DocumentSnapshot employeeDoc =
          await _firestore.collection('employees').doc(currentUser!.uid).get();

      if (!employeeDoc.exists) {
        throw Exception('Employee document not found');
      }

      // Update employee document with onboarding data
      await _firestore
          .collection('employees')
          .doc(currentUser!.uid)
          .update({
            ...employeeOnboardingData,
            'onboardingCompleted': true,
            'onboardingCompletedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to complete employee onboarding: ${e.toString()}');
    }
  }

  // Get employee company information
  static Future<Map<String, dynamic>?> getEmployeeCompanyInfo() async {
    try {
      if (currentUser == null) return null;

      String? userRole = await getUserRole();
      if (userRole != 'employee') return null;

      DocumentSnapshot employeeDoc =
          await _firestore.collection('employees').doc(currentUser!.uid).get();

      if (employeeDoc.exists) {
        Map<String, dynamic> data = employeeDoc.data() as Map<String, dynamic>;
        return data['companyInfo'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get company info: ${e.toString()}');
    }
  }

  // Get employee work information
  static Future<Map<String, dynamic>?> getEmployeeWorkInfo() async {
    try {
      if (currentUser == null) return null;

      String? userRole = await getUserRole();
      if (userRole != 'employee') return null;

      DocumentSnapshot employeeDoc =
          await _firestore.collection('employees').doc(currentUser!.uid).get();

      if (employeeDoc.exists) {
        Map<String, dynamic> data = employeeDoc.data() as Map<String, dynamic>;
        return data['employeeInfo'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get work info: ${e.toString()}');
    }
  }

  // Update employee company information
  static Future<void> updateEmployeeCompanyInfo(Map<String, dynamic> companyInfo) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? userRole = await getUserRole();
      if (userRole != 'employee') {
        throw Exception('User is not an employee');
      }

      await _firestore
          .collection('employees')
          .doc(currentUser!.uid)
          .update({
            'companyInfo': companyInfo,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update company info: ${e.toString()}');
    }
  }

  // Update employee work information
  static Future<void> updateEmployeeWorkInfo(Map<String, dynamic> workInfo) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      String? userRole = await getUserRole();
      if (userRole != 'employee') {
        throw Exception('User is not an employee');
      }

      await _firestore
          .collection('employees')
          .doc(currentUser!.uid)
          .update({
            'employeeInfo': workInfo,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update work info: ${e.toString()}');
    }
  }

  // Get employees by company (for company admin features)
  static Future<List<Map<String, dynamic>>> getEmployeesByCompany(String companyName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('employees')
          .where('companyInfo.companyName', isEqualTo: companyName)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get company employees: ${e.toString()}');
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
      'onboardingCompleted': false, // Reset onboarding for role change
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