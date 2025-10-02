import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/user/jobs/bookmark_provider.dart';
import 'package:get_work_app/screens/main/user/jobs/user_all_jobs_services.dart';
import 'package:get_work_app/screens/main/user/jobs/user_job_detail.dart';
import 'package:get_work_app/screens/main/user/saved_jobs_screen.dart';
import 'package:get_work_app/screens/main/user/student_ob_screen/skills_list.dart';
import 'package:get_work_app/screens/main/user/user_chats.dart';
import 'package:get_work_app/screens/main/user/user_help_and_support.dart';
import 'package:get_work_app/screens/main/user/user_my_gigs.dart';
import 'package:get_work_app/screens/main/user/user_profile.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/glassmorphism_utils.dart';
import 'package:get_work_app/widgets/floating_3d_button.dart';
import 'package:get_work_app/widgets/glass_card.dart';
import 'package:get_work_app/widgets/ios_floating_bottom_nav.dart';
import 'package:provider/provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with TickerProviderStateMixin {
  String? _userId;
  String _userName = '';
  bool _isLoading = true;
  int _currentIndex = 0;
  String _selectedFilter = 'All';
  List<String> _selectedCities = [];
  List<String> _selectedSkills = [];
  final TextEditingController _cityController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Job data with lazy loading
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoadingJobs = false;
  bool _hasMoreJobs = true;
  final int _jobsPerPage = 10;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _skillController = TextEditingController();
  List<String> _filteredSkills = [];

  final List<String> _filterOptions = [
    'All',
    'High Pay',
    'Remote',
    'Bookmarked',
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
    _scrollController.addListener(_scrollListener);
    _loadUserData();
    _loadJobs();
    _animationController.forward();
    _filteredSkills = List.from(allSkills);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _skillController.dispose();
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
        setState(() {
          _userName = userData['fullName'] ?? 'User';
          _userId = userData['uid'];
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

  void _filterSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = List.from(allSkills);
      } else {
        _filteredSkills =
            allSkills
                .where(
                  (skill) => skill.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _addCity(String city) {
    if (city.isNotEmpty && !_selectedCities.contains(city)) {
      setState(() {
        _selectedCities.add(city);
        _cityController.clear();
        _applyFilters();
      });
    }
  }

  void _addSkill(String skill) {
    if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _skillController.clear();
        _applyFilters();
      });
    }
  }

  void _removeCity(String city) {
    setState(() {
      _selectedCities.remove(city);
      _applyFilters();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs =
          _jobs.where((job) {
            bool matchesFilter = true;
            bool matchesCity = true;
            bool matchesSkill = true;

            // Apply main filter
            switch (_selectedFilter) {
              case 'High Pay':
                final salary = int.tryParse(job.salaryRange) ?? 0;
                matchesFilter = salary >= 10000; // 10L+ per year
                break;
              case 'Remote':
                matchesFilter =
                    job.location.toLowerCase().contains('remote') ||
                    job.employmentType.toLowerCase().contains('remote');
                break;
              case 'Bookmarked':
                final bookmarkProvider = Provider.of<BookmarkProvider>(
                  context,
                  listen: false,
                );
                matchesFilter = bookmarkProvider.isBookmarked(job.id);
                break;
              default: // 'All'
                matchesFilter = true;
            }

            // Apply city filter - match if any selected city is in the job location
            if (_selectedCities.isNotEmpty) {
              matchesCity = _selectedCities.any(
                (city) =>
                    job.location.toLowerCase().contains(city.toLowerCase()),
              );
            }

            // Apply skill filter - match if any selected skill is in the required skills
            if (_selectedSkills.isNotEmpty) {
              matchesSkill = _selectedSkills.any(
                (skill) => job.requiredSkills.any(
                  (jobSkill) =>
                      jobSkill.toLowerCase().contains(skill.toLowerCase()),
                ),
              );
            }

            return matchesFilter && matchesCity && matchesSkill;
          }).toList();
    });
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
        DocumentSnapshot<Map<String, dynamic>>? newLastDoc;
        if (jobs.isNotEmpty) {
          newLastDoc =
              await _firestore
                  .collection('jobPostings')
                  .doc(jobs.last.id)
                  .get();
        }

        setState(() {
          _jobs = jobs;
          _filteredJobs = jobs;
          _isLoadingJobs = false;
          _hasMoreJobs = jobs.length == _jobsPerPage;
          _lastDocument = newLastDoc;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading jobs: $e')));
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
        DocumentSnapshot<Map<String, dynamic>>? newLastDoc;
        if (newJobs.isNotEmpty) {
          newLastDoc =
              await _firestore
                  .collection('jobPostings')
                  .doc(newJobs.last.id)
                  .get();
        }

        setState(() {
          _isLoadingJobs = false;
          if (newJobs.isNotEmpty) {
            _jobs.addAll(newJobs);
            _hasMoreJobs = newJobs.length == _jobsPerPage;
            _lastDocument = newLastDoc;
          } else {
            _hasMoreJobs = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading more jobs: $e')));
      }
    }
  }

  Future<void> _toggleBookmark(String jobId) async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    bookmarkProvider.toggleBookmark(jobId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              bookmarkProvider.isBookmarked(jobId)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              bookmarkProvider.isBookmarked(jobId)
                  ? 'Job bookmarked'
                  : 'Bookmark removed',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatSalary(String salary) {
    // Assuming salary is in format "min-max" or just a single number
    final parts = salary.split('-');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0].trim()) ?? 0;
      final max = int.tryParse(parts[1].trim()) ?? 0;

      String formatAmount(int amount) {
        if (amount >= 10000000) {
          return '${(amount / 10000000).toStringAsFixed(1)}Cr';
        } else if (amount >= 100000) {
          return '${(amount / 100000).toStringAsFixed(1)}L';
        } else if (amount >= 1000) {
          return '${(amount / 1000).toStringAsFixed(1)}K';
        }
        return '$amount';
      }

      return '${formatAmount(min)} - ${formatAmount(max)}';
    } else {
      // Single value
      final num = int.tryParse(salary) ?? 0;

      if (num >= 10000000) {
        return '${(num / 10000000).toStringAsFixed(1)}Cr';
      } else if (num >= 100000) {
        return '${(num / 100000).toStringAsFixed(1)}L';
      } else if (num >= 1000) {
        return '${(num / 1000).toStringAsFixed(1)}K';
      }
      return '$num';
    }
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      body: Container(
        // Seamless blending - EXACTLY like green app's perfect flow
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accentDeep,        // Medium red (matches header bottom exactly)
              const Color(0xFFD73527),     // Slightly darker red
              const Color(0xFFCA2E20),     // Darker red
              const Color(0xFFBD2719),     // Even darker red
              const Color(0xFFB02012),     // Deep red
              const Color(0xFFA3190B),     // Very deep red
              const Color(0xFF961204),     // Dark red-brown
              const Color(0xFF7A0F03),     // Very dark red
              const Color(0xFF5E0C02),     // Almost black red
              const Color(0xFF420901),     // Nearly black
              const Color(0xFF260600),     // Very dark
              AppColors.background,        // Pure black at bottom
            ],
            stops: const [0.0, 0.08, 0.16, 0.24, 0.32, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            _buildCurrentScreen(),
            // Floating bottom navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IOSFloatingBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: const [
                  IOSBottomNavItem(
                    activeIcon: Icons.work,
                    inactiveIcon: Icons.work_outline,
                    label: 'Jobs',
                  ),
                  IOSBottomNavItem(
                    activeIcon: Icons.assignment,
                    inactiveIcon: Icons.assignment_outlined,
                    label: 'My Gigs',
                  ),
                  IOSBottomNavItem(
                    activeIcon: Icons.chat,
                    inactiveIcon: Icons.chat_outlined,
                    label: 'Chat',
                  ),
                  IOSBottomNavItem(
                    activeIcon: Icons.person,
                    inactiveIcon: Icons.person_outline,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildJobsScreen(); // Jobs screen (main job listings)
      case 1:
        return _buildMyGigsScreen(); // My Gigs screen
      case 2:
        return _buildChatsScreen(); // Chat screen
      case 3:
        return _buildProfileScreen(); // Profile screen
      default:
        return _buildJobsScreen();
    }
  }

  Widget _buildJobsScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Scrollable content with top padding for fixed header
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Add padding at top for fixed header space
              SliverToBoxAdapter(
                child: SizedBox(height: _getHeaderHeight()),
              ),
              // Add subtle visual separator for better UX
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: const SizedBox(height: 16), // Extra breathing room
                ),
              ),
              _buildJobsList(),
            ],
          ),
          // Fixed header that stays on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFixedGradientHeader(),
          ),
        ],
      ),
    );
  }

  double _getHeaderHeight() {
    // Calculate header height including SafeArea, curves, and proper spacing
    return MediaQuery.of(context).padding.top + 320; // Extra 20px for breathing room
  }

  // ROLLBACK: If you want to revert, uncomment the method below and change the call above
  /*
  Widget _buildJobsScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildCollapsibleGlassHeader(),
          _buildJobsList(),
        ],
      ),
    );
  }
  */

  Widget _buildMyGigsScreen() {
    return const MyGigsScreen();
  }

  Widget _buildChatsScreen() {
    return const UserChats();
  }

  Widget _buildProfileScreen() {
    return const ProfileScreen();
  }

  Widget _buildLuxuryCurvedHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.sheenStart.withValues(alpha: 0.9),
              AppColors.primaryAccent.withValues(alpha: 0.8),
              AppColors.accentDeep.withValues(alpha: 0.7),
              AppColors.sheenEnd.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDeep.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              children: [
                // Header content with welcome message
                Row(
                  children: [
                    // User avatar with luxury styling
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Welcome text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName.isNotEmpty
                                ? _userName.split(' ').first
                                : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Add notification functionality
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
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
      ),
    );
  }

  Widget _buildFixedGradientHeader() {
    return Container(
      // Minimal margins like green app - almost edge-to-edge
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        // Sophisticated red gradient - darker, more elegant
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accentDark,        // Deep burgundy red at top
            AppColors.accentCore,        // Rich red
            AppColors.primaryAccent,     // True red
            AppColors.accentDeep,        // Medium red - stays in red family
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        // Single, clean shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), // Tighter like green app
            child: Column(
              children: [
                // Welcome section
                _buildFixedHeaderWelcomeContent(),
                const SizedBox(height: 20),
                // Portfolio stats
                _buildFixedHeaderPortfolioStats(),
                const SizedBox(height: 20),
                // Filter chips
                _buildFixedHeaderFilterChips(),
                const SizedBox(height: 8), // Extra spacing at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuriousFlowingHeader() {
    return Container(
      // Flows from the very top
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            // Luxurious subtle gradient - not too bright
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryAccent.withValues(alpha: 0.85), // Subtle red
                AppColors.accentDeep.withValues(alpha: 0.75), // Deeper red
                AppColors.accentCore.withValues(alpha: 0.65), // Dark red
                AppColors.accentDark.withValues(alpha: 0.55), // Very dark red
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            // Luxurious 3D shadow system
            boxShadow: [
              // Primary depth shadow
              BoxShadow(
                color: AppColors.accentDeep.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: -3,
              ),
              // Secondary floating shadow
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                blurRadius: 50,
                offset: const Offset(0, 25),
                spreadRadius: -8,
              ),
              // Subtle inner glow
              BoxShadow(
                color: AppColors.sheenStart.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            child: Container(
              // Subtle glass overlay for luxury
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                children: [
                  // Welcome section
                  _buildLuxuriousWelcomeContent(),
                  const SizedBox(height: 24),
                  // Portfolio stats
                  _buildLuxuriousPortfolioStats(),
                  const SizedBox(height: 24),
                  // Embedded filter chips
                  _buildEmbeddedLuxuriousFilterChips(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuriousPortfolioStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Portfolio icon with luxury styling
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.work_outline,
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Stats content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Applications',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filteredJobs.length} Jobs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Luxurious trend indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '+12%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuriousWelcomeContent() {
    return Row(
      children: [
        // Luxurious User Avatar
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        // Welcome text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userName.isNotEmpty ? _userName.split(' ').first : 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // Luxurious Notification Button
        GestureDetector(
          onTap: () {
            // Add notification functionality
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmbeddedFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // Selected: Solid reddish-orange gradient
                  gradient:
                      isSelected
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accentCore,
                              AppColors.accentDeep,
                            ],
                          )
                          : null,
                  // Unselected: True glassmorphic effect
                  color:
                      isSelected ? null : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.accentCore.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.25),
                    width: isSelected ? 1.2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected) ...[
                      // Selected chip shadow for prominence
                      BoxShadow(
                        color: AppColors.accentCore.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] else ...[
                      // Unselected glassmorphic shadow
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildElegantFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filterOptions.length,
          itemBuilder: (context, index) {
            final filter = _filterOptions[index];
            final isSelected = _selectedFilter == filter;

            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _applyFilters();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        isSelected
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accentCore,
                                AppColors.accentDeep,
                              ],
                            )
                            : null,
                    color: isSelected ? null : AppColors.glass15,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.accentCore.withValues(alpha: 0.6)
                              : AppColors.glassBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (isSelected) ...[
                        BoxShadow(
                          color: AppColors.accentCore.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ] else ...[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ],
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textHigh,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobsList() {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= _filteredJobs.length) {
            return _isLoadingJobs
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                    ),
                  ),
                )
                : const SizedBox.shrink();
          }

          final job = _filteredJobs[index];
          return _buildJobCard(job);
        }, childCount: _filteredJobs.length + (_isLoadingJobs ? 1 : 0)),
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 20, // Increased elevation for dramatic floating effect
      child: Column(
        children: [
          // Stack for bookmark positioning
          Stack(
            children: [
              // Job card layout with proper positioning
              Row(
                children: [
                  // 3D Floating Company Avatar
                  GlassmorphismUtils.floating3DContainer(
                    padding: const EdgeInsets.all(2),
                    borderRadius: 14,
                    elevation: 6,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          job.companyName.isNotEmpty
                              ? job.companyName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: AppColors.textOnAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Job info with salary badge positioned inline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.companyName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Location and salary in same row
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: AppColors.textSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.location,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 3D Floating Salary Badge
                            GlassmorphismUtils.floating3DContainer(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              borderRadius: 12,
                              elevation: 6,
                              backgroundColor: AppColors.primaryAccent
                                  .withValues(alpha: 0.9),
                              borderColor: AppColors.primaryAccent,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${_formatSalary(job.salaryRange)}',
                                    style: const TextStyle(
                                      color: AppColors.textOnAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  Text(
                                    'per year',
                                    style: TextStyle(
                                      color: AppColors.textOnAccent.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 7,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 3D Floating Bookmark Button
              Positioned(
                top: -8,
                right: -8,
                child: Consumer<BookmarkProvider>(
                  builder: (context, bookmarkProvider, child) {
                    final isBookmarked = bookmarkProvider.isBookmarked(job.id);
                    return GestureDetector(
                      onTap: () => _toggleBookmark(job.id),
                      child: GlassmorphismUtils.floating3DContainer(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 20,
                        elevation: 6,
                        backgroundColor:
                            isBookmarked
                                ? AppColors.primaryAccent.withValues(alpha: 0.2)
                                : AppColors.glass15,
                        borderColor:
                            isBookmarked
                                ? AppColors.primaryAccent.withValues(alpha: 0.5)
                                : AppColors.glassBorder,
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color:
                              isBookmarked
                                  ? AppColors.primaryAccent
                                  : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3D Floating View Details Button
          Floating3DButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => JobDetailScreen(
                        job: job,
                        isBookmarked: Provider.of<BookmarkProvider>(
                          context,
                          listen: false,
                        ).isBookmarked(job.id),
                        onBookmarkToggled: (jobId) => _toggleBookmark(jobId),
                      ),
                ),
              );
            },
            isPrimary: true,
            width: double.infinity,
            borderRadius: 25, // More circular like green app reference
            elevation: 12,
            child: const Text(
              'View Details',
              style: TextStyle(
                color: AppColors.textOnAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: const BoxDecoration(
              color: AppColors.primaryAccent,
              borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Job Seeker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 3);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bookmark_outline,
                  title: 'Saved Jobs',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SavedJobsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
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
                const Divider(color: AppColors.border),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
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
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await AuthService.signOut();
                if (mounted) {
                  navigator.pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmbeddedLuxuriousFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // Selected: Luxurious white with subtle shadow
                  color:
                      isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color:
                        isSelected
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  // Luxurious shadow effects
                  boxShadow: [
                    if (isSelected) ...[
                      // Selected chip gets elegant white glow
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ] else ...[
                      // Unselected chips get subtle depth
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ],
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color:
                        isSelected
                            ? AppColors.primaryAccent
                            : Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixedHeaderWelcomeContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // No extra padding like green app
      child: Row(
        children: [
          // Subtle, elegant avatar (like green app)
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Subtle shadow - no harsh glow
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22, // Smaller, more refined like green app
                backgroundColor: Colors.white.withValues(alpha: 0.95),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16), // Proper spacing like green app
          // Clean, elegant typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    // Subtle text glow
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4), // Tighter spacing
                Text(
                  _userName.isNotEmpty ? _userName.split(' ').first : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // More reasonable size
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    // No glow effects - clean and elegant
                  ),
                ),
              ],
            ),
          ),
          // Subtle, elegant notification button (like green app)
          GestureDetector(
            onTap: () {
              // Add notification functionality
            },
            child: Container(
              padding: const EdgeInsets.all(12), // Smaller, more refined
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15), // Subtle background
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), // Subtle border
                  width: 1,
                ),
                // Simple, clean shadow
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 20, // Smaller, more elegant
                // No glow effects - clean design
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeaderPortfolioStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Portfolio icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.work_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Stats content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Applications',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filteredJobs.length} Jobs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Trend indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '+12%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeaderFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  // Selected: Bright white with red text
                  color: isSelected 
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  // Enhanced shadow effects for fixed header
                  boxShadow: [
                    if (isSelected) ...[
                      // Selected chip gets bright white glow
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ] else ...[
                      // Unselected chips get subtle depth
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ],
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected 
                      ? AppColors.primaryAccent 
                      : Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }}
