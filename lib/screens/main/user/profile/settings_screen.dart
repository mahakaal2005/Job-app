import 'package:flutter/material.dart';
import 'package:get_work_app/provider/applicant_provider.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/screens/main/user/profile/update_password_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _isLoading = false;
  
  // Profile completion tracking
  bool _profileCompleted = true;
  int _profileCompletionPercentage = 100;
  bool _skippedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadProfileCompletionStatus();
  }

  Future<void> _loadProfileCompletionStatus() async {
    try {
      // Profile completion status removed
      if (mounted) {
        setState(() {
          _skippedOnboarding = false;
          _profileCompletionPercentage = 100; // Always complete
          _profileCompleted = true; // Always complete
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_TD29C7
      body: SafeArea(
        child: Column(
              children: [
                // Header with back button and title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0), // From Figma layout_D95AYF
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/images/about_me_back_icon.png',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF524B6B),
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
                    ],
                  ),
                ),

                // Settings title (positioned at x: 20, y: 94 from Figma)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Settings',
                        style: const TextStyle(
                          fontFamily: 'DM Sans', // From Figma style_MLEUUI
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 1.302,
                          color: Color(0xFF150A33), // From Figma fill_PTJ18L
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 47), // Gap to first setting item

                // Settings items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Notifications setting (positioned at x: 20, y: 141 from Figma)
                        _buildSettingItem(
                          icon: 'assets/images/notification_icon.png',
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

                        // Dark mode setting (positioned at x: 20, y: 201 from Figma)
                        _buildSettingItem(
                          icon: 'assets/images/dark_mode_icon.png',
                          title: 'Dark mode',
                          hasToggle: true,
                          toggleValue: _darkModeEnabled,
                          onToggleChanged: (value) {
                            setState(() {
                              _darkModeEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),

                        // Complete Profile setting (NEW - show ONLY if profile is less than 100% complete)
                        if (_profileCompletionPercentage < 100)
                          _buildSettingItem(
                            icon: 'assets/images/profile_icon.png',
                            title: 'Complete Profile',
                            subtitle: '$_profileCompletionPercentage% complete',
                            hasArrow: true,
                            showBadge: true,
                            onTap: _navigateToCompleteProfile,
                          ),
                        if (_profileCompletionPercentage < 100) 
                          const SizedBox(height: 10),

                        // Password setting (positioned at x: 20, y: 261 from Figma)
                        _buildSettingItem(
                          icon: 'assets/images/password_icon.png',
                          title: 'Password',
                          hasArrow: true,
                          onTap: () {
                            // Navigate to password change screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpdatePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Logout setting (positioned at x: 20, y: 321 from Figma)
                        _buildSettingItem(
                          icon: 'assets/images/logout_icon.png',
                          title: 'Logout',
                          hasArrow: true,
                          onTap: _showLogoutConfirmation,
                        ),

                        const Spacer(),

                        // Save button (positioned at x: 81, y: 671 from Figma)
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
    required String icon,
    required String title,
    String? subtitle,
    bool hasToggle = false,
    bool toggleValue = false,
    ValueChanged<bool>? onToggleChanged,
    bool hasArrow = false,
    bool showBadge = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 335, // From Figma layout_YJFR7O
        height: subtitle != null ? 60 : 50, // Taller if has subtitle
        decoration: BoxDecoration(
          color: AppColors.white, // From Figma fill_ROSM8H
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withOpacity(0.18), // From Figma effect_20ABQ0
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13), // From Figma layout_Z2TV3A
          child: Row(
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      icon,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          _getDefaultIcon(title),
                          size: 24,
                          color: const Color(0xFF150B3D),
                        );
                      },
                    ),
                  ),
                  // Badge indicator
                  if (showBadge)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 11), // Gap to title (55 - 20 - 24 = 11)

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'DM Sans', // From Figma style_XLWF0Y
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: Color(0xFF150B3D), // From Figma fill_YIIY4R
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
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFF150B3D),
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
        width: 38, // From Figma layout_HOK07J
        height: 19,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF56CD54) : const Color(0xFFE5E5E5), // From Figma fill_1CSDFR
          borderRadius: BorderRadius.circular(19),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 13, // From Figma layout_JPDH6C
            height: 13,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
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
        width: 213, // From Figma layout_BWQ90V
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF130160), // From Figma fill_IGCJZ6
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withOpacity(0.18), // From Figma effect_20ABQ0
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
                    fontFamily: 'DM Sans', // From Figma style_ZWMF8N
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.302,
                    letterSpacing: 0.84,
                    color: AppColors.white, // From Figma fill_ROSM8H
                  ),
                ),
        ),
      ),
    );
  }

  // Navigate to onboarding to complete profile
  Future<void> _navigateToCompleteProfile() async {
    try {
      String? role = await AuthService.getUserRole();
      String route = role == 'employer' 
        ? '/EMPLOYER-onboarding'
        : '/student-onboarding';
      
      if (mounted) {
        await Navigator.pushNamed(context, route);
        // Reload profile completion status after returning
        _loadProfileCompletionStatus();
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _showLogoutConfirmation() async {
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
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white, // From Figma fill_RCMW2W
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }

  IconData _getDefaultIcon(String title) {
    switch (title.toLowerCase()) {
      case 'notifications':
        return Icons.notifications_outlined;
      case 'dark mode':
        return Icons.dark_mode_outlined;
      case 'complete profile':
        return Icons.person_outline;
      case 'password':
        return Icons.lock_outline;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.settings;
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate saving settings
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        _showSuccessSnackBar('Settings saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving settings: $e');
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
      // Clear Firestore listeners before sign out
      try {
        final applicantProvider = Provider.of<ApplicantProvider>(context, listen: false);
        final statusProvider = Provider.of<ApplicantStatusProvider>(context, listen: false);
        applicantProvider.clearData();
        statusProvider.clearAllCache();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('⚠️ Warning: Error cleaning up listeners: $e');
      }
      
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error logging out: $e');
      }
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature functionality will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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