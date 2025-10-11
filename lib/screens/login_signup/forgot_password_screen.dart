import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();

      // First, check if email is registered
      final bool isRegistered = await AuthService.isEmailRegistered(email);

      if (!isRegistered) {
        // Email not found - show error immediately
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No account found with this email address. Please check your email or sign up.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Email exists - proceed to send password reset email
      await AuthService.resetPassword(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to success screen with email
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.passwordResetSuccess,
          arguments: email,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
            errorMessage = 'Too many requests. Please try again later.';
            break;
          default:
            errorMessage = e.message ?? 'Failed to send reset email.';
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
          _isLoading = false;
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
      backgroundColor: AppColors.lookGigLightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 375),
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 90),

                    // Title
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D0140),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),

                    const SizedBox(height: 11),

                    // Subtitle
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        'To reset your password, you need your email or mobile number that can be authenticated',
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

                    const SizedBox(height: 52),

                    // Illustration
                    Image.asset(
                      'assets/images/forgot_password_icon.png',
                      width: 118,
                      height: 94,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 118,
                          height: 94,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 50,
                            color: AppColors.primaryBlue,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 72),

                    // Email input
                    SizedBox(
                      width: 326,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF150B3D),
                              fontFamily: 'DM Sans',
                              height: 1.302,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF99ABC6).withOpacity(0.18),
                                  blurRadius: 62,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF0D0140).withOpacity(0.6),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Brandonelouis@gmail.com',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF0D0140).withOpacity(0.6),
                                  fontFamily: 'DM Sans',
                                  height: 1.302,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 17,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 29),

                    // Reset Password Button
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
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lookGigPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : const Text(
                                'RESET PASSWORD',
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

                    const SizedBox(height: 29),

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

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
