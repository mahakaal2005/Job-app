import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:get_work_app/screens/main/employer/profile/employer_update_password_screen.dart';

class EMPLOYERSettingsScreen extends StatefulWidget {
  const EMPLOYERSettingsScreen({super.key});

  @override
  State<EMPLOYERSettingsScreen> createState() => _EMPLOYERSettingsScreenState();
}

class _EMPLOYERSettingsScreenState extends State<EMPLOYERSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF524B6B),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Settings title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.302,
                      color: Color(0xFF150A33),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 47),

            // Settings items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Notifications setting
                    _buildSettingItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      hasToggle: true,
                      toggleValue: _notificationsEnabled,
                      onToggleChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Password setting
                    _buildSettingItem(
                      icon: Icons.lock_outline,
                      title: 'Password',
                      hasArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployerUpdatePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Privacy Policy setting
                    _buildSettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      hasArrow: true,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Help & Support setting
                    _buildSettingItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      hasArrow: true,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.helpSupport);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Logout setting
                    _buildSettingItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      hasArrow: true,
                      isLogout: true,
                      onTap: _showLogoutConfirmation,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    _buildSaveButton(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
    bool hasArrow = false,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 335,
        height: subtitle != null ? 60 : 50,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              // Icon
              Icon(
                icon,
                size: 24,
                color: isLogout ? AppColors.error : const Color(0xFF150B3D),
              ),
              const SizedBox(width: 11),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: isLogout ? AppColors.error : const Color(0xFF150B3D),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Toggle switch or arrow
              if (hasToggle)
                _buildToggleSwitch(toggleValue, onToggleChanged!)
              else if (hasArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: isLogout ? AppColors.error : const Color(0xFF150B3D),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 38,
        height: 19,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF56CD54) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(19),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveSettings,
      child: Container(
        width: 213,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF130160),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withOpacity(0.18),
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                )
              : const Text(
                  'SAVE',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.302,
                    letterSpacing: 0.84,
                    color: AppColors.white,
                  ),
                ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLogoutModal(),
    );

    if (result == true) {
      _logout();
    }
  }

  Widget _buildLogoutModal() {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Draggable handle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5858),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Title
              const Text(
                'Log out',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.302,
                  color: Color(0xFF150B3D),
                  decoration: TextDecoration.none,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 100),
                child: Text(
                  'Are you sure you want to leave?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.302,
                    color: Color(0xFF524B6B),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: Column(
                  children: [
                    // Yes button
                    GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        width: 317,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF130160),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF99ABC6).withOpacity(0.18),
                              blurRadius: 62,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'YES',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.302,
                              letterSpacing: 0.84,
                              color: AppColors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Cancel button
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        width: 317,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6CDFE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.302,
                              letterSpacing: 0.84,
                              color: AppColors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate saving settings
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Settings saved successfully!',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error saving settings: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error logging out: $e',
          isSuccess: false,
        );
      }
    }
  }
}
