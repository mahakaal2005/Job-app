import 'package:flutter/material.dart';
import 'package:get_work_app/screens/initial/onboarding_screen.dart';
import 'package:get_work_app/screens/initial/splash_screen.dart';
import 'package:get_work_app/screens/login_signup/login_screen.dart';
import 'package:get_work_app/screens/login_signup/signup_screen.dart';
import 'package:get_work_app/screens/main/employye/emp_ob/employee_onboarding.dart';
import 'package:get_work_app/screens/main/employye/employee_home_screen.dart';
import 'package:get_work_app/screens/main/user/student_ob_screen/student_ob.dart';
import 'package:get_work_app/screens/main/user/user_home_screen.dart';
import 'package:get_work_app/services/auth_wrapper.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home'; // This will be handled by AuthWrapper
  static const String userHome = '/user-home';
  static const String employeeHome = '/employee-home';
  static const String studentOnboarding = '/student-onboarding';
  static const String employeeOnboarding = '/employee-onboarding';

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
      case home:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());

      case userHome:
        return MaterialPageRoute(builder: (_) => const UserHomeScreen());

      case employeeHome:
        return MaterialPageRoute(builder: (_) => const EmployerHomeScreen());

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
