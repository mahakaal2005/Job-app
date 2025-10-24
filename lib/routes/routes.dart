import 'package:flutter/material.dart';
import 'package:get_work_app/screens/initial/onboarding_screen.dart';
import 'package:get_work_app/screens/initial/splash_screen.dart';
import 'package:get_work_app/screens/login_signup/login_screen.dart';
import 'package:get_work_app/screens/login_signup/signup_screen.dart';
import 'package:get_work_app/screens/login_signup/forgot_password_screen.dart';
import 'package:get_work_app/screens/login_signup/password_reset_success_screen.dart';
import 'package:get_work_app/screens/login_signup/password_reset_complete_screen.dart';
import 'package:get_work_app/screens/main/employer/emp_analytics.dart';
import 'package:get_work_app/screens/main/employer/emp_chats.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/employer_onboarding.dart';
import 'package:get_work_app/screens/main/employer/employer_home_screen.dart';
import 'package:get_work_app/screens/main/employer/emp_profile.dart';
import 'package:get_work_app/screens/main/employer/emp_help_support.dart';
import 'package:get_work_app/screens/main/employer/emp_privacy_policy.dart';
import 'package:get_work_app/screens/main/employer/new%20post/all_jobs.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/employer/new%20post/new_job_screen.dart';
import 'package:get_work_app/screens/main/user/student_ob_screen/student_ob.dart';
import 'package:get_work_app/screens/main/user/user_home_screen_new.dart';
import 'package:get_work_app/screens/main/user/user_profile.dart';
import 'package:get_work_app/screens/main/user/jobs/no_results_screen.dart';
import 'package:get_work_app/services/auth_wrapper.dart';

class AppRoutes {
  static const String splash = '/splash'; // Changed from '/' to '/splash' to prevent back navigation issues
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String passwordResetSuccess = '/password-reset-success';
  static const String passwordResetComplete = '/password-reset-complete';
  static const String home = '/';
  static const String userHome = '/user-home';
  static const String employerHome = '/employer-home';
  static const String employerProfile = '/employer-profile';
  static const String jobsManagement = '/jobs-management';
  static const String messages = '/messages';
  static const String studentOnboarding = '/student-onboarding';
  static const String employerOnboarding = '/employer-onboarding';
  static const String createJobOpening = '/create-job-opening';
  static const String allJobListings = '/all-job-listings';
  static const String helpSupport = '/help-support';
  static const String privacyPolicy = '/privacy-policy';
  static const String reports = '/reports';
  static const String empProfile = '/emp-profile';
  static const String userProfile = '/user-profile';
  static const String noResults = '/no-results';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('🔵 [ROUTES] Generating route for: ${settings.name}');
    switch (settings.name) {
      case home:
        print('🔵 [ROUTES] Navigating to AuthWrapper');
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings: settings,
        );
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case passwordResetSuccess:
        final email = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => PasswordResetSuccessScreen(email: email),
          settings: settings,
        );
      case passwordResetComplete:
        return MaterialPageRoute(
          builder: (_) => const PasswordResetCompleteScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case createJobOpening:
        return MaterialPageRoute(
          builder: (_) => const CreateJobScreen(),
          settings: settings,
        );
      case allJobListings:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (_) => AllJobListingsScreen(
                initialJobs: args?['initialJobs'] as List<Job>?,
                onStatusChanged:
                    args?['onStatusChanged'] as Function(String, bool)?,
              ),
        );
      case userHome:
        return MaterialPageRoute(builder: (_) => const UserHomeScreenNew());
      case employerHome:
        return MaterialPageRoute(
          builder: (_) => const EmployerDashboardScreen(),
        );
      case employerProfile:
        return MaterialPageRoute(builder: (_) => const EmpProfile());
      case helpSupport:
        return MaterialPageRoute(builder: (_) => const EmpHelpSupportScreen());
      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const EmpPrivacyPolicyScreen());
      case jobsManagement:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('Jobs Management')),
                body: const Center(child: Text('Jobs Management Screen')),
              ),
        );
      case messages:
        return MaterialPageRoute(
          builder:
              (_) => const EmpChats(),
        );
      
      case reports:
        return MaterialPageRoute(
          builder: (_) => const EmpAnalytics(),
        );

      case empProfile:
        return MaterialPageRoute(
          builder: (_) => const EmpProfile(),
        );

      case userProfile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case studentOnboarding:
        return MaterialPageRoute(
          builder: (_) => const StudentOnboardingScreen(),
          settings: settings,
        );
      case employerOnboarding:
        return MaterialPageRoute(
          builder: (_) => const EmployerOnboardingScreen(),
          settings: settings,
        );
      case noResults:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => NoResultsScreen(
            searchQuery: args?['searchQuery'] as String? ?? '',
            onBack: args?['onBack'] as VoidCallback?,
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder:
              (_) => Builder(
                builder:
                    (context) => Scaffold(
                      appBar: AppBar(title: const Text('Page Not Found')),
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
                            Text(
                              'No route defined for ${settings.name}',
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.home,
                                );
                              },
                              child: const Text('Go Home'),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
        );
    }
  }
}
