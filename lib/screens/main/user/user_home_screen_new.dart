import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/provider/applicant_provider.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/user/applications/my_applications_screen.dart';
import 'package:get_work_app/screens/main/user/bookmarks_screen.dart';
import 'package:get_work_app/screens/main/user/jobs/bookmark_provider.dart';
import 'package:get_work_app/screens/main/user/jobs/filtered_jobs_screen.dart';
import 'package:get_work_app/screens/main/user/jobs/job_detail_screen_new.dart';
import 'package:get_work_app/screens/main/user/jobs/user_all_jobs_services.dart';
import 'package:get_work_app/screens/main/user/user_chats.dart';
import 'package:get_work_app/screens/main/user/user_help_and_support.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/number_formatter.dart';
import 'package:get_work_app/services/profile_gating_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/app_spacing.dart';
import 'package:get_work_app/utils/error_handler.dart';
import 'package:get_work_app/utils/image_utils.dart';
import 'package:get_work_app/utils/responsive.dart';
import 'package:get_work_app/widgets/custom_bottom_nav_bar.dart';
// import 'package:get_work_app/widgets/profile_completion_widget.dart';
import 'package:provider/provider.dart';

class UserHomeScreenNew extends StatefulWidget {
  const UserHomeScreenNew({super.key});

  @override
  State<UserHomeScreenNew> createState() => _UserHomeScreenNewState();
}

