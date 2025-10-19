import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/routes/routes.dart';

/// Service to gate critical actions behind profile completion
/// Users must complete their profile before performing important actions
class ProfileGatingService {
  /// Check if user can perform a critical action
  /// Returns true if profile is complete, false otherwise
  /// If showDialog is true, shows a dialog prompting user to complete profile
  static Future<bool> canPerformAction(
    BuildContext context, {
    required String actionName,
    bool showDialog = true,
  }) async {
    try {
      // Get profile completion status
      final status = await AuthService.getProfileCompletionStatus();
      final int percentage = status['completionPercentage'] ?? 100;
      final bool isComplete = percentage >= 100;

      // If profile is complete, allow action
      if (isComplete) {
        return true;
      }

      // If profile is incomplete and dialog should be shown
      if (showDialog && context.mounted) {
        final result = await showProfileCompletionDialog(
          context,
          actionName,
          percentage,
        );

        // If user chose to complete profile
        if (result == true && context.mounted) {
          await navigateToOnboarding(context);
          
          // After returning from onboarding, check again
          if (context.mounted) {
            final newStatus = await AuthService.getProfileCompletionStatus();
            final newPercentage = newStatus['completionPercentage'] ?? 0;
            return newPercentage >= 100;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      // On error, allow action to proceed (fail open)
      return true;
    }
  }

  /// Show dialog prompting user to complete profile
  /// Returns true if user wants to complete now, false if maybe later
  static Future<bool?> showProfileCompletionDialog(
    BuildContext context,
    String actionName,
    int completionPercentage,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lookGigPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: AppColors.lookGigPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getMessageForAction(actionName),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 20),
            // Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile Completion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lookGigPurple,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.lookGigPurple,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontFamily: 'DM Sans',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lookGigPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Complete Now',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'DM Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to appropriate onboarding screen based on user role
  static Future<void> navigateToOnboarding(BuildContext context) async {
    try {
      final role = await AuthService.getUserRole();
      final route = role == 'employer'
          ? AppRoutes.employerOnboarding
          : AppRoutes.studentOnboarding;

      if (context.mounted) {
        await Navigator.pushNamed(context, route);
      }
    } catch (e) {
      debugPrint('Error navigating to onboarding: $e');
    }
  }

  /// Get appropriate message based on action
  static String _getMessageForAction(String actionName) {
    switch (actionName.toLowerCase()) {
      case 'apply for jobs':
      case 'apply for this job':
        return 'To apply for jobs, you need to complete your profile first. '
            'This helps employers know more about you and increases your chances of getting hired.';

      case 'post jobs':
      case 'post a job':
      case 'create job':
        return 'To post jobs, you need to complete your company profile first. '
            'This helps candidates learn about your company and attracts better applicants.';

      case 'message employers':
      case 'send message':
        return 'To message employers, you need to complete your profile first. '
            'A complete profile helps build trust and improves communication.';

      case 'message candidates':
      case 'contact applicants':
        return 'To message candidates, you need to complete your company profile first. '
            'This helps candidates trust your company and respond to your messages.';

      case 'view applicant details':
      case 'view applicants':
        return 'To view applicant details, you need to complete your company profile first. '
            'A complete profile ensures professional interactions with candidates.';

      case 'edit job':
      case 'update job':
        return 'To edit jobs, you need to complete your company profile first. '
            'This ensures all your job postings have complete company information.';

      default:
        return 'To perform this action, you need to complete your profile first. '
            'A complete profile ensures the best experience on our platform.';
    }
  }

  /// Quick check without showing dialog (for UI state management)
  static Future<bool> isProfileComplete() async {
    try {
      final status = await AuthService.getProfileCompletionStatus();
      final int percentage = status['completionPercentage'] ?? 100;
      return percentage >= 100;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return true; // Fail open
    }
  }
}
