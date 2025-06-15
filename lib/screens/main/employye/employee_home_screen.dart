import 'package:flutter/material.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/screens/main/employye/emp_analytics.dart';
import 'package:get_work_app/screens/main/employye/emp_profile.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/recent_jobs.dart';
import 'package:get_work_app/screens/main/employye/applicants/all_applicants_screen.dart';
import 'package:get_work_app/screens/main/employye/applicants/applicant_details_screen.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/screens/main/employye/emp_chats.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  List<Job> _jobs = [];
  List<Map<String, dynamic>> _recentApplicants = [];

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

      // Return only the 3 most recent applicants
      setState(() {
        _recentApplicants = allApplicants.take(3).toList();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: IndexedStack(
        index: _selectedIndex,
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
      bottomNavigationBar: _buildBottomNavigationBar(),
      endDrawer: _buildEndDrawer(screenHeight, screenWidth),
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

  Widget _buildEndDrawer(double screenHeight, double screenWidth) {
    return Drawer(
      backgroundColor: AppColors.cardBackground,
      width: screenWidth * 0.75, // Reduced from 0.8 to prevent overflow
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: 32,
              ),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    _userData?['fullName'] ?? 'User',
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _companyInfo?['companyName'] ?? 'Company Name',
                    style: TextStyle(
                      color: AppColors.whiteText.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
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
  final List<Job> jobs;
  final Function(String, bool) onStatusChanged;
  final Function(int) onIndexChanged;
  final VoidCallback onLogout;

  const DashboardPage({
    Key? key,
    required this.jobs,
    required this.onStatusChanged,
    required this.onIndexChanged,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _companyInfo;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentApplicants = [];

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

      // Return only the 3 most recent applicants
      setState(() {
        _recentApplicants = allApplicants.take(3).toList();
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
        backgroundColor: isError ? AppColors.error : AppColors.primaryBlue,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder:
          (context) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x330066FF),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF0066FF),
                                  child: const Icon(
                                    Icons.work_rounded,
                                    color: AppColors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.035,
                                  color: AppColors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userData?['fullName']?.split(' ').first ??
                                    'User',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
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
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.menu_rounded,
                        color: AppColors.white,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userData?['fullName'] ?? 'User';
    final screenWidth = MediaQuery.of(context).size.width;

    return _isLoading
        ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
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
                    GridView.count(
                      crossAxisCount: screenWidth < 600 ? 2 : 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: screenWidth < 600 ? 1.2 : 1.0,
                      children: [
                        GestureDetector(
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.createJobOpening,
                              ),
                          child: _buildDashboardCard(
                            title: 'Create Job',
                            subtitle: 'Post new opening',
                            icon: Icons.work_outline,
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
                        ),
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(1),
                          child: _buildDashboardCard(
                            title: 'Messages',
                            subtitle: '12 unread',
                            icon: Icons.chat,
                            color: AppColors.warning,
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(
                                  255,
                                  255,
                                  212,
                                  126,
                                ).withOpacity(0.8),
                                const Color.fromARGB(255, 224, 183, 102),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(2),
                          child: _buildDashboardCard(
                            title: 'Reports',
                            subtitle: 'View analytics',
                            icon: Icons.bar_chart,
                            color: AppColors.success,
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(
                                  255,
                                  129,
                                  249,
                                  177,
                                ).withOpacity(0.8),
                                const Color.fromARGB(255, 132, 255, 181),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(3),
                          child: _buildDashboardCard(
                            title: 'Profile',
                            subtitle: 'Manage account',
                            icon: Icons.person_4_outlined,
                            color: AppColors.grey,
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(
                                  255,
                                  184,
                                  179,
                                  179,
                                ).withOpacity(0.8),
                                const Color.fromARGB(255, 144, 141, 141),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AllApplicantsNavigationCard(
                      companyName: _companyInfo?['companyName'] ?? '',
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Recently';

    final DateTime dateTime =
        timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.parse(timestamp.toString());

    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'shortlisted':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class AllApplicantsNavigationCard extends StatelessWidget {
  final String companyName;

  const AllApplicantsNavigationCard({Key? key, required this.companyName})
    : super(key: key);

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
              AppColors.primaryBlue,
              AppColors.primaryBlue.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.1),
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
                      color: Colors.white.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.9),
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
