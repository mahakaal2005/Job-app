import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/user/student_ob_screen/student_ob.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/employer_onboarding.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/screens/main/user/user_home_screen_new.dart';
import 'package:get_work_app/screens/main/employer/employer_home_screen.dart';
import 'package:get_work_app/screens/initial/onboarding_screen.dart';
import 'package:get_work_app/utils/app_colors.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.white,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
          );
        }

        // Handle stream errors
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Authentication Error',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to onboarding screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is not authenticated, show onboarding screen directly
        if (!snapshot.hasData || snapshot.data == null) {
          return const OnboardingScreen();
        }

        // If user is authenticated, determine which screen to show
        return FutureBuilder<Map<String, dynamic>>(
          future: _getUserStateAndRole(snapshot.data!.uid),
          builder: (context, stateSnapshot) {
            // Show loading while getting user state and role
            if (stateSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Handle error in getting user state and role
            if (stateSnapshot.hasError) {
              return Scaffold(
                backgroundColor: AppColors.white,
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading user data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${stateSnapshot.error}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await AuthService.signOut();
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const OnboardingScreen(),
                                    ),
                                  );
                                }
                              } catch (e) {
                                // If sign out fails, still navigate to onboarding
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const OnboardingScreen(),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final userState = stateSnapshot.data!;
            final String? userRole = userState['role'];
            final bool onboardingCompleted = userState['onboardingCompleted'] ?? false;
            final bool skippedOnboarding = userState['skippedOnboarding'] ?? false;

            // Debug logging
            print('🔍 DEBUG AuthWrapper: Role = $userRole');
            print('🔍 DEBUG AuthWrapper: Onboarding Complete = $onboardingCompleted');
            print('🔍 DEBUG AuthWrapper: Skipped Onboarding = $skippedOnboarding');

            // Route based on role and onboarding status
            if (userRole == 'user') {
              // User role (student)
              print('🔍 DEBUG AuthWrapper: Routing to USER screens');
              // If user skipped onboarding OR completed it, go to home
              // Only redirect to onboarding if they haven't completed AND haven't skipped
              if (!onboardingCompleted && !skippedOnboarding) {
                return const StudentOnboardingScreen();
              } else {
                // Wrap in PopScope to handle back button - exit app instead of navigating back
                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (!didPop) {
                      // Exit the app when back button is pressed on home screen
                      SystemNavigator.pop();
                    }
                  },
                  child: const UserHomeScreenNew(),
                );
              }
            } else if (userRole == 'employer') {
              // Employer role
              print('🔍 DEBUG AuthWrapper: Routing to EMPLOYER screens');
              // If employer skipped onboarding OR completed it, go to home
              // Only redirect to onboarding if they haven't completed AND haven't skipped
              if (!onboardingCompleted && !skippedOnboarding) {
                return const EmployerOnboardingScreen();
              } else {
                // Wrap in PopScope to handle back button - exit app instead of navigating back
                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (!didPop) {
                      // Exit the app when back button is pressed on home screen
                      SystemNavigator.pop();
                    }
                  },
                  child: const EmployerDashboardScreen(),
                );
              }
            } else {
              // Default case - redirect to user onboarding if role is not set
              print('⚠️ WARNING AuthWrapper: No role found, defaulting to user onboarding');
              return const StudentOnboardingScreen();
            }
          },
        );
      },
    );
  }

  // Get both user role and onboarding status
  Future<Map<String, dynamic>> _getUserStateAndRole(String uid) async {
    try {
      print('DEBUG [AUTH_WRAPPER] Getting user state for uid: $uid');
      
      // Get user role from AuthService
      final String? userRole = await AuthService.getCurrentUserRole();
      print('DEBUG [AUTH_WRAPPER] User role: $userRole');
      
      // Check if user has completed onboarding (works for both users and employers)
      bool onboardingCompleted = await AuthService.hasUserCompletedOnboarding(uid);
      print('DEBUG [AUTH_WRAPPER] Onboarding completed: $onboardingCompleted');
      
      // Get profile completion status (includes skippedOnboarding flag)
      final completionStatus = await AuthService.getProfileCompletionStatus();
      bool skippedOnboarding = completionStatus['skippedOnboarding'] ?? false;
      print('DEBUG [AUTH_WRAPPER] Skipped onboarding: $skippedOnboarding');
      print('DEBUG [AUTH_WRAPPER] Profile completion status: $completionStatus');

      final result = {
        'role': userRole,
        'onboardingCompleted': onboardingCompleted,
        'skippedOnboarding': skippedOnboarding,
      };
      
      print('DEBUG [AUTH_WRAPPER] Returning state: $result');
      return result;
    } catch (e) {
      print('DEBUG [AUTH_WRAPPER] Error getting user state: $e');
      throw Exception('Failed to get user state and role: ${e.toString()}');
    }
  }
}