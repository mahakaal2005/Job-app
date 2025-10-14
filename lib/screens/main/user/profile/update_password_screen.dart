import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_RV2DD5
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button (positioned at x: 20, y: 30 from Figma)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      'assets/images/update_password_back_icon.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF524B6B),
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Title "Update Password" (positioned at x: 20, y: 94 from Figma)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
                child: Text(
                  'Update Password',
                  style: const TextStyle(
                    fontFamily: 'DM Sans', // From Figma style_NQ6NTG
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.302,
                    color: Color(0xFF150A33), // From Figma fill_BQQFS1
                  ),
                ),
              ),

              const SizedBox(height: 47), // Gap to first field (141 - 94 - 21 = 26, but need more for proper spacing)

              // Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Old Password field (positioned at x: 20, y: 141 from Figma)
                      _buildPasswordField(
                        label: 'Old Password',
                        controller: _oldPasswordController,
                        isVisible: _isOldPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isOldPasswordVisible = !_isOldPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your old password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15), // Gap between fields (222 - 141 - 66 = 15)

                      // New Password field (positioned at x: 20, y: 222 from Figma)
                      _buildPasswordField(
                        label: 'New Password',
                        controller: _newPasswordController,
                        isVisible: _isNewPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15), // Gap between fields (303 - 222 - 66 = 15)

                      // Confirm Password field (positioned at x: 20, y: 303 from Figma)
                      _buildPasswordField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 302), // Space to button (671 - 303 - 66 = 302)

                      // Update button (positioned at x: 81, y: 671 from Figma)
                      _buildUpdateButton(),
                      
                      const SizedBox(height: 50), // Bottom padding
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
  Widget
 _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
  }) {
    return SizedBox(
      width: 335, // From Figma dimensions
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans', // From Figma style_NDRZ5T
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.302,
              color: Color(0xFF150A33), // From Figma fill_BQQFS1
            ),
          ),
          const SizedBox(height: 10), // Gap between label and input
          
          // Input field container
          Container(
            height: 40, // From Figma layout_L7FIME
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF), // From Figma fill_80TU3Y
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99ABC6).withOpacity(0.18), // From Figma effect_P3HNLM
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: !isVisible,
              validator: validator,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: Color(0xFF150A33),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                suffixIcon: GestureDetector(
                  onTap: onVisibilityToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 20),
                    child: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                      color: const Color(0xFFB0B0B0), // From Figma fill_KN7T5E
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoading ? null : _updatePassword,
        child: Container(
          width: 213, // From Figma layout_V3QUKH
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF130160), // From Figma fill_PLVX5Q
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF99ABC6).withOpacity(0.18), // From Figma effect_P3HNLM
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Color(0xFFFFFFFF),
                    strokeWidth: 2,
                  )
                : const Text(
                    'UPDATE', // From Figma text content, uppercase
                    style: TextStyle(
                      fontFamily: 'DM Sans', // From Figma style_U9WLNP
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.302,
                      letterSpacing: 0.84, // 6% of 14px
                      color: Color(0xFFFFFFFF), // From Figma fill_80TU3Y
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement password update logic with Firebase Auth
      // This will require backend integration
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        _showSuccessSnackBar('Password updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating password: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}