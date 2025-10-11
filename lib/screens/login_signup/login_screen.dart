import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        
        // Get user role and navigate to appropriate home screen
        await _navigateBasedOnUserRole();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // If user not found, redirect to signup
        if (e.code == 'user-not-found') {
          _showAccountNotExistDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _navigateBasedOnUserRole() async {
    try {
      // Get the current user's role from your auth service
      String? userRole = await AuthService.getCurrentUserRole();
      
      if (mounted) {
        // Navigate to appropriate home screen based on role
        if (userRole == 'user') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.userHome,
            (route) => false,
          );
        } else if (userRole == 'employee') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.employeeHome,
            (route) => false,
          );
        } else {
          // Default fallback - you might want to handle this case differently
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home, // This will go to AuthWrapper
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // If role retrieval fails, fallback to AuthWrapper
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    }
  }

  void _showAccountNotExistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Not Found'),
        content: const Text(
          'This email is not registered. Would you like to create a new account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.signup,
                arguments: _emailController.text.trim(),
              );
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _forgotPassword() {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                    const SizedBox(height: 102),

                    // Header - Welcome Back
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lookGigPurple,
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                    const SizedBox(height: 11),
                    
                    // Subtitle
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 13),
                      child: Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
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

                    const SizedBox(height: 64),

                    // Email input
                    SizedBox(
                      width: 317,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 3),
                            child: Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.lookGigPurple,
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
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
                                color: AppColors.lookGigPurple.withOpacity(0.6),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Brandonelouis@gmail.com',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lookGigPurple.withOpacity(0.6),
                                  fontFamily: 'DM Sans',
                                  height: 1.302,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
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

                    const SizedBox(height: 15),

                    // Password input
                    SizedBox(
                      width: 317,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 3),
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lookGigPurple,
                                fontFamily: 'Open Sans',
                                height: 1.3618,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF99ABC6).withOpacity(0.18),
                                  blurRadius: 62,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••••',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  height: 1.302,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 17,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFFB0B0B0),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Remember me and Forgot password row
                    SizedBox(
                      width: 317,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember me checkbox
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6E1FF),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF99ABC6).withOpacity(0.18),
                                      blurRadius: 62,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFFE6E1FF),
                                  checkColor: const Color(0xFFAAA6B9),
                                  side: BorderSide.none,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFAAA6B9),
                                  fontFamily: 'DM Sans',
                                  height: 1.302,
                                ),
                              ),
                            ],
                          ),
                          // Forgot password
                          TextButton(
                            onPressed: _forgotPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password ?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.lookGigPurple,
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Login Button
                    Container(
                      width: 266,
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
                        onPressed: _isLoading ? null : _signIn,
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
                                'LOGIN',
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

                    const SizedBox(height: 19),

                    // Sign in with Google Button
                    Container(
                      width: 264,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6CDFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement Google Sign In
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Google Sign In coming soon!')),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_icon.png',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'SIGN IN WITH GOOGLE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.lookGigPurple,
                                fontFamily: 'DM Sans',
                                letterSpacing: 0.84,
                                height: 1.302,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sign up link
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.signup);
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "You don't have an account yet?  ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.lookGigDescriptionText,
                            fontFamily: 'Open Sans',
                            height: 1.3618,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.orange,
                                fontFamily: 'Open Sans',
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.orange,
                                height: 1.3618,
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
      ),
    );
  }
}