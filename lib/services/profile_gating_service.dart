import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';

/// Profile gating service that checks profile completion before allowing critical actions
class ProfileGatingService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user's profile is complete (onboardingCompleted flag)
  static Future<bool> isProfileComplete() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // CRITICAL: Get role from AuthService to check correct collection
      final role = await AuthService.getUserRole();
      if (role == null) return false;

      final collectionName = role == 'employer' ? 'employers' : 'users_specific';
      final userDoc = await _firestore.collection(collectionName).doc(user.uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data();
      return data?['onboardingCompleted'] == true;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  /// Get profile completion percentage (0-100)
  static Future<int> getCompletionPercentage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // CRITICAL: Get role from AuthService to check correct collection
      final role = await AuthService.getUserRole();
      if (role == null) return 0;

      final collectionName = role == 'employer' ? 'employers' : 'users_specific';
      final userDoc = await _firestore.collection(collectionName).doc(user.uid).get();
      if (!userDoc.exists) return 0;

      final data = userDoc.data();
      
      // If onboarding is completed, return 100%
      if (data?['onboardingCompleted'] == true) {
        return 100;
      }

      // Calculate based on role
      if (role == 'employer') {
        return _calculateEmployerCompletion(data ?? {});
      } else {
        return _calculateUserCompletion(data ?? {});
      }
    } catch (e) {
      debugPrint('Error calculating completion percentage: $e');
      return 0;
    }
  }

  /// Calculate completion percentage for regular users (5 sections = 20% each)
  static int _calculateUserCompletion(Map<String, dynamic> data) {
    int completedSections = 0;

    // Section 1: Personal Info (name, phone, age, gender, DOB) - 20%
    if (_isNotEmpty(data['fullName']) &&
        _isNotEmpty(data['phone']) &&
        _isNotEmpty(data['age']) &&
        _isNotEmpty(data['gender']) &&
        data['dateOfBirth'] != null) {
      completedSections++;
    }

    // Section 2: Address (address, city, state, zip) - 20%
    if (_isNotEmpty(data['address']) &&
        _isNotEmpty(data['city']) &&
        _isNotEmpty(data['state']) &&
        _isNotEmpty(data['zipCode'])) {
      completedSections++;
    }

    // Section 3: Education (level, college) - 20%
    if (_isNotEmpty(data['educationLevel']) &&
        _isNotEmpty(data['college'])) {
      completedSections++;
    }

    // Section 4: Skills & Availability - 20%
    final skills = data['skills'];
    if (skills is List && skills.isNotEmpty &&
        _isNotEmpty(data['availability'])) {
      completedSections++;
    }

    // Section 5: Resume upload - 20%
    if (_isNotEmpty(data['resumeUrl'])) {
      completedSections++;
    }

    return (completedSections * 20);
  }

  /// Calculate completion percentage for employers (3 sections)
  static int _calculateEmployerCompletion(Map<String, dynamic> data) {
    int completedSections = 0;

    // Section 1: Company Info (name, email, phone, address) - 33%
    if (_isNotEmpty(data['companyName']) &&
        _isNotEmpty(data['companyEmail']) &&
        _isNotEmpty(data['companyPhone']) &&
        _isNotEmpty(data['address'])) {
      completedSections++;
    }

    // Section 2: Employer Info (job title, department, ID) - 33%
    if (_isNotEmpty(data['jobTitle']) &&
        _isNotEmpty(data['department']) &&
        _isNotEmpty(data['employerId'])) {
      completedSections++;
    }

    // Section 3: Documents (logo, license, ID card) - 34%
    if (_isNotEmpty(data['companyLogo']) &&
        _isNotEmpty(data['businessLicense']) &&
        _isNotEmpty(data['employerIdCard'])) {
      completedSections++;
    }

    // Calculate percentage (33%, 66%, or 100%)
    if (completedSections == 0) return 0;
    if (completedSections == 1) return 33;
    if (completedSections == 2) return 66;
    return 100;
  }

  /// Helper to check if a value is not empty
  static bool _isNotEmpty(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return true;
  }

  /// Show dialog when profile is incomplete
  /// Returns true if user clicked "Complete Now", false if "Later"
  static Future<bool> showProfileIncompleteDialog(
    BuildContext context,
    String actionName,
    int completionPercentage,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: const Text(
            'Complete Your Profile Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.lookGigPurple,
              fontFamily: 'DM Sans',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You need to complete your profile to $actionName.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lookGigDescriptionText,
                  fontFamily: 'DM Sans',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your profile is $completionPercentage% complete.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lookGigPurple,
                  fontFamily: 'DM Sans',
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: AppColors.lookGigLightPurple.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.lookGigPurple,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                // Later button with light purple background
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lookGigLightPurple,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Later',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DM Sans',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Complete Now button with dark purple background
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lookGigPurple,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Complete Now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DM Sans',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        );
      },
    );

    // If user clicked "Complete Now", navigate to onboarding
    if (result == true && context.mounted) {
      // CRITICAL: Get role from AuthService to navigate to correct onboarding
      final role = await AuthService.getUserRole();
      if (role != null) {
        if (role == 'employer') {
          Navigator.pushNamed(context, '/employer-onboarding');
        } else {
          Navigator.pushNamed(context, '/student-onboarding');
        }
      }
    }

    return result ?? false;
  }

  /// Main method to check if user can perform an action
  /// Returns true if allowed, false if blocked
  static Future<bool> canPerformAction(
    BuildContext context, {
    String? actionName,
    bool showDialog = true,
  }) async {
    final isComplete = await isProfileComplete();
    
    if (isComplete) {
      return true;
    }

    // Profile is incomplete
    if (showDialog && context.mounted) {
      final percentage = await getCompletionPercentage();
      await showProfileIncompleteDialog(
        context,
        actionName ?? 'perform this action',
        percentage,
      );
    }

    return false;
  }

  /// Check profile completion for job application
  static Future<bool> checkProfileCompletionForJobApplication(
    BuildContext context, {
    bool showDialog = true,
  }) async {
    return canPerformAction(
      context,
      actionName: 'apply for this job',
      showDialog: showDialog,
    );
  }

  /// Check profile completion for job posting (employers)
  static Future<bool> checkProfileCompletionForJobPosting(
    BuildContext context, {
    bool showDialog = true,
  }) async {
    return canPerformAction(
      context,
      actionName: 'post a job',
      showDialog: showDialog,
    );
  }

  /// Check profile completion for bookmarking
  /// Note: Bookmarking is ALLOWED even if profile is incomplete
  static Future<bool> checkProfileCompletionForBookmark(
    BuildContext context, {
    bool showDialog = true,
  }) async {
    // Bookmarking is always allowed
    return true;
  }

  /// Generic profile completion check
  static Future<bool> checkProfileCompletion(
    BuildContext context, {
    bool showDialog = true,
  }) async {
    return canPerformAction(
      context,
      actionName: 'access this feature',
      showDialog: showDialog,
    );
  }

  /// Check and navigate if incomplete
  static Future<bool> checkAndNavigateIfIncomplete(
    BuildContext context, {
    bool showDialog = true,
  }) async {
    return canPerformAction(
      context,
      actionName: 'continue',
      showDialog: showDialog,
    );
  }
}
