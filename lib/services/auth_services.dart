import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool get isLoggedIn => _auth.currentUser != null;

  static Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    Function(PhoneAuthCredential credential)? onVerificationCompleted,
    Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    try {
      // Format phone number properly
      String formattedPhone =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      if (kDebugMode) {
        print('AuthService: Sending OTP to $formattedPhone');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) {
            print('AuthService: Verification completed automatically');
          }
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          } else {
            await signInWithCredential(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            print('AuthService: Verification failed - ${e.code}: ${e.message}');
          }
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) {
            print(
              'AuthService: Code sent successfully. Verification ID: $verificationId',
            );
          }
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) {
            print(
              'AuthService: Auto retrieval timeout for verification ID: $verificationId',
            );
          }
          if (onCodeAutoRetrievalTimeout != null) {
            onCodeAutoRetrievalTimeout(verificationId);
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error in sendOTP - $e');
      }
      rethrow;
    }
  }

  static Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'AuthService: Verifying OTP - Code: $smsCode, Verification ID: $verificationId',
        );
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final result = await signInWithCredential(credential);

      if (kDebugMode) {
        print('AuthService: OTP verification successful');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error in verifyOTP - $e');
      }
      rethrow;
    }
  }

  // Sign in with credential
  static Future<UserCredential> signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      if (kDebugMode) {
        print('AuthService: Signing in with credential');
      }

      final result = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print(
          'AuthService: Sign in successful - User: ${result.user?.phoneNumber}',
        );
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error in signInWithCredential - $e');
      }
      rethrow;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (kDebugMode) {
          print('AuthService: Updating user profile - Name: $displayName');
        }

        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        // Reload user to get updated info
        await user.reload();

        if (kDebugMode) {
          print('AuthService: Profile updated successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error updating profile - $e');
      }
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('AuthService: Signing out user');
      }

      await _auth.signOut();

      if (kDebugMode) {
        print('AuthService: Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error in signOut - $e');
      }
      rethrow;
    }
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (kDebugMode) {
          print('AuthService: Deleting user account');
        }

        await user.delete();

        if (kDebugMode) {
          print('AuthService: Account deleted successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error deleting account - $e');
      }
      rethrow;
    }
  }

  // Get user phone number
  static String? get userPhoneNumber => _auth.currentUser?.phoneNumber;

  // Get user display name
  static String? get userDisplayName => _auth.currentUser?.displayName;

  // Get user UID
  static String? get userUID => _auth.currentUser?.uid;

  // Check if phone number is valid
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid 10-digit Indian number
    return cleanNumber.length == 10 &&
        RegExp(r'^[6-9]\d{9}$').hasMatch(cleanNumber);
  }
}
