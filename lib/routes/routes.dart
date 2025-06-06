import 'package:flutter/material.dart';
import 'package:get_work_app/screens/initial/onboarding_screen.dart';
import 'package:get_work_app/screens/initial/splash_screen.dart';
import 'package:get_work_app/screens/login_signup/login_screen.dart';
import 'package:get_work_app/screens/login_signup/signup_screen.dart';
import 'package:get_work_app/screens/main/employye/emp_ob/employee_onboarding.dart';
import 'package:get_work_app/screens/main/employye/employee_home_screen.dart';
import 'package:get_work_app/screens/main/employye/emp_profile.dart';
import 'package:get_work_app/screens/main/employye/new%20post/all_jobs.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/new_job_screen.dart';
import 'package:get_work_app/screens/main/user/student_ob_screen/student_ob.dart';
import 'package:get_work_app/screens/main/user/user_home_screen.dart';
import 'package:get_work_app/services/auth_wrapper.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String userHome = '/user-home';
  static const String employeeHome = '/employee-home';
  static const String employerProfile = '/employer-profile';
  static const String jobsManagement = '/jobs-management';
  static const String messages = '/messages';
  static const String studentOnboarding = '/student-onboarding';
  static const String employeeOnboarding = '/employee-onboarding';
  static const String createJobOpening = '/create-job-opening';
  static const String allJobListings = '/all-job-listings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
      case home:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
case AppRoutes.allJobListings:
  final args = settings.arguments as Map<String, dynamic>?;
  return MaterialPageRoute(
    builder: (_) => AllJobListingsScreen(
      initialJobs: args?['initialJobs'] as List<Job>?,
      onStatusChanged: args?['onStatusChanged'] as Function(String, bool)?,
    ),
  );

      case userHome:
        return MaterialPageRoute(builder: (_) => const UserHomeScreen());

      case employeeHome:
        return MaterialPageRoute(builder: (_) => const EmployerDashboardScreen());

      case employerProfile:
        return MaterialPageRoute(builder: (_) => const EmpProfile());

      case jobsManagement:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Jobs Management')),
            body: const Center(
              child: Text('Jobs Management Screen'),
            ),
          ),
        );

      case messages:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Messages')),
            body: const Center(
              child: Text('Messages Screen'),
            ),
          ),
        );

      case studentOnboarding:
        return MaterialPageRoute(
          builder: (_) => const StudentOnboardingScreen(),
          settings: settings,
        );

      case employeeOnboarding:
        return MaterialPageRoute(
          builder: (_) => const EmployeeOnboardingScreen(),
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