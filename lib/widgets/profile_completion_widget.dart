import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/services/profile_gating_service.dart';
import 'package:get_work_app/utils/app_colors.dart';

/// Profile completion card widget that shows on profile screen
class ProfileCompletionWidget extends StatelessWidget {
  final bool showDetailedView;
  final VoidCallback? onCompletePressed;

  const ProfileCompletionWidget({
    super.key,
    this.showDetailedView = false,
    this.onCompletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCompletionData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final percentage = data['percentage'] as int;
        final isComplete = data['isComplete'] as bool;
        final role = data['role'] as String;

        // Don't show if profile is complete
        if (isComplete || percentage >= 100) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF130160), // lookGigPurple
                Color(0xFF6C5CE7), // Lighter purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF130160).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Info icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Text and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role == 'employer'
                          ? 'Complete Your Company Profile'
                          : 'Complete Your Profile',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage% complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Complete button
              ElevatedButton(
                onPressed: () => _handleCompletePressed(context, role),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.lookGigPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCompletionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'percentage': 0, 'isComplete': false, 'role': 'user'};
    }

    // CRITICAL: Use AuthService to get role from correct collection
    final role = await AuthService.getUserRole();
    if (role == null) {
      return {'percentage': 0, 'isComplete': false, 'role': 'user'};
    }

    // Get data from role-specific collection
    final collectionName = role == 'employer' ? 'employers' : 'users_specific';
    final userDoc = await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return {'percentage': 0, 'isComplete': false, 'role': role};
    }

    final data = userDoc.data()!;
    final isComplete = data['onboardingCompleted'] == true;
    final percentage = await ProfileGatingService.getCompletionPercentage();

    return {
      'percentage': percentage,
      'isComplete': isComplete,
      'role': role,
    };
  }

  void _handleCompletePressed(BuildContext context, String role) {
    if (onCompletePressed != null) {
      onCompletePressed!();
    } else {
      // Navigate to appropriate onboarding
      if (role == 'employer') {
        Navigator.pushNamed(context, '/employer-onboarding');
      } else {
        Navigator.pushNamed(context, '/student-onboarding');
      }
    }
  }
}

/// Compact badge for headers/navigation (currently disabled)
class ProfileCompletionBadge extends StatelessWidget {
  const ProfileCompletionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Disabled for now
  }
}