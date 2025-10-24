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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSettingCard(
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
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {
                      // Navigate to employer change password screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmployerUpdatePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.helpSupport);
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildLogoutCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/header_background.png'),
              fit: BoxFit.cover,
            ),
            gradient: LinearGradient(
              colors: [
                AppColors.lookGigProfileGradientStart,
                AppColors.lookGigProfileGradientEnd,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileCardShadow,
            blurRadius: 62,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9228).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFF9228), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.lookGigProfileText,
          ),
        ),
        trailing: hasToggle
            ? Switch(
                value: toggleValue,
                onChanged: onToggleChanged,
                activeThumbColor: const Color(0xFFFF9228),
              )
            : const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.lookGigDescriptionText,
              ),
        onTap: hasToggle ? null : onTap,
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileCardShadow,
            blurRadius: 62,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout, color: AppColors.error, size: 24),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.error,
        ),
        onTap: () => _showLogoutDialog(),
      ),
    );
  }

  void _showLogoutDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLogoutModal(),
    );

    if (result == true) {
      // User confirmed logout
      _logout();
    }
  }

  Widget _buildLogoutModal() {
    return Container(
      height: 308, // From Figma layout_3M40KY
      decoration: const BoxDecoration(
        color: AppColors.white, // From Figma fill_RCMW2W
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Top divider line (positioned at x: 173, y: 25 from Figma)
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Container(
              width: 30, // From Figma layout_4NW3L8
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF130160), // From Figma stroke_BSUCMX
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Log out title (positioned at x: 158, y: 75 from Figma)
          const Text(
            'Log out',
            style: TextStyle(
              fontFamily: 'DM Sans', // From Figma style_LO4LE8
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.302,
              color: Color(0xFF150B3D), // From Figma fill_OYSX7Z
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Confirmation message (positioned at x: 100, y: 107 from Figma)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 100),
            child: Text(
              'Are you sure you want to leave?',
              style: TextStyle(
                fontFamily: 'DM Sans', // From Figma style_4CT1AL
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.302,
                color: Color(0xFF524B6B), // From Figma fill_YOI2NZ
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Buttons (positioned at x: 29, y: 168 from Figma)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29), // From Figma layout_U18LLN
            child: Column(
              children: [
                // Yes button (positioned at x: 0, y: 0 from Figma)
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    width: 317, // From Figma layout_YIFPU2
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF130160), // From Figma fill_UTF6FG
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF99ABC6).withOpacity(0.18), // From Figma effect_H91LQV
                          blurRadius: 62,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'YES',
                        style: TextStyle(
                          fontFamily: 'DM Sans', // From Figma style_4PAAIK
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.302,
                          letterSpacing: 0.84,
                          color: AppColors.white, // From Figma fill_RCMW2W
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Cancel button (positioned at x: 0, y: 60 from Figma)
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 317, // From Figma layout_YIFPU2
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6CDFE), // From Figma fill_J8341B
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'DM Sans', // From Figma style_4PAAIK
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.302,
                          letterSpacing: 0.84,
                          color: AppColors.white, // From Figma fill_RCMW2W
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
