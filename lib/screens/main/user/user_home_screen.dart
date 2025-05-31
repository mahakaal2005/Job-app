import 'package:flutter/material.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/user/user_chats.dart';
import 'package:get_work_app/screens/main/user/user_my_gigs.dart';
import 'package:get_work_app/screens/main/user/user_profile.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with TickerProviderStateMixin {
  String _userName = '';
  bool _isLoading = true;
  int _currentIndex = 0;
  String _selectedFilter = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Enhanced job data with better visuals
  final List<Map<String, dynamic>> _jobListings = [
    {
      'id': 1,
      'title': 'Senior Data Analyst',
      'employer': 'TechCorp Solutions',
      'logo': Icons.analytics_outlined,
      'hourlyRate': 1500,
      'distance': 2.3,
      'badges': ['Remote', 'Full-time', 'Urgent'],
      'type': 'full-time',
      'duration': '8 hours',
      'color': AppColors.primaryBlue,
      'rating': 4.8,
      'applications': 12,
    },
    {
      'id': 2,
      'title': 'UI/UX Designer',
      'employer': 'Creative Studio',
      'logo': Icons.design_services_outlined,
      'hourlyRate': 1200,
      'distance': 1.8,
      'badges': ['Design', 'Creative', 'Portfolio'],
      'type': 'contract',
      'duration': '6 hours',
      'color': AppColors.neonBlue,
      'rating': 4.9,
      'applications': 8,
    },
    {
      'id': 3,
      'title': 'Content Strategist',
      'employer': 'Digital Agency',
      'logo': Icons.edit_outlined,
      'hourlyRate': 1800,
      'distance': 3.1,
      'badges': ['Writing', 'Strategy', 'Remote'],
      'type': 'freelance',
      'duration': '4 hours',
      'color': AppColors.darkBlue,
      'rating': 4.7,
      'applications': 15,
    },
    {
      'id': 4,
      'title': 'Mobile Developer',
      'employer': 'StartupTech',
      'logo': Icons.phone_android_outlined,
      'hourlyRate': 2000,
      'distance': 0.8,
      'badges': ['Flutter', 'React Native', 'Full-time'],
      'type': 'permanent',
      'duration': '8 hours',
      'color': AppColors.accentBlue,
      'rating': 4.6,
      'applications': 25,
    },
  ];

  final List<String> _filterOptions = [
    'All',
    'Nearby',
    'High Pay',
    'Remote',
    'Urgent',
  ];

  // Enhanced notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Job Match Found!',
      'message': 'Perfect Senior Data Analyst role matches your profile',
      'time': '5 min ago',
      'isRead': false,
      'type': 'match',
      'icon': Icons.work_outline,
    },
    {
      'id': 2,
      'title': 'Application Update',
      'message': 'Your UI/UX Designer application is under review',
      'time': '2 hours ago',
      'isRead': false,
      'type': 'update',
      'icon': Icons.update,
    },
    {
      'id': 3,
      'title': 'Payment Received',
      'message': 'You received ₹15,000 for completed project',
      'time': '1 day ago',
      'isRead': true,
      'type': 'payment',
      'icon': Icons.payment,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _userName = userData['fullName'] ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.white,
          elevation: 20,
          shadowColor: AppColors.shadowMedium,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Are you sure you want to sign out of your account?',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text('Successfully signed out', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: AppColors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Error signing out: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      elevation: 16,
      shadowColor: AppColors.shadowMedium,
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.25, // Responsive height
            decoration: BoxDecoration(
              gradient: AppColors.blackGradient,
              borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.09, // Responsive size
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.07, // Responsive
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _userName,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.05, // Responsive
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Job Seeker',
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: MediaQuery.of(context).size.width * 0.03, // Responsive
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.work_outline_rounded,
                  title: 'My Applications',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Saved Jobs',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.payment_rounded,
                  title: 'Payment History',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => Navigator.pop(context),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: AppColors.dividerColor, thickness: 1),
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primaryBlue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primaryBlue,
            size: MediaQuery.of(context).size.width * 0.05, // Responsive
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.black,
            fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildNotificationDropdown() {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    
    return PopupMenuButton<int>(
      icon: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size: MediaQuery.of(context).size.width * 0.06, // Responsive
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.4),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$unreadCount',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.025, // Responsive
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: Offset(-100, 50),
      elevation: 20,
      shadowColor: AppColors.shadowMedium,
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            value: -1,
            enabled: false,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8, // Responsive width
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.045, // Responsive
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: AppColors.lightBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.03, // Responsive
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ..._notifications.map((notification) {
            return PopupMenuItem<int>(
              value: notification['id'],
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8, // Responsive width
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        notification['icon'],
                        color: AppColors.primaryBlue,
                        size: MediaQuery.of(context).size.width * 0.045, // Responsive
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                    fontWeight: notification['isRead'] 
                                        ? FontWeight.w500 
                                        : FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              if (!notification['isRead'])
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.02, // Responsive
                                  height: MediaQuery.of(context).size.width * 0.02, // Responsive
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            notification['message'],
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.032, // Responsive
                              color: AppColors.secondaryText,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            notification['time'],
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.03, // Responsive
                              color: AppColors.hintText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ];
      },
    );
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05, // Responsive
            vertical: 16,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive
                            color: AppColors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _userName.split(' ').first,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.07, // Responsive
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildNotificationDropdown(),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_rounded, 
                            color: AppColors.white, 
                            size: MediaQuery.of(context).size.width * 0.06, // Responsive
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.07, 
      padding: EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04), 
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.03), // Responsive
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04, // Responsive
                  vertical: MediaQuery.of(context).size.height * 0.01, // Responsive
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.dividerColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? AppColors.blueShadow.withOpacity(0.3)
                          : AppColors.shadowLight,
                      blurRadius: isSelected ? 8 : 4,
                      offset: Offset(0, isSelected ? 4 : 2),
                    ),
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.secondaryText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04, // Responsive
        vertical: 8,
      ),
      child: Card(
        elevation: 8,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            // Navigate to job detail screen
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.white,
                  AppColors.white.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04), // Responsive
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              job['color'].withOpacity(0.1),
                              job['color'].withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: job['color'].withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          job['logo'],
                          color: job['color'],
                          size: MediaQuery.of(context).size.width * 0.06, // Responsive
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03), // Responsive
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['title'],
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.045, // Responsive
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              job['employer'],
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, 
                                     color: AppColors.warning, 
                                     size: MediaQuery.of(context).size.width * 0.04), // Responsive
                                SizedBox(width: 4),
                                Text(
                                  '${job['rating']}',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.people_outline_rounded, 
                                     color: AppColors.hintText, 
                                     size: MediaQuery.of(context).size.width * 0.04), // Responsive
                                SizedBox(width: 4),
                                Text(
                                  '${job['applications']} applied',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                    color: AppColors.hintText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.03, // Responsive
                              vertical: MediaQuery.of(context).size.height * 0.01, // Responsive
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              '₹${job['hourlyRate']}/hr',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded, 
                                   size: MediaQuery.of(context).size.width * 0.035, // Responsive
                                   color: AppColors.hintText),
                              SizedBox(width: 4),
                              Text(
                                '${job['distance']} km',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.032, // Responsive
                                  color: AppColors.hintText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job['badges'].map<Widget>((badge) {
                      final isUrgent = badge.toLowerCase() == 'urgent';
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.03, // Responsive
                          vertical: MediaQuery.of(context).size.height * 0.01, // Responsive
                        ),
                        decoration: BoxDecoration(
                          gradient: isUrgent
                              ? LinearGradient(
                                  colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                                )
                              : LinearGradient(
                                  colors: [
                                    job['color'].withOpacity(0.1),
                                    job['color'].withOpacity(0.05),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isUrgent 
                                ? AppColors.error.withOpacity(0.3)
                                : job['color'].withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.032, // Responsive
                            color: isUrgent ? AppColors.white : job['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, 
                                 size: MediaQuery.of(context).size.width * 0.04, // Responsive
                                 color: AppColors.hintText),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                job['duration'],
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.work_outline_rounded, 
                                 size: MediaQuery.of(context).size.width * 0.04, // Responsive
                                 color: AppColors.hintText),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                job['type'],
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blueShadow.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to job details
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.04, // Responsive
                              vertical: MediaQuery.of(context).size.height * 0.015, // Responsive
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Apply Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, 
                                   size: MediaQuery.of(context).size.width * 0.04), // Responsive
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobsScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildModernHeader(),
          _buildFilterChips(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 8, bottom: 20),
              itemCount: _jobListings.length,
              itemBuilder: (context, index) {
                return _buildJobCard(_jobListings[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildJobsScreen();
      case 1:
        return MyGigsScreen();
      case 2:
        return ChatScreen();
      case 3:
        return ProfileScreen();
      default:
        return _buildJobsScreen();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.hintText,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 0 ? Icons.work_rounded : Icons.work_outline_rounded,
                  size: 24,
                ),
              ),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 1 ? Icons.assignment_rounded : Icons.assignment_outlined,
                  size: 24,
                ),
              ),
              label: 'My Gigs',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 2 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                  size: 24,
                ),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded,
                  size: 24,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blueShadow,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Loading your opportunities...',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundColor,
      endDrawer: _buildDrawer(),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}