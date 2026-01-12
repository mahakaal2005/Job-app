import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class ErrorHandler {
  // Enable debug mode to show technical error details
  static const bool _debugMode = kDebugMode;
  
  // Convert technical errors to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // In debug mode, log the actual error
    if (_debugMode) {
      debugPrint('[ERROR_HANDLER][DEBUG] Details: $error');
      debugPrint('[ERROR_HANDLER][DEBUG] Type: ${error.runtimeType}');
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('access')) {
      return 'Permission required. Please grant the necessary permissions in your device settings.';
    }

    // Storage/File errors
    if (errorString.contains('storage') ||
        errorString.contains('file') ||
        errorString.contains('read') ||
        errorString.contains('write')) {
      return 'Unable to access file. Please check storage permissions and try again.';
    }

    // Google Sign-In errors
    if (errorString.contains('google') && errorString.contains('sign')) {
      if (errorString.contains('cancel')) {
        return 'Sign-in cancelled. Please try again.';
      }
      return 'Unable to sign in with Google. Please check your internet connection and try again.';
    }

    // Firebase Auth errors
    if (errorString.contains('email-already-in-use')) {
      return 'This email is already registered. Please login instead.';
    }
    if (errorString.contains('invalid-email')) {
      return 'Invalid email address. Please check and try again.';
    }
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    // Firestore errors
    if (errorString.contains('firestore') || errorString.contains('firebase')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    // Image/Media errors
    if (errorString.contains('image') || errorString.contains('photo')) {
      return 'Unable to process image. Please try selecting a different image.';
    }

    // Default message
    return 'Something went wrong. Please try again.';
  }

  // Show error dialog with user-friendly message
  static void showErrorDialog(BuildContext context, dynamic error,
      {String? title}) {
    final message = getUserFriendlyMessage(error);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title ?? 'Error',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.gigAppPurple,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF524B6B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gigAppPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show error snackbar with user-friendly message
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getUserFriendlyMessage(error);
    
    // In debug mode, show technical details in a separate snackbar
    if (_debugMode) {
      final technicalError = error.toString();
      Future.delayed(const Duration(milliseconds: 100), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEBUG INFO:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  technicalError,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show permission required dialog with action to open settings
  static void showPermissionDialog(
    BuildContext context, {
    required String permission,
    required VoidCallback onOpenSettings,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Permission Required',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.gigAppPurple,
          ),
        ),
        content: Text(
          'This app needs $permission permission to work properly. Please grant the permission in your device settings.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF524B6B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gigAppPurple,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show network error dialog with retry option
  static void showNetworkErrorDialog(
    BuildContext context, {
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'No Internet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.gigAppPurple,
              ),
            ),
          ],
        ),
        content: const Text(
          'Please check your internet connection and try again.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF524B6B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gigAppPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