class _UserHomeScreenNewState extends State<UserHomeScreenNew>
    with TickerProviderStateMixin {
  // User data
  String? _userId;
  String _userName = 'User';
  String _userProfilePic = '';
  bool _isLoading = true;
  bool _isFirstLogin = false; // Track if this is user's first login

  // Navigation
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Job data with pagination
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoadingJobs = false;
  bool _hasMoreJobs = true;
  final int _jobsPerPage = 10;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  // Job statistics
  int _fullTimeJobsCount = 0;
  int _partTimeJobsCount = 0;
  int _remoteJobsCount = 0;

  // Filtered jobs view state
  bool _showingFilteredJobs = false;
  String _currentFilterType = '';
  String _currentFilterTitle = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    _scrollController.addListener(_scrollListener);
    _loadUserData();
    _loadJobStatistics();
    _loadJobs();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      if (!_isLoadingJobs && _hasMoreJobs) {
        _loadMoreJobs();
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Check if this is first login
      final isFirstLogin = await AuthService.isFirstLogin();
      
      final userData = await AuthService.getUserData();
      if (userData != null && mounted) {
        // Use 'profileImageUrl' - same field name as user_profile.dart
        final profilePic = userData['profileImageUrl'] ?? '';
        debugPrint('=== User Data Loaded ===');
        debugPrint('User Name: ${userData['fullName']}');
        debugPrint('Profile Image URL: $profilePic');
        debugPrint('Profile Image isEmpty: ${profilePic.isEmpty}');
        debugPrint('Is First Login: $isFirstLogin');
        debugPrint('=======================');

        setState(() {
          _userName = userData['fullName'] ?? 'User';
          _userId = userData['uid'];
          _userProfilePic = profilePic;
          _isFirstLogin = isFirstLogin;
          _isLoading = false;
        });

        // Update last login date after loading
        if (isFirstLogin) {
          // Small delay to ensure user sees the welcome message
          await Future.delayed(const Duration(milliseconds: 500));
          await AuthService.updateLastLoginDate();
          debugPrint('✅ First login date recorded');
        } else {
          // Update login date for returning users too
          await AuthService.updateLastLoginDate();
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoading = false;
          _isFirstLogin = false;
        });
      }
    }
  }

  Future<void> _loadJobStatistics() async {
    try {
      // Use Firestore count() aggregation for efficient counting
      // Note: These queries require Firestore indexes to be created

      // Count Full Time jobs
      final fullTimeQuery = _firestore
          .collectionGroup('jobPostings')
          .where('isActive', isEqualTo: true)
          .where('employmentType', isEqualTo: 'Full-time');

      // Count Part Time jobs
      final partTimeQuery = _firestore
          .collectionGroup('jobPostings')
          .where('isActive', isEqualTo: true)
          .where('employmentType', isEqualTo: 'Part-time');

      // Count Remote jobs
      final remoteQuery = _firestore
          .collectionGroup('jobPostings')
          .where('isActive', isEqualTo: true)
          .where('workFrom', isEqualTo: 'Remote');

      // Execute count aggregations in parallel
      final results = await Future.wait([
        fullTimeQuery.count().get(),
        partTimeQuery.count().get(),
        remoteQuery.count().get(),
      ]);

      if (mounted) {
        setState(() {
          _fullTimeJobsCount = results[0].count ?? 0;
          _partTimeJobsCount = results[1].count ?? 0;
          _remoteJobsCount = results[2].count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading job statistics: $e');

      // Check if it's an index error
      if (e.toString().contains('FAILED_PRECONDITION') ||
          e.toString().contains('requires an index')) {
        debugPrint('⚠️  FIRESTORE INDEXES REQUIRED ⚠️');
        debugPrint(
          'Please create the required Firestore indexes by clicking the URLs in the error messages above.',
        );
        debugPrint(
          'Once indexes are created, the statistics will load automatically.',
        );
      }

      // Fallback: Calculate from loaded jobs
      if (mounted && _jobs.isNotEmpty) {
        setState(() {
          _fullTimeJobsCount =
              _jobs.where((job) => job.employmentType == 'Full-time').length;
          _partTimeJobsCount =
              _jobs.where((job) => job.employmentType == 'Part-time').length;
          _remoteJobsCount =
              _jobs.where((job) => job.workFrom == 'Remote').length;
        });

        debugPrint(
          'Using fallback: Calculated statistics from ${_jobs.length} loaded jobs',
        );
      } else {
        // No jobs loaded yet, set to 0
        if (mounted) {
          setState(() {
            _fullTimeJobsCount = 0;
            _partTimeJobsCount = 0;
            _remoteJobsCount = 0;
          });
        }
      }
    }
  }

  Future<void> _loadJobs() async {
    if (_isLoadingJobs) return;

    setState(() {
      _isLoadingJobs = true;
      _lastDocument = null;
      _hasMoreJobs = true;
    });

    try {
      final jobs = await AllJobsService.getAllJobs(
        limit: _jobsPerPage,
        lastDocument: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _filteredJobs = jobs;
          _isLoadingJobs = false;
          _hasMoreJobs = jobs.length == _jobsPerPage;
          // Note: lastDocument is handled by AllJobsService
          _lastDocument = null;
        });

        // Reload statistics after jobs are loaded
        _loadJobStatistics();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _loadMoreJobs() async {
    if (_isLoadingJobs || !_hasMoreJobs) return;

    setState(() => _isLoadingJobs = true);

    try {
      final newJobs = await AllJobsService.getAllJobs(
        limit: _jobsPerPage,
        lastDocument: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _isLoadingJobs = false;
          if (newJobs.isNotEmpty) {
            _jobs.addAll(newJobs);
            _filteredJobs.addAll(newJobs);
            _hasMoreJobs = newJobs.length == _jobsPerPage;
            // Note: lastDocument is handled by AllJobsService
            _lastDocument = null;
          } else {
            _hasMoreJobs = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
      // Always reset filtered jobs view when tapping any bottom nav icon
      // This ensures clicking Home icon always shows the main home screen
      // regardless of where you navigated from
      _showingFilteredJobs = false;
    });
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.lookGigPurple,
                  AppColors.lookGigPurple.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.white,
                      child:
                          _userProfilePic.isNotEmpty
                              ? ClipOval(
                                child: ImageUtils.buildSafeNetworkImage(
                                  imageUrl: _userProfilePic,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorWidget: Text(
                                    _userName.isNotEmpty
                                        ? _userName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lookGigPurple,
                                    ),
                                  ),
                                ),
                              )
                              : Text(
                                _userName.isNotEmpty
                                    ? _userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lookGigPurple,
                                ),
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppColors.lookGigPurple,
                  ),
                  title: const Text('My Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.userProfile);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.bookmark_outline,
                    color: AppColors.lookGigPurple,
                  ),
                  title: const Text('Saved Jobs'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 4);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppColors.lookGigPurple,
                  ),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserHelpAndSupport(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    // Clear Firestore listeners before sign out
                    try {
                      final applicantProvider = Provider.of<ApplicantProvider>(
                        context,
                        listen: false,
                      );
                      final statusProvider =
                          Provider.of<ApplicantStatusProvider>(
                            context,
                            listen: false,
                          );
                      applicantProvider.clearData();
                      statusProvider.clearAllCache();
                      await Future.delayed(const Duration(milliseconds: 100));
                    } catch (e) {
                      print('⚠️ Warning: Error cleaning up listeners: $e');
                    }

                    await AuthService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.lookGigLightGray,
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildSearchScreen();
      case 2:
        return _buildAddScreen();
      case 3:
        return const UserChats();
      case 4:
        return BookmarksScreen(
          onNavigateToTab: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        );
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    // Show filtered jobs screen if flag is true
    if (_showingFilteredJobs) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            setState(() {
              _showingFilteredJobs = false;
            });
          }
        },
        child: FilteredJobsScreen(
          filterType: _currentFilterType,
          title: _currentFilterTitle,
          onBack: () {
            setState(() {
              _showingFilteredJobs = false;
            });
          },
        ),
      );
    }

    // Show normal home screen
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            // Removed crossAxisAlignment to center content properly
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildPromotionalBanner(),
              const SizedBox(height: 24),
              _buildFindYourJobSection(),
              const SizedBox(height: 16),
              _buildJobStatisticsCards(),
              const SizedBox(height: 24),
              _buildRecentJobsList(),
              if (_isLoadingJobs)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.fromLTRB(context, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Greeting - Left Side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isFirstLogin ? 'Welcome' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0140),
                    fontFamily: 'DM Sans',
                    height: 1.211,
                  ),
                ),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0140),
                    fontFamily: 'DM Sans',
                    height: 1.211,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Profile completion badge
                const SizedBox(height: 8),
                const SizedBox.shrink(), // Profile completion badge removed
              ],
            ),
          ),
          // Profile Picture - Right Side (navigates to profile)
          // Using CircleAvatar with backgroundImage - same approach as user_profile.dart
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.userProfile);
            },
            child: ImageUtils.buildSafeCircleAvatar(
              radius: 18, // 36px diameter
              imagePath: _userProfilePic,
              child:
                  _userProfilePic.isEmpty
                      ? Icon(Icons.person, color: AppColors.black, size: 20)
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerWidth = screenWidth * 0.9; // 90% of screen width
    final bannerHeight = bannerWidth * 0.55; // Maintain aspect ratio
    final blueBoxHeight = bannerHeight * 0.79; // 79% of banner height
    final blueBoxTop = bannerHeight * 0.21; // Start at 21% from top
    
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: SizedBox(
          width: bannerWidth,
          height: bannerHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bottom container layer - transparent background
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: bannerWidth,
                  height: bannerHeight,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Blue rectangle - CHANGED COLOR TO #2f51a7
              Positioned(
                left: 0,
                top: blueBoxTop,
                child: Container(
                  width: bannerWidth,
                  height: blueBoxHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2f51a7), // Changed from 0xFF130160
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Lady's photo - responsive positioning
              Positioned(
                left: bannerWidth * 0.486, // ~49% from left
                top: 0,
                child: Image.asset(
                  'assets/images/banner_lady.png',
                  width: bannerWidth * 0.656, // ~66% of banner width
                  height: bannerHeight * 1.066, // Slightly taller than banner
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: bannerWidth * 0.656,
                      height: bannerHeight * 1.066,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: bannerWidth * 0.24,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              // Text overlay - responsive positioning
              Positioned(
                left: bannerWidth * 0.052, // ~5% from left
                top: bannerHeight * 0.343, // ~34% from top
                child: SizedBox(
                  width: bannerWidth * 0.428, // ~43% of banner width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "50% off"
                      Text(
                        '50% off',
                        style: TextStyle(
                          fontSize: bannerWidth * 0.055, // Responsive font size
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFFFFFF),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                      // "take any courses"
                      Text(
                        'take any courses',
                        style: TextStyle(
                          fontSize: bannerWidth * 0.055, // Responsive font size
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFFFFFFF),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                      SizedBox(height: bannerHeight * 0.088),
                      // Button
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Course feature coming soon!'),
                            ),
                          );
                        },
                        child: Container(
                          width: bannerWidth * 0.274, // Responsive button width
                          height: bannerHeight * 0.144, // Responsive button height
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9228),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              'Join Now',
                              style: TextStyle(
                                fontSize: bannerWidth * 0.0395, // Responsive font size
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFFFFFFF),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                            ),
                          ),
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

  Widget _buildFindYourJobSection() {
    return Padding(
      padding: AppSpacing.horizontal(context),
      child: const Text(
        'Find Your Job',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
          fontFamily: 'DM Sans',
          height: 1.302,
        ),
      ),
    );
  }

  Widget _buildJobStatisticsCards() {
    return Padding(
      padding: AppSpacing.horizontal(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remote Job Card - Left (responsive width, 170px height)
          Expanded(
            flex: 48,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showingFilteredJobs = true;
                  _currentFilterType = 'Remote';
                  _currentFilterTitle = 'Remote Jobs';
                });
              },
              child: Container(
                // Removed fixed width for responsive layout
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFAFECFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Image.asset(
                    'assets/images/job_search_icon.png',
                    width: 34,
                    height: 34,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.work,
                        size: 34,
                        color: Color(0xFF0D0140),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // Count
                  Text(
                    _formatCount(_remoteJobsCount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D0140),
                      fontFamily: 'DM Sans',
                      height: 1.302,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label
                  const Text(
                    'Remote Job',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0D0140),
                      fontFamily: 'DM Sans',
                      height: 1.302,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          const SizedBox(width: 20),
          // Right Column with Full Time and Part Time (responsive width)
          Expanded(
            flex: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Time Card (responsive width, 75px height)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showingFilteredJobs = true;
                      _currentFilterType = 'Full-time';
                      _currentFilterTitle = 'Full Time Jobs';
                    });
                  },
                  child: Container(
                    // Removed fixed width for responsive layout
                    height: 75,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBEAFFE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Count
                      Text(
                        _formatCount(_fullTimeJobsCount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D0140),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Label
                      const Text(
                        'Full Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0D0140),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 20),
                // Part Time Card (responsive width, 75px height)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showingFilteredJobs = true;
                      _currentFilterType = 'Part-time';
                      _currentFilterTitle = 'Part Time Jobs';
                    });
                  },
                  child: Container(
                    // Removed fixed width for responsive layout
                    height: 75,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD6AD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Count
                      Text(
                        _formatCount(_partTimeJobsCount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D0140),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Label
                      const Text(
                        'Part Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0D0140),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                    ],
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

  Widget _buildRecentJobsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.horizontal(context),
          child: const Text(
            'Recent Job List',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF150B3D),
              fontFamily: 'DM Sans',
              height: 1.302,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_filteredJobs.isEmpty && !_isLoadingJobs)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No jobs available'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: AppSpacing.horizontal(context),
            itemCount: _filteredJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(_filteredJobs[index]);
            },
          ),
      ],
    );
  }

  Widget _buildJobCard(Job job) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final isBookmarked = bookmarkProvider.isBookmarked(job.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => JobDetailScreenNew(
                  job: job,
                  isBookmarked: isBookmarked,
                  onBookmarkToggled: (jobId) async {
                    final canBookmark = await ProfileGatingService.canPerformAction(
                      context,
                      actionName: 'bookmark this job',
                    );
                    if (canBookmark) {
                      bookmarkProvider.toggleBookmark(jobId);
                    }
                  },
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withOpacity(0.18),
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Company Logo - Circular
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(
                    0xFFE8E0FF,
                  ), // Light purple background
                  child:
                      job.companyLogo.isNotEmpty
                          ? ClipOval(
                            child: ImageUtils.buildSafeNetworkImage(
                              imageUrl: job.companyLogo,
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(
                                Icons.business,
                                size: 20,
                                color: Color(0xFF6B5CE7),
                              ),
                            ),
                          )
                          : const Icon(
                            Icons.business,
                            size: 20,
                            color: Color(0xFF6B5CE7),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF150B3D),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              job.companyName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF524B6B),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: const BoxDecoration(
                              color: Color(0xFF524B6B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            flex: 2,
                            child: Text(
                              job.location,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF524B6B),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 2,
                            height: 2,
                            decoration: const BoxDecoration(
                              color: Color(0xFF524B6B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            flex: 1,
                            child: Text(
                              _getTimeAgo(job.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF524B6B),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (_userId != null) {
                      final canBookmark = await ProfileGatingService.canPerformAction(
                        context,
                        actionName: 'bookmark this job',
                      );
                      if (canBookmark) {
                        bookmarkProvider.toggleBookmark(job.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBookmarked
                                  ? 'Bookmark removed'
                                  : 'Job bookmarked',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: const Color(0xFF524B6B),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormattedSalary(job.salaryRange, job.employmentType),
            const SizedBox(height: 12),
            Row(
              children: [
                if (job.experienceLevel.isNotEmpty) ...[
                  _buildJobTag(
                    context,
                    job.experienceLevel,
                    const Color(0xFFCBC9D4),
                    false,
                  ),
                  const SizedBox(width: 8),
                ],
                _buildJobTag(
                  context,
                  job.employmentType,
                  const Color(0xFFCBC9D4),
                  false,
                ),
                SizedBox(width: Responsive.isSmallScreen(context) ? 8 : 16),
                Expanded(
                  child: _buildJobTag(
                    context,
                    'Apply',
                    const Color(0xFFFF6B2C),
                    true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTag(
    BuildContext context,
    String label,
    Color color,
    bool isApplyButton,
  ) {
    // Responsive padding based on screen size
    double horizontalPadding;
    double verticalPadding;

    if (isApplyButton) {
      // Apply button responsive padding
      if (Responsive.isSmallScreen(context)) {
        // Small screens (<360px): Reduce padding significantly
        horizontalPadding = 12;
        verticalPadding = 8;
      } else if (Responsive.isMediumScreen(context)) {
        // Medium screens (360-400px): Moderate padding
        horizontalPadding = 18;
        verticalPadding = 9;
      } else {
        // Large screens (>400px): Original padding
        horizontalPadding = 28;
        verticalPadding = 10;
      }
    } else {
      // Other tags responsive padding
      if (Responsive.isSmallScreen(context)) {
        horizontalPadding = 12;
        verticalPadding = 6;
      } else if (Responsive.isMediumScreen(context)) {
        horizontalPadding = 16;
        verticalPadding = 7;
      } else {
        horizontalPadding = 20;
        verticalPadding = 8;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isApplyButton ? 13 : 11,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF524B6B),
          fontFamily: 'DM Sans',
          height: 1.302,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildFormattedSalary(String salaryRange, String employmentType) {
    final formattedSalary = _formatSalary(salaryRange, employmentType);

    // Split the salary into amount and unit (e.g., "$10K" and "/Project")
    final parts = formattedSalary.split(RegExp(r'(/\w+)$'));

    if (parts.length >= 2) {
      final amount = parts[0]; // e.g., "$10K"
      final unit = formattedSalary.substring(amount.length); // e.g., "/Project"

      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: amount,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232D3A),
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
            TextSpan(
              text: unit,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999), // Light gray
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
          ],
        ),
      );
    } else {
      // Fallback to original styling if splitting fails
      return Text(
        formattedSalary,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF232D3A),
          fontFamily: 'Open Sans',
          height: 1.362,
        ),
      );
    }
  }

  /// Formats salary for display matching Figma design
  /// Converts "10-16" or "50000-80000" to "$15K/Mo" format
  /// Adds period indicator based on employment type
  String _formatSalary(String salaryRange, String employmentType) {
    if (salaryRange.isEmpty) return 'Salary not specified';

    try {
      // Check if salary already has a period indicator (e.g., "40/hour", "50/month")
      final hasPeriod = salaryRange.contains('/');
      String period = '';
      String numberPart = salaryRange;

      if (hasPeriod) {
        // Extract the period from the salary string
        final parts = salaryRange.split('/');
        numberPart = parts[0];
        if (parts.length > 1) {
          // Normalize the period format
          final periodText = parts[1].toLowerCase().trim();
          if (periodText.contains('hour') || periodText == 'hr') {
            period = '/hr';
          } else if (periodText.contains('month') || periodText == 'mo') {
            period = '/mo';
          } else if (periodText.contains('year') || periodText == 'yr') {
            period = '/yr';
          } else if (periodText.contains('project')) {
            period = '/project';
          } else {
            period = '/$periodText'; // Use as-is if not recognized
          }
        }
      }

      // Remove currency symbols and commas from number part
      String cleaned = numberPart.replaceAll(RegExp(r'[₹$,\s]'), '');

      // Extract numbers (handle ranges like "10-16" or "50000-80000")
      final numbers = RegExp(r'\d+').allMatches(cleaned);
      if (numbers.isEmpty) {
        return salaryRange; // Return original if no numbers found
      }

      // Get first number (min salary)
      int minSalary = int.parse(numbers.first.group(0)!);

      // Format the amount with commas
      String formattedAmount = NumberFormatter.formatSalaryAmount(minSalary);

      // If no period was in the original data, determine it from employment type
      if (period.isEmpty) {
        switch (employmentType.toLowerCase()) {
          case 'full-time':
          case 'full time':
            period = '/mo';
            break;
          case 'part-time':
          case 'part time':
            period = '/hr';
            break;
          case 'freelance':
          case 'contract':
            period = '/project';
            break;
          default:
            period = '/mo'; // Default to monthly
        }
      }

      // Use ₹ for Indian currency, $ for others
      String currency = salaryRange.contains('₹') ? '₹' : '\$';

      return '$currency$formattedAmount$period';
    } catch (e) {
      debugPrint('Error formatting salary: $e');
      return salaryRange; // Return original on error
    }
  }

  Widget _buildSearchScreen() {
    // Return My Applications Screen without the header since it has its own
    return const MyApplicationsScreen();
  }

  Widget _buildAddScreen() {
    return const Center(child: Text('Add Screen - Coming Soon'));
  }
}
