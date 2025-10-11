import 'package:flutter/material.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/utils/app_colors.dart';

class PasswordResetCompleteScreen extends StatelessWidget {
  const PasswordResetCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 375),
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Title
                const Text(
                  'Successfully',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0140),
                    fontFamily: 'DM Sans',
                    height: 1.302,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Your password has been updated, please change your password regularly to avoid this happening',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.lookGigDescriptionText,
                      fontFamily: 'DM Sans',
                      height: 1.6,
                    ),
                  ),
                ),
                
                const SizedBox(height: 55),
                
                // Illustration
                Image.asset(
                  'assets/images/password_reset_complete_illustration.png',
                  width: 139,
                  height: 117,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 139,
                      height: 117,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50),
                    );
                  },
                ),
                
                const Spacer(flex: 3),
                
                // Continue Button
                Container(
                  width: 317,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lookGigPurple,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF99ABC6).withOpacity(0.18),
                        blurRadius: 62,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to login screen
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lookGigPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.84,
                        height: 1.302,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Back to Login Button
                Container(
                  width: 317,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6CDFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to login screen
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6CDFE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'BACK TO LOGIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.84,
                        height: 1.302,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
