import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employye/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/user/jobs/bookmark_provider.dart';
import 'package:get_work_app/screens/main/user/jobs/user_all_jobs_services.dart';
import 'package:get_work_app/screens/main/user/jobs/job_detail_screen_new.dart';
import 'package:get_work_app/screens/main/user/jobs/filtered_jobs_screen.dart';
import 'package:get_work_app/screens/main/user/bookmarks_screen.dart';
import 'package:get_work_app/screens/main/user/user_chats.dart';
import 'package:get_work_app/screens/main/user/user_help_and_support.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/image_utils.dart';
import 'package:get_work_app/widgets/custom_bottom_nav_bar.dart';
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
      final userData = await AuthService.getUserData();
      if (userData != null && mounted) {
        // Use 'profileImageUrl' - same field name as user_profile.dart
        final profilePic = userData['profileImageUrl'] ?? '';
        debugPrint('=== User Data Loaded ===');
        debugPrint('User Name: ${userData['fullName']}');
        debugPrint('Profile Image URL: $profilePic');
        debugPrint('Profile Image isEmpty: ${profilePic.isEmpty}');
        debugPrint('=======================');
        
        setState(() {
          _userName = userData['fullName'] ?? 'User';
          _userId = userData['uid'];
          _userProfilePic = profilePic;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoading = false;
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
        debugPrint('Please create the required Firestore indexes by clicking the URLs in the error messages above.');
        debugPrint('Once indexes are created, the statistics will load automatically.');
      }
      
      // Fallback: Calculate from loaded jobs
      if (mounted && _jobs.isNotEmpty) {
        setState(() {
          _fullTimeJobsCount = _jobs.where((job) => job.employmentType == 'Full-time').length;
          _partTimeJobsCount = _jobs.where((job) => job.employmentType == 'Part-time').length;
          _remoteJobsCount = _jobs.where((job) => job.workFrom == 'Remote').length;
        });
        
        debugPrint('Using fallback: Calculated statistics from ${_jobs.length} loaded jobs');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more jobs: $e')),
        );
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
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
                colors: [AppColors.lookGigPurple, AppColors.lookGigPurple.withOpacity(0.8)],
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
                      child: _userProfilePic.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _userProfilePic,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lookGigPurple,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
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
                  leading: const Icon(Icons.person_outline, color: AppColors.lookGigPurple),
                  title: const Text('My Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.userProfile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_outline, color: AppColors.lookGigPurple),
                  title: const Text('Saved Jobs'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 4);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.lookGigPurple),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserHelpAndSupport()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.fromLTRB(23, 16, 23, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Greeting - Left Side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello',
                  style: TextStyle(
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
              child: _userProfilePic.isEmpty
                  ? Icon(
                      Icons.person,
                      color: AppColors.black,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 23),
      child: SizedBox(
        width: 329,
        height: 181,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bottom container layer at (0, 0) - 329x181 with rounded corners (transparent/white background)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 329,
                height: 181,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Blue rectangle (middle layer) at (0, 38) - 329x143 - THIS IS THE ACTUAL BLUE BACKGROUND
            Positioned(
              left: 0,
              top: 38,
              child: Container(
                width: 329,
                height: 143,
                decoration: BoxDecoration(
                  color: const Color(0xFF130160),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Lady's photo at (160, 0) - 216x193 - positioned at top of banner
            // Lady extends from y=0 to y=193 (12px below banner bottom at 181)
            // Blue box: y=38 to y=181, so lady's bottom extends 12px below blue box bottom
            // This creates the effect of lady standing ON the blue box
            Positioned(
              left: 160,
              top: 0,
              child: Image.asset(
                'assets/images/banner_lady.png',
                width: 216,
                height: 193,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 216,
                    height: 193,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 80, color: Colors.white),
                  );
                },
              ),
            ),
          // Text overlay - Group 65 at (17, 62) within banner
          Positioned(
              left: 17,
              top: 62,
              child: SizedBox(
                width: 141,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "50% off" at (0, 0) within Group 65
                    const Text(
                      '50% off',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFFFF),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                    // "take any courses" at (0, 21) within Group 65
                    const Text(
                      'take any courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFFFFFF),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Button at (0, 62) within Group 65
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Course feature coming soon!')),
                        );
                      },
                      child: Container(
                        width: 90,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9228),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            'Join Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFFFFFF),
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
    );
  }

  Widget _buildFindYourJobSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 23),
      child: Text(
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
      padding: const EdgeInsets.symmetric(horizontal: 23),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remote Job Card - Left (150x170)
          GestureDetector(
            onTap: () {
              setState(() {
                _showingFilteredJobs = true;
                _currentFilterType = 'Remote';
                _currentFilterTitle = 'Remote Jobs';
              });
            },
            child: Container(
              width: 150,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFAFECFE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  // Icon at position (58, 37) within card
                  Positioned(
                    left: 58,
                    top: 37,
                    child: Image.asset(
                      'assets/images/job_search_icon.png',
                      width: 34,
                      height: 34,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.work, size: 34, color: Color(0xFF0D0140));
                      },
                    ),
                  ),
                  // Count at position (54, 85)
                  Positioned(
                    left: 54,
                    top: 85,
                    child: Text(
                      _formatCount(_remoteJobsCount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D0140),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                  ),
                  // Label at position (36, 112)
                  Positioned(
                    left: 36,
                    top: 112,
                    child: const Text(
                      'Remote Job',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF0D0140),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Right Column with Full Time and Part Time
          Column(
            children: [
              // Full Time Card (156x75)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showingFilteredJobs = true;
                    _currentFilterType = 'Full-time';
                    _currentFilterTitle = 'Full Time Jobs';
                  });
                },
                child: Container(
                  width: 156,
                  height: 75,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBEAFFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      // Count at position (51, 17)
                      Positioned(
                        left: 51,
                        top: 17,
                        child: Text(
                          _formatCount(_fullTimeJobsCount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D0140),
                            fontFamily: 'DM Sans',
                            height: 1.302,
                          ),
                        ),
                      ),
                      // Label at position (46, 43)
                      Positioned(
                        left: 46,
                        top: 43,
                        child: const Text(
                          'Full Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF0D0140),
                            fontFamily: 'DM Sans',
                            height: 1.302,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Part Time Card (156x75)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showingFilteredJobs = true;
                    _currentFilterType = 'Part-time';
                    _currentFilterTitle = 'Part Time Jobs';
                  });
                },
                child: Container(
                  width: 156,
                  height: 75,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD6AD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      // Count at position (51, 17)
                      Positioned(
                        left: 51,
                        top: 17,
                        child: Text(
                          _formatCount(_partTimeJobsCount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D0140),
                            fontFamily: 'DM Sans',
                            height: 1.302,
                          ),
                        ),
                      ),
                      // Label at position (43, 43)
                      Positioned(
                        left: 43,
                        top: 43,
                        child: const Text(
                          'Part Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF0D0140),
                            fontFamily: 'DM Sans',
                            height: 1.302,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJobsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
            builder: (context) => JobDetailScreenNew(
              job: job,
              isBookmarked: isBookmarked,
              onBookmarkToggled: (jobId) {
                bookmarkProvider.toggleBookmark(jobId);
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
                  backgroundColor: const Color(0xFFE8E0FF), // Light purple background
                  child: job.companyLogo.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            job.companyLogo,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business,
                                size: 20,
                                color: Color(0xFF6B5CE7),
                              );
                            },
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
                          Text(
                            job.companyName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF524B6B),
                              fontFamily: 'DM Sans',
                              height: 1.302,
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
                          Expanded(
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
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_userId != null) {
                      bookmarkProvider.toggleBookmark(job.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBookmarked ? 'Bookmark removed' : 'Job bookmarked',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (job.experienceLevel.isNotEmpty)
                  Expanded(
                    child: _buildJobTag(job.experienceLevel, const Color(0xFFCBC9D4)),
                  ),
                if (job.experienceLevel.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: _buildJobTag(job.employmentType, const Color(0xFFCBC9D4)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildJobTag('Apply', const Color(0xFFFF6B2C)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: Color(0xFF524B6B),
          fontFamily: 'DM Sans',
          height: 1.302,
        ),
        textAlign: TextAlign.center,
      ),
    );
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
      // Remove currency symbols and commas
      String cleaned = salaryRange.replaceAll(RegExp(r'[₹$,\s]'), '');
      
      // Extract numbers (handle ranges like "10-16" or "50000-80000")
      final numbers = RegExp(r'\d+').allMatches(cleaned);
      if (numbers.isEmpty) return salaryRange; // Return original if no numbers found
      
      // Get first number (min salary)
      int minSalary = int.parse(numbers.first.group(0)!);
      
      // Determine if it's in thousands or needs K suffix
      String formattedAmount;
      if (minSalary < 1000) {
        // Already in K format (e.g., "10" means 10K)
        formattedAmount = '${minSalary}K';
      } else if (minSalary >= 1000 && minSalary < 100000) {
        // Convert to K (e.g., 15000 -> 15K)
        formattedAmount = '${(minSalary / 1000).round()}K';
      } else {
        // Large numbers, show in lakhs or keep as is
        formattedAmount = '${(minSalary / 1000).round()}K';
      }
      
      // Determine period based on employment type
      String period;
      switch (employmentType.toLowerCase()) {
        case 'full-time':
        case 'full time':
          period = '/Mo';
          break;
        case 'part-time':
        case 'part time':
          period = '/Hr';
          break;
        case 'freelance':
        case 'contract':
          period = '/Project';
          break;
        default:
          period = '/Mo'; // Default to monthly
      }
      
      // Use ₹ for Indian currency, $ for others (can be enhanced based on location)
      String currency = salaryRange.contains('₹') ? '₹' : '\$';
      
      return '$currency$formattedAmount$period';
    } catch (e) {
      debugPrint('Error formatting salary: $e');
      return salaryRange; // Return original on error
    }
  }

  Widget _buildSearchScreen() {
    return const Center(
      child: Text('Search Screen - Coming Soon'),
    );
  }

  Widget _buildAddScreen() {
    return const Center(
      child: Text('Add Screen - Coming Soon'),
    );
  }
}
