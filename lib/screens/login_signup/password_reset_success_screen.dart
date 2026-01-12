import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';

class PasswordResetSuccessScreen extends StatefulWidget {
  final String email;

  const PasswordResetSuccessScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetSuccessScreen> createState() =>
      _PasswordResetSuccessScreenState();
}

class _PasswordResetSuccessScreenState
    extends State<PasswordResetSuccessScreen> with WidgetsBindingObserver {
  bool _isResending = false;
  
  // Two-flag system for password reset detection
  final bool _resetEmailSent = true; // Always true on this screen (email was sent to reach here)
  bool _passwordWasReset = false; // Set to true when user confirms they reset password
  
  // Helper flags
  bool _userOpenedEmail = false; // Track if user clicked "Open Your Email"
  bool _hasShownDialog = false; // Prevent showing dialog multiple times

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app resumes, check conditions
    if (state == AppLifecycleState.resumed && mounted) {
      
      // If user opened email but hasn't confirmed reset yet, show dialog
      if (_userOpenedEmail && !_hasShownDialog && !_passwordWasReset) {
        _hasShownDialog = true;
        
        // Small delay to ensure app is fully resumed
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showPasswordResetConfirmationDialog();
          }
        });
      }
      
      // If BOTH flags are true, navigate to complete screen
      else if (_resetEmailSent && _passwordWasReset) {
        // Small delay to ensure app is fully resumed
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.passwordResetComplete,
            );
          }
        });
      }
    }
  }

  void _showPasswordResetConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Password Reset',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF0D0140),
            ),
          ),
          content: const Text(
            'Have you completed resetting your password?',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: AppColors.gigAppDescriptionText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset flag so dialog can show again if user leaves and returns
                setState(() {
                  _hasShownDialog = false;
                });
              },
              child: const Text(
                'Not Yet',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w600,
                  color: AppColors.gigAppDescriptionText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Set the second flag: password was reset
                setState(() {
                  _passwordWasReset = true;
                });
                
                // Check both flags before navigating
                if (_resetEmailSent && _passwordWasReset) {
                  // Both flags are true, navigate to complete screen
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.passwordResetComplete,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gigAppPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Yes, I Have',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEmailApp() async {
    // Mark that user opened email app
    setState(() {
      _userOpenedEmail = true;
    });
    
    try {
      // Try to open Gmail app directly using package URL
      final Uri gmailUri = Uri.parse('android-app://com.google.android.gm');
      
      bool launched = await launchUrl(
        gmailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // If Gmail doesn't work, try generic email intent
        // This opens the email app chooser on Android
        final Uri emailIntent = Uri(
          scheme: 'mailto',
          queryParameters: {'subject': ''}, // Empty subject to minimize compose mode
        );
        
        launched = await launchUrl(
          emailIntent,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please open your email app manually to check your inbox.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please open your email app manually to check your inbox.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      await AuthService.resetPassword(email: widget.email);

      if (mounted) {
        setState(() {
          _isResending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset email sent again!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });

        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email address.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please wait before trying again.';
            break;
          default:
            errorMessage = e.message ?? 'Failed to resend email.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gigAppLightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 375),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 92),

                  // Title
                  const Text(
                    'Check Your Email',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D0140),
                      fontFamily: 'DM Sans',
                      height: 1.302,
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      'We have sent the reset password link to ${widget.email}\n\nPlease open your email app and check your inbox.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gigAppDescriptionText,
                        fontFamily: 'Open Sans',
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Illustration
                  Image.asset(
                    'assets/images/email_sent_illustration.png',
                    width: 125,
                    height: 109,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 125,
                        height: 109,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          size: 50,
                          color: AppColors.primaryBlue,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 94),

                  // Open Your Email Button
                  Container(
                    width: 317,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.gigAppPurple,
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
                      onPressed: _openEmailApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gigAppPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'OPEN YOUR EMAIL',
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
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
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

                  const SizedBox(height: 30),

                  // Resend link
                  GestureDetector(
                    onTap: _isResending ? null : _resendEmail,
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gigAppPurple,
                            ),
                          )
                        : RichText(
                            text: const TextSpan(
                              text: 'You have not received the email?  ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.gigAppDescriptionText,
                                fontFamily: 'Open Sans',
                                height: 1.6,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Resend',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF150B3D),
                                    fontFamily: 'Open Sans',
                                    decoration: TextDecoration.underline,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
