import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/widgets/ios_floating_bottom_nav.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employye/applicants/all_applicants_screen.dart';
import 'package:get_work_app/screens/main/employye/emp_analytics.dart';
import 'package:get_work_app/screens/main/employye/emp_chats.dart';
import 'package:get_work_app/screens/main/employye/emp_profile.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';
import 'package:get_work_app/screens/main/employye/new%20post/recent_jobs.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/glassmorphism_utils.dart';

import 'package:provider/provider.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _companyInfo;
  bool _isLoading = true;
  List<Job> _jobs = [];

  // Controllers for iOS-style navigation
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadJobs();
    _loadRecentApplicants();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> _loadJobs() async {
    try {
      final jobs = await JobService.getCompanyJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load jobs: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _loadRecentApplicants() async {
    try {
      final List<Map<String, dynamic>> allApplicants = [];

      // Get all jobs for the company
      final jobsSnapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(_companyInfo?['companyName'])
              .collection('jobPostings')
              .get();

      // Get applicants from each job
      for (var job in jobsSnapshot.docs) {
        final applicantsSnapshot =
            await FirebaseFirestore.instance
                .collection('jobs')
                .doc(_companyInfo?['companyName'])
                .collection('jobPostings')
                .doc(job.id)
                .collection('applicants')
                .orderBy('appliedAt', descending: true)
                .get();

        for (var doc in applicantsSnapshot.docs) {
          allApplicants.add({
            ...doc.data(),
            'id': doc.id,
            'jobId': job.id,
            'jobTitle': job['title'],
          });
        }
      }

      // Sort all applicants by application date (most recent first)
      allApplicants.sort((a, b) {
        final aDate = DateTime.parse(a['appliedAt']);
        final bDate = DateTime.parse(b['appliedAt']);
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      print('Error loading recent applicants: $e');
    }
  }

  void _handleStatusChange(String jobId, bool newStatus) {
    setState(() {
      _jobs =
          _jobs.map((job) {
            if (job.id == jobId) {
              return job.copyWith(isActive: newStatus);
            }
            return job;
          }).toList();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryAccent,
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
          backgroundColor: AppColors.surface,
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DashboardPage(
            jobs: _jobs,
            onStatusChanged: _handleStatusChange,
            onIndexChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            onLogout: _showLogoutDialog,
          ),
          const EmpChats(),
          const EmpAnalytics(),
          const EmpProfile(),
        ],
      ),
      extendBody: true, // IMPORTANT: This makes the body extend behind the floating bar
      bottomNavigationBar: IOSFloatingBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        items: const [
          IOSBottomNavItem(
            activeIcon: EvaIcons.grid,
            inactiveIcon: EvaIcons.gridOutline,
            label: 'Dashboard',
          ),
          IOSBottomNavItem(
            activeIcon: EvaIcons.messageCircle,
            inactiveIcon: EvaIcons.messageCircleOutline,
            label: 'Chats',
          ),
          IOSBottomNavItem(
            activeIcon: EvaIcons.barChart2,
            inactiveIcon: EvaIcons.barChart2Outline,
            label: 'Analytics',
          ),
          IOSBottomNavItem(
            activeIcon: EvaIcons.person,
            inactiveIcon: EvaIcons.personOutline,
            label: 'Profile',
          ),
        ],
      ),
      endDrawer: _buildPortfolioDrawer(screenHeight, screenWidth),
    );
  }

  Widget _buildPortfolioDrawer(double screenHeight, double screenWidth) {
    return Drawer(
      backgroundColor: Colors.transparent,
      width: screenWidth * 0.75,
      child: GlassmorphismUtils.glassDrawer(
        width: screenWidth * 0.75,
        child: SafeArea(
          child: Column(
            children: [
              // Portfolio-style header
              Container(
                margin: const EdgeInsets.all(20),
                child: GlassmorphismUtils.portfolioCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company logo with enhanced glass effect
                      GlassmorphismUtils.glassContainer(
                        width: 70,
                        height: 70,
                        borderRadius: 20,
                        backgroundColor: AppColors.glass25,
                        borderColor: AppColors.glassBorderStrong,
                        child:
                            _companyInfo?['companyLogo'] != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    _companyInfo!['companyLogo'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPortfolioCompanyLogo();
                                    },
                                  ),
                                )
                                : _buildPortfolioCompanyLogo(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userData?['fullName'] ?? 'User',
                        style: const TextStyle(
                          color: AppColors.glassWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _companyInfo?['companyName'] ?? 'Company Name',
                        style: const TextStyle(
                          color: AppColors.glassGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Menu items with portfolio styling
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildPortfolioDrawerItem(
                        icon: EvaIcons.grid,
                        title: 'Dashboard',
                        isSelected: _selectedIndex == 0,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                      ),
                      _buildPortfolioDrawerItem(
                        icon: EvaIcons.messageCircle,
                        title: 'Messages',
                        isSelected: _selectedIndex == 1,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                      _buildPortfolioDrawerItem(
                        icon: EvaIcons.barChart,
                        title: 'Analytics',
                        isSelected: _selectedIndex == 2,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedIndex = 2;
                          });
                        },
                      ),
                      _buildPortfolioDrawerItem(
                        icon: EvaIcons.person,
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
                        icon: Icons.work_outline,
                        title: 'Create Job Opening',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.createJobOpening,
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.helpSupport);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Portfolio-style logout button
              Container(
                margin: const EdgeInsets.all(20),
                child: GlassmorphismUtils.portfolioButton(
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                  backgroundColor: AppColors.errorGlass,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppColors.glassWhite, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.glassWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildPortfolioCompanyLogo() {
    return GlassmorphismUtils.glassContainer(
      backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.1),
      borderColor: AppColors.primaryAccent.withValues(alpha: 0.3),
      borderRadius: 20,
      child: Center(
        child: Text(
          (_companyInfo?['companyName'] ?? 'C').substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GlassmorphismUtils.portfolioButton(
        onTap: onTap,
        backgroundColor:
            isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.1)
                : AppColors.glass10,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryAccent : AppColors.glassGray,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primaryAccent : AppColors.glassWhite,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GlassmorphismUtils.portfolioButton(
        onTap: onTap,
        backgroundColor: AppColors.glass10,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.glassGray, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.glassWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassmorphismUtils.portfolioCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Profile avatar with glassmorphism
                    GlassmorphismUtils.glassContainer(
                      width: 44,
                      height: 44,
                      borderRadius: 14,
                      backgroundColor: AppColors.glass20,
                      borderColor: AppColors.glassBorder,
                      child:
                          _userData?['profilePicture'] != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _userData!['profilePicture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar();
                                  },
                                ),
                              )
                              : _buildDefaultAvatar(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Good ${_getGreeting()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.glassGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userData?['fullName']?.split(' ').first ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.glassWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Notification bell
                  GlassmorphismUtils.glassContainer(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: AppColors.glass15,
                    borderRadius: 14,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.glassGray,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Menu button
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: GlassmorphismUtils.glassContainer(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: AppColors.glass15,
                      borderRadius: 14,
                      child: Icon(
                        Icons.menu_rounded,
                        color: AppColors.glassGray,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return GlassmorphismUtils.glassContainer(
      backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.1),
      borderColor: AppColors.primaryAccent.withValues(alpha: 0.3),
      borderRadius: 14,
      child: Center(
        child: Text(
          (_userData?['fullName'] ?? 'U').substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class DashboardPage extends StatefulWidget {
  final List<Job> jobs;
  final Function(String, bool) onStatusChanged;
  final Function(int) onIndexChanged;
  final VoidCallback onLogout;

  const DashboardPage({
    super.key,
    required this.jobs,
    required this.onStatusChanged,
    required this.onIndexChanged,
    required this.onLogout,
  });

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
    _loadRecentApplicants();
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

  Future<void> _loadRecentApplicants() async {
    try {
      final List<Map<String, dynamic>> allApplicants = [];

      // Get all jobs for the company
      final jobsSnapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(_companyInfo?['companyName'])
              .collection('jobPostings')
              .get();

      // Get applicants from each job
      for (var job in jobsSnapshot.docs) {
        final applicantsSnapshot =
            await FirebaseFirestore.instance
                .collection('jobs')
                .doc(_companyInfo?['companyName'])
                .collection('jobPostings')
                .doc(job.id)
                .collection('applicants')
                .orderBy('appliedAt', descending: true)
                .get();

        for (var doc in applicantsSnapshot.docs) {
          allApplicants.add({
            ...doc.data(),
            'id': doc.id,
            'jobId': job.id,
            'jobTitle': job['title'],
          });
        }
      }

      // Sort all applicants by application date (most recent first)
      allApplicants.sort((a, b) {
        final aDate = DateTime.parse(a['appliedAt']);
        final bDate = DateTime.parse(b['appliedAt']);
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      print('Error loading recent applicants: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryAccent,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassmorphismUtils.portfolioCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Profile avatar with glassmorphism
                    GlassmorphismUtils.glassContainer(
                      width: 44,
                      height: 44,
                      borderRadius: 14,
                      backgroundColor: AppColors.glass20,
                      borderColor: AppColors.glassBorder,
                      child:
                          _userData?['profilePicture'] != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _userData!['profilePicture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar();
                                  },
                                ),
                              )
                              : _buildDefaultAvatar(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Good ${_getGreeting()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.glassGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userData?['fullName']?.split(' ').first ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.glassWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Notification bell
                  GlassmorphismUtils.glassContainer(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: AppColors.glass15,
                    borderRadius: 14,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.glassGray,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Menu button
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: GlassmorphismUtils.glassContainer(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: AppColors.glass15,
                      borderRadius: 14,
                      child: Icon(
                        Icons.menu_rounded,
                        color: AppColors.glassGray,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return GlassmorphismUtils.glassContainer(
      backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.1),
      borderColor: AppColors.primaryAccent.withValues(alpha: 0.3),
      borderRadius: 14,
      child: Center(
        child: Text(
          (_userData?['fullName'] ?? 'U').substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return _isLoading
        ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
        )
        : Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Portfolio Balance Card (like in reference image)
                    GlassmorphismUtils.portfolioStatCard(
                      title: 'Company Portfolio',
                      value:
                          '\$${(widget.jobs.length * 1500.0).toStringAsFixed(0)}',
                      subtitle: '+12.5% from last month',
                      icon: Icons.trending_up,
                      accentColor: AppColors.primaryAccent,
                    ),
                    const SizedBox(height: 20),

                    // Quick Action Buttons (Portfolio Style)
                    Row(
                      children: [
                        Expanded(
                          child: GlassmorphismUtils.portfolioButton(
                            onTap:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.createJobOpening,
                                ),
                            isPrimary: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Post Job',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassmorphismUtils.portfolioButton(
                            onTap: () => widget.onIndexChanged(1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppColors.glassWhite,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Messages',
                                  style: TextStyle(
                                    color: AppColors.glassWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Jobs Section
                    RecentJobsCard(
                      jobs: widget.jobs,
                      onSeeAllPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.allJobListings,
                          arguments: widget.jobs,
                        );
                      },
                      onStatusChanged: widget.onStatusChanged,
                    ),
                    const SizedBox(height: 24),

                    // Portfolio-style Stats Grid
                    GridView.count(
                      crossAxisCount: screenWidth < 600 ? 2 : 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: screenWidth < 600 ? 1.2 : 1.0,
                      children: [
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(2),
                          child: GlassmorphismUtils.portfolioStatCard(
                            title: 'Total Jobs',
                            value: '${widget.jobs.length}',
                            subtitle: 'Active positions',
                            icon: Icons.work_outline,
                            accentColor: AppColors.primaryAccent,
                            margin: const EdgeInsets.all(0),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(1),
                          child: GlassmorphismUtils.portfolioStatCard(
                            title: 'Messages',
                            value: '12',
                            subtitle: 'Unread chats',
                            icon: Icons.chat_bubble_outline,
                            accentColor: Colors.orange,
                            margin: const EdgeInsets.all(0),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(2),
                          child: GlassmorphismUtils.portfolioStatCard(
                            title: 'Analytics',
                            value: '89%',
                            subtitle: 'Success rate',
                            icon: Icons.trending_up,
                            accentColor: Colors.blue,
                            margin: const EdgeInsets.all(0),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(3),
                          child: GlassmorphismUtils.portfolioStatCard(
                            title: 'Profile',
                            value: '100%',
                            subtitle: 'Complete',
                            icon: Icons.person_outline,
                            accentColor: Colors.purple,
                            margin: const EdgeInsets.all(0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // All Applicants Card with Glassmorphism
                    GlassmorphismUtils.portfolioCard(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AllApplicantsScreen(
                                    jobId: '',
                                    companyName:
                                        _companyInfo?['companyName'] ?? '',
                                    jobTitle: 'All Jobs',
                                  ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              GlassmorphismUtils.glassContainer(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: AppColors.primaryAccent
                                    .withValues(alpha: 0.1),
                                borderColor: AppColors.primaryAccent.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: 16,
                                child: Icon(
                                  Icons.people_outline,
                                  color: AppColors.primaryAccent,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'View All Applicants',
                                      style: TextStyle(
                                        color: AppColors.glassWhite,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage and review job applications',
                                      style: TextStyle(
                                        color: AppColors.glassGray,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.glassGray,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }
}

class AllApplicantsNavigationCard extends StatelessWidget {
  final String companyName;

  const AllApplicantsNavigationCard({super.key, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AllApplicantsScreen(
                  jobId: '',
                  companyName: companyName,
                  jobTitle: 'All Jobs',
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryAccent,
              AppColors.primaryAccent.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.people_alt_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View All Applicants',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and review all job applications',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow Icon
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
