import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/initial/onboarding_screen.dart';
import 'package:get_work_app/screens/main/user/student_ob_screen/student_ob.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/screens/main/user/user_home_screen.dart';
import 'package:get_work_app/screens/main/employye/employee_home_screen.dart';
import 'package:get_work_app/screens/login_signup/login_screen.dart';
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is not authenticated, show login screen
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
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
                        'Error loading user data',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${stateSnapshot.error}',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await AuthService.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final userState = stateSnapshot.data!;
            final String? userRole = userState['role'];
            final bool onboardingCompleted = userState['onboardingCompleted'] ?? false;

            // If user role is 'user' (student) and onboarding is not completed
            if (userRole == 'user' && !onboardingCompleted) {
              return const StudentOnboardingScreen();
            }

            // Navigate to appropriate home screen based on role
            if (userRole == 'employee') {
              return const EmployeeHomeScreen();
            } else if (userRole == 'user') {
              return const UserHomeScreen();
            } else {
              // Default to user home if role is null or unrecognized
              return const UserHomeScreen();
            }
          },
        );
      },
    );
  }

  // Get both user role and onboarding status
  Future<Map<String, dynamic>> _getUserStateAndRole(String uid) async {
    try {
      // Get user role from AuthService
      final String? userRole = await AuthService.getCurrentUserRole();
      
      // If user is a student, check onboarding status
      bool onboardingCompleted = true; // Default for employees
      
      if (userRole == 'user') {
        // Check if student has completed onboarding
        onboardingCompleted = await AuthService.hasUserCompletedOnboarding(uid);
      }

      return {
        'role': userRole,
        'onboardingCompleted': onboardingCompleted,
      };
    } catch (e) {
      throw Exception('Failed to get user state and role: ${e.toString()}');
    }
  }
}