import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/emp_analytics.dart';
import 'package:get_work_app/screens/main/employye/emp_profile.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/screens/main/employye/emp_chats.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/routes/routes.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _companyInfo;
  bool _isLoading = true;

  final List<Widget> _pages = [
    DashboardPage(),
    const EmpChats(),
    const EmpAnalytics(),
    const EmpProfile(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      final companyInfo = await AuthService.getEmployeeCompanyInfo();

      if (mounted) {
        setState(() {
          _userData = userData;
          _companyInfo = companyInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          'Failed to load user data: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primaryBlue,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar('Failed to logout: ${e.toString()}', isError: true);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.whiteText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigationBar(),
      endDrawer: _buildEndDrawer(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueShadow,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with greeting and icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: AppColors.whiteText.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData?['fullName'] ?? 'User',
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Notification icon with badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.whiteText.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.whiteText,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Menu button
                  Builder(
                    builder:
                        (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openEndDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.glassWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.whiteText.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.menu,
                              color: AppColors.whiteText,
                              size: 24,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      backgroundColor: AppColors.cardBackground,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          // Header with company logo and user info
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 32,
            ),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.whiteText,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      _companyInfo?['companyLogo'] != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              _companyInfo!['companyLogo'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultCompanyLogo();
                              },
                            ),
                          )
                          : _buildDefaultCompanyLogo(),
                ),
                const SizedBox(height: 20),
                // User name
                Text(
                  _userData?['fullName'] ?? 'User',
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Company name
                Text(
                  _companyInfo?['companyName'] ?? 'Company Name',
                  style: TextStyle(
                    color: AppColors.whiteText.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    isSelected: _selectedIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.chat,
                    title: 'Messages',
                    isSelected: _selectedIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    isSelected: _selectedIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    isSelected: _selectedIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    height: 1,
                    color: AppColors.dividerColor,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to help
                    },
                  ),
                ],
              ),
            ),
          ),
          // Logout button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
                icon: const Icon(Icons.logout, color: AppColors.whiteText),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.whiteText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCompanyLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue.withOpacity(0.1), AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          (_companyInfo?['companyName'] ?? 'C').substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.lightBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryBlue : AppColors.grey,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.primaryText,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _companyInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      final companyInfo = await AuthService.getEmployeeCompanyInfo();

      if (mounted) {
        setState(() {
          _userData = userData;
          _companyInfo = companyInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

Widget _buildTopBar(String userName) {
  return Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      bottom: 20,
    ),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.blueShadow,
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                color: AppColors.whiteText.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName, // Use the passed userName
              style: const TextStyle(
                color: AppColors.whiteText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
          Row(
            children: [
              // Notification icon with badge
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.whiteText.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.whiteText,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: AppColors.whiteText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Menu button
              Builder(
                builder:
                    (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openEndDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.whiteText.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.menu,
                          color: AppColors.whiteText,
                          size: 24,
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      final userName = _userData?['fullName'] ?? 'User';
  final companyName = _companyInfo?['companyName'] ?? 'Company Name';

    return Column(
      children: [
        _buildTopBar(userName),
        // Dashboard Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Overview
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Overview',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Employees',
                              '24',
                              Icons.people,
                              AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatItem(
                              'Active Projects',
                              '8',
                              Icons.work,
                              AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  children: [
                    _buildDashboardCard(
                      title: 'Messages',
                      subtitle: '12 unread',
                      icon: Icons.chat,
                      color: AppColors.warning,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning.withOpacity(0.1),
                          AppColors.warningLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _buildDashboardCard(
                      title: 'Tasks',
                      subtitle: '5 pending',
                      icon: Icons.task,
                      color: AppColors.success,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withOpacity(0.1),
                          AppColors.successLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _buildDashboardCard(
                      title: 'Reports',
                      subtitle: 'View analytics',
                      icon: Icons.analytics,
                      color: AppColors.primaryBlue,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.1),
                          AppColors.lightBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    _buildDashboardCard(
                      title: 'Settings',
                      subtitle: 'Manage account',
                      icon: Icons.settings,
                      color: AppColors.grey,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.grey.withOpacity(0.1),
                          AppColors.lightGrey,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Activity
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem(
                        'New employee John joined the team',
                        '2 hours ago',
                        Icons.person_add,
                        AppColors.success,
                      ),
                      _buildActivityItem(
                        'Project Alpha milestone completed',
                        '1 day ago',
                        Icons.check_circle,
                        AppColors.primaryBlue,
                      ),
                      _buildActivityItem(
                        'Monthly report generated',
                        '2 days ago',
                        Icons.description,
                        AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.hintText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
