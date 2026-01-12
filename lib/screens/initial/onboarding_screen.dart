import 'package:flutter/material.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/utils/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.gigAppLightGray,
        ),
        child: SafeArea(
          child: Column(
                    children: [
                      // Top section with logo
                      Padding(
                        padding: const EdgeInsets.only(top: 20, right: 32),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            'GigApp',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ),
                      ),
                      
                      // Main illustration
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Center(
                            child: Image.asset(
                              'assets/images/main_illustration.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.work_outline,
                                    size: 100,
                                    color: AppColors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      // Bottom section with text and icon
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main heading
                              const Text(
                                'Find Your\nDream Job\nHere!',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                  fontFamily: 'DM Sans',
                                  height: 0.95,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Description text
                              const Text(
                                'Explore all the most exciting job roles based\non your interest and study major.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.gigAppDescriptionText,
                                  fontFamily: 'DM Sans',
                                  height: 1.3,
                                ),
                              ),
                              
                              const Spacer(),
                              
                              // Bottom icon with tap functionality
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 40),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                                    },
                                    child: Image.asset(
                                      'assets/images/bottom_icon.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward,
                                            color: AppColors.white,
                                            size: 30,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}