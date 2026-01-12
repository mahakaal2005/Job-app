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
    return FutureBuilder<String?>(
      future: AuthService.getUserRole(),
      builder: (context, roleSnapshot) {
        if (!roleSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final role = roleSnapshot.data;
        if (role == null) {
          return const SizedBox.shrink();
        }

        final collectionName = role == 'employer' ? 'employers' : 'users_specific';
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }

            final doc = snapshot.data!;
            if (!doc.exists) {
              return const SizedBox.shrink();
            }

            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              return const SizedBox.shrink();
            }

            // Get completion data - Use ProfileGatingService for consistency
            final isComplete = data['onboardingCompleted'] == true;

            // Don't show if profile is complete
            if (isComplete) {
              return const SizedBox.shrink();
            }

            // Use ProfileGatingService to get the same calculation as dialogs
            return FutureBuilder<int>(
              future: ProfileGatingService.getCompletionPercentage(),
              builder: (context, percentageSnapshot) {
                if (!percentageSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final percentage = percentageSnapshot.data!;

                // Don't show if 100% complete
                if (percentage >= 100) {
                  return const SizedBox.shrink();
                }

                return _buildCompletionCard(context, percentage, role);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompletionCard(BuildContext context, int percentage, String role) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF130160), // gigAppPurple
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
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
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
              foregroundColor: AppColors.gigAppPurple,
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