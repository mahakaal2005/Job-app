import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/provider/applicant_provider.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employer/applicants/all_applicants_screen.dart';
import 'package:get_work_app/screens/main/employer/emp_analytics.dart';
import 'package:get_work_app/screens/main/employer/emp_chats.dart';
import 'package:get_work_app/screens/main/employer/emp_profile.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/employer/new%20post/job_services.dart';
import 'package:get_work_app/screens/main/employer/new%20post/recent_jobs.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/services/chat_service.dart';
import 'package:get_work_app/services/profile_gating_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  int _currentIndex = 0; // Changed from _selectedIndex for consistency
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _companyInfo;
  bool _isLoading = true;
  List<Job> _jobs = [];

  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      Provider.of<JobProvider>(context, listen: false).loadJobs();
    });
  }

  Future<void> _initializeData() async {
    try {
      // Load user data first (needed for company info)
      await _loadUserData();

      // Then load jobs (applicants loading temporarily disabled to prevent hang)
      await _loadJobs();

      // TODO: Fix _loadRecentApplicants() - currently causes app to hang
      // await _loadRecentApplicants();
    } catch (e) {
      print('âŒ ERROR initializing EMPLOYER dashboard: $e');
      if (mounted) {
        _showSnackBar(
          'Failed to load dashboard data: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    print('🔵 [EMPLOYER_HOME] _loadUserData() called');
    try {
      print('🔵 [EMPLOYER_HOME] Fetching user data from AuthService...');
      final userData = await AuthService.getUserData();
      print('✅ [EMPLOYER_HOME] User data fetched: ${userData?['fullName'] ?? 'No name'}');
      
      print('🔵 [EMPLOYER_HOME] Fetching company info from AuthService...');
      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();
      print('✅ [EMPLOYER_HOME] Company info fetched: ${companyInfo != null ? "Company: ${companyInfo['companyName'] ?? 'No name'}" : "NULL - User likely skipped onboarding"}');

      if (mounted) {
        setState(() {
          _userData = userData;
          _companyInfo = companyInfo;
          _isLoading = false;
        });
        print('✅ [EMPLOYER_HOME] State updated, _isLoading = false');
        print('📊 [EMPLOYER_HOME] _userData is ${_userData != null ? "NOT NULL" : "NULL"}');
        print('📊 [EMPLOYER_HOME] _companyInfo is ${_companyInfo != null ? "NOT NULL" : "NULL"}');
      } else {
        print('⚠️ [EMPLOYER_HOME] Widget not mounted, skipping state update');
      }
    } catch (e) {
      print('❌ [EMPLOYER_HOME] Error in _loadUserData: $e');
      print('❌ [EMPLOYER_HOME] Stack trace: ${StackTrace.current}');
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
    print('🔵 [EMPLOYER_HOME] _loadJobs() called');
    try {
      final jobs = await JobService.getCompanyJobs();
      print('✅ [EMPLOYER_HOME] Jobs loaded: ${jobs.length} jobs found');
      if (mounted) {
        setState(() {
          _jobs = jobs;
        });
      }
    } catch (e) {
      print('❌ [EMPLOYER_HOME] Error loading jobs: $e');
      if (mounted) {
        // Don't show error for missing company info - this is expected when profile is incomplete
        if (!e.toString().contains('Company profile must be completed')) {
          _showSnackBar('Failed to load jobs: ${e.toString()}', isError: true);
        }
        // Set empty jobs list
        setState(() {
          _jobs = [];
        });
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

      // Note: _recentApplicants removed as it was unused
    } catch (e) {
      print('Error loading recent applicants: $e');
    }
  }

  void _handleStatusChange(String jobId, bool newStatus) {
    if (!mounted) return;
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
      // CRITICAL: Clear all Firestore listeners BEFORE signing out
      // This prevents crashes from active listeners trying to reconnect after auth invalidation
      try {
        final applicantProvider = Provider.of<ApplicantProvider>(context, listen: false);
        final statusProvider = Provider.of<ApplicantStatusProvider>(context, listen: false);
        
        print('ðŸ§¹ Cleaning up Firestore listeners before sign out...');
        applicantProvider.clearData();
        statusProvider.clearAllCache();
        print('âœ… Listeners cleaned up successfully');
      } catch (e) {
        print('âš ï¸ Warning: Error cleaning up listeners: $e');
        // Continue with sign out even if cleanup fails
      }
      
      // Increased delay to ensure all Firestore listeners are fully cancelled
      // This prevents permission-denied errors from orphaned listeners
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Now safe to sign out
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
    print('🏗️ [EMPLOYER_HOME] build() called');
    print('📊 [EMPLOYER_HOME] _isLoading = $_isLoading');
    print('📊 [EMPLOYER_HOME] _userData = ${_userData != null ? "NOT NULL" : "NULL"}');
    print('📊 [EMPLOYER_HOME] _companyInfo = ${_companyInfo != null ? "NOT NULL" : "NULL"}');
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      print('🔄 [EMPLOYER_HOME] Showing loading spinner');
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      );
    }

    print('🏗️ [EMPLOYER_HOME] Building main scaffold with _buildBody()');
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          // Handle center button navigation
          if (index == 2) {
            // Check profile completion before allowing job creation
            final canCreate = await ProfileGatingService.canPerformAction(
              context,
              actionName: 'create job',
            );
            
            if (canCreate && context.mounted) {
              Navigator.pushNamed(context, AppRoutes.createJobOpening).then((result) {
                if (result == true) {
                  // Reload jobs when returning from job creation
                  _loadJobs();
                }
              });
            }
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        userType: 'employer',
      ),
      endDrawer: _buildEndDrawer(screenHeight, screenWidth),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return DashboardPage(
          jobs: _jobs,
          onStatusChanged: _handleStatusChange,
          onIndexChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          onLogout: _showLogoutDialog,
          onRefresh: _loadJobs,
        );
      case 1:
        return const Center(
          child: Text(
            'Search/Connection - Coming Soon',
            style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
          ),
        );
      case 3:
        return const EmpChats();
      case 4:
        return const EmpAnalytics();
      default:
        return DashboardPage(
          jobs: _jobs,
          onStatusChanged: _handleStatusChange,
          onIndexChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          onLogout: _showLogoutDialog,
          onRefresh: _loadJobs,
        );
    }
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
                  // Show different text based on whether company info exists
                  if (_companyInfo != null && _companyInfo?['companyName'] != null)
                    Text(
                      _companyInfo!['companyName'],
                      style: TextStyle(
                        color: AppColors.whiteText.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.whiteText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Profile Incomplete',
                            style: TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.chat,
                      title: 'Messages',
                      isSelected: _currentIndex == 3,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentIndex = 3;
                        });
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.analytics,
                      title: 'Analytics',
                      isSelected: _currentIndex == 4,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentIndex = 4;
                        });
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Profile',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmpProfile(),
                          ),
                        );
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
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Check profile completion before allowing job posting
                        final canPost = await ProfileGatingService.canPerformAction(
                          context,
                          actionName: 'post a job',
                        );
                        
                        if (canPost && context.mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.createJobOpening,
                          ).then((result) {
                            if (result == true) {
                              // Reload jobs when returning from job creation
                              _loadJobs();
                            }
                          });
                        }
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
  final Future<void> Function() onRefresh;

  const DashboardPage({
    super.key,
    required this.jobs,
    required this.onStatusChanged,
    required this.onIndexChanged,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ChatService _chatService = ChatService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _companyInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadRecentApplicants();
    });
  }

  Future<void> _loadUserData() async {
    print('🔵 [DASHBOARD_PAGE] _loadUserData() called');
    try {
      final userData = await AuthService.getUserData();
      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();
      
      print('📊 [DASHBOARD_PAGE] Company info: ${companyInfo != null ? "EXISTS" : "NULL"}');

      if (mounted) {
        setState(() {
          _userData = userData;
          _companyInfo = companyInfo;
          _isLoading = false;
        });
        print('✅ [DASHBOARD_PAGE] State updated');
      }
    } catch (e) {
      print('❌ [DASHBOARD_PAGE] Error loading user data: $e');
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
    print('🔵 [DASHBOARD_PAGE] _loadRecentApplicants() called');
    
    // Skip if company info is not available (user skipped onboarding)
    if (_companyInfo == null || 
        _companyInfo?['companyName'] == null || 
        _companyInfo!['companyName'].toString().trim().isEmpty) {
      print('⚠️ [DASHBOARD_PAGE] Skipping applicants load - company info not available or empty');
      return;
    }
    
    try {
      final List<Map<String, dynamic>> allApplicants = [];

      // Get all jobs for the company
      print('🔵 [DASHBOARD_PAGE] Fetching jobs for company: ${_companyInfo?['companyName']}');
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

      // Note: _recentApplicants removed as it was unused
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
    print('🏗️ [DASHBOARD_HEADER] Building header');
    print('📊 [DASHBOARD_HEADER] _userData: ${_userData?['fullName'] ?? "NULL"}');
    print('📊 [DASHBOARD_HEADER] _companyInfo: ${_companyInfo?['companyName'] ?? "NULL"}');
    
    return Builder(
      builder:
          (context) => Container(
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
                      AppColors.gigAppProfileGradientStart,
                      AppColors.gigAppProfileGradientEnd,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 27,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child:
                                      _companyInfo?['companyLogo'] != null &&
                                              _companyInfo!['companyLogo']
                                                  .toString()
                                                  .isNotEmpty
                                          ? Image.network(
                                            _companyInfo!['companyLogo'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return _buildDefaultLogo();
                                            },
                                          )
                                          : _buildDefaultLogo(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _userData?['fullName']
                                              ?.split(' ')
                                              .first ??
                                          'User',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                        fontFamily: 'DM Sans',
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
                            // Navigate to EMPLOYER profile
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmpProfile(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gigAppPurple.withOpacity(0.1),
            AppColors.gigAppPurple.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          (_companyInfo?['companyName'] ?? 'C').substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.gigAppPurple,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ [DASHBOARD_PAGE] build() called');
    print('📊 [DASHBOARD_PAGE] _isLoading = $_isLoading');
    print('📊 [DASHBOARD_PAGE] _companyInfo = ${_companyInfo != null ? "NOT NULL" : "NULL"}');
    
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
                      childAspectRatio: screenWidth < 600 ? 1.1 : 1.0,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Check profile completion before allowing job posting
                            final canPost = await ProfileGatingService.canPerformAction(
                              context,
                              actionName: 'post a job',
                            );
                            
                            if (canPost && context.mounted) {
                              final result = await Navigator.pushNamed(
                                context,
                                AppRoutes.createJobOpening,
                              );
                              
                              if (result == true && mounted) {
                                // Reload jobs when returning from job creation
                                await widget.onRefresh();
                              }
                            }
                          },
                          child: _buildDashboardCard(
                            title: 'Create Job',
                            count: widget.jobs.length.toString(),
                            icon: Icons.work_outline,
                            backgroundColor: const Color(0xFFB2F5EA),
                          ),
                        ),
                        StreamBuilder<int>(
                          stream: _chatService.getTotalUnreadCount(),
                          builder: (context, snapshot) {
                            // Handle different stream states
                            if (snapshot.hasError) {
                              debugPrint('âŒ Error loading unread count: ${snapshot.error}');
                            }
                            
                            // Use data if available, otherwise show 0
                            final unreadCount = snapshot.hasData ? snapshot.data! : 0;
                            
                            return GestureDetector(
                              onTap: () => widget.onIndexChanged(3),
                              child: _buildDashboardCard(
                                title: 'Messages',
                                count: unreadCount.toString(),
                                icon: Icons.chat_bubble_outline,
                                backgroundColor: const Color(0xFFFFD6AD),
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () => widget.onIndexChanged(4),
                          child: _buildDashboardCard(
                            title: 'Reports',
                            count: widget.jobs.length.toString(),
                            icon: Icons.bar_chart_rounded,
                            backgroundColor: const Color(0xFFBEAFFE),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmpProfile(),
                              ),
                            );
                          },
                          child: _buildDashboardCard(
                            title: 'Profile',
                            count:
                                _companyInfo?['companyName'] != null
                                    ? _companyInfo!['companyName']
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase() +
                                        _companyInfo!['companyName']
                                            .toString()
                                            .substring(1, 2)
                                    : 'Co',
                            icon: Icons.person_outline,
                            backgroundColor: const Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Only show applicants card if company info is available
                    if (_companyInfo != null && _companyInfo?['companyName'] != null && _companyInfo!['companyName'].toString().trim().isNotEmpty)
                      AllApplicantsNavigationCard(
                        companyName: _companyInfo!['companyName'],
                      )
                    else
                      _buildPlaceholderCard(
                        title: 'View All Applicants',
                        subtitle: 'Complete your profile to view applicants',
                        icon: Icons.people_outline,
                        onTap: () async {
                          final canView = await ProfileGatingService.canPerformAction(
                            context,
                            actionName: 'view applicants',
                          );
                          // ProfileGatingService will handle navigation to onboarding if needed
                        },
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
    required String count,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0140).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF0D0140)),
          ),
          const SizedBox(height: 16),
          // Count
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D0140),
              fontFamily: 'DM Sans',
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D0140),
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gigAppPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Complete Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
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
              AppColors.gigAppPurple,
              AppColors.gigAppProfileGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gigAppPurple.withOpacity(0.3),
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
