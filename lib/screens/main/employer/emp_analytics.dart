import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/services/profile_gating_service.dart';
import 'package:get_work_app/screens/main/employer/applicants/all_applicants_screen.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:intl/intl.dart';

class EmpAnalytics extends StatefulWidget {
  const EmpAnalytics({super.key});

  @override
  State<EmpAnalytics> createState() => _EmpAnalyticsState();
}

class _EmpAnalyticsState extends State<EmpAnalytics> {
  bool _isLoading = true;
  Map<String, dynamic>? _companyInfo;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _jobs = [];
  Map<String, int> _applicationStatusCounts = {};
  Map<String, int> _jobTypeDistribution = {};
  List<Map<String, dynamic>> _dailyApplications = [];
  List<Map<String, dynamic>> _topSkills = [];
  List<Map<String, dynamic>> _experienceDistribution = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileAndLoadData();
    });
  }

  Future<void> _checkProfileAndLoadData() async {
    try {
      // Check if profile is complete before loading analytics
      final canViewAnalytics = await ProfileGatingService.canPerformAction(
        context,
        actionName: 'view analytics',
        showDialog: false, // Don't show dialog yet, just check
      );

      if (!canViewAnalytics && mounted) {
        // Profile is incomplete, show the gating dialog
        final result = await ProfileGatingService.canPerformAction(
          context,
          actionName: 'view analytics',
          showDialog: true, // Now show the dialog
        );
        
        // If user didn't choose to complete profile, show placeholder
        if (!result && mounted) {
          setState(() {
            _isLoading = false;
            _error = 'profile_incomplete';
          });
          return;
        }
      }

      // Check if employer has posted any jobs
      final jobCount = await AuthService.getEmployerJobCount();
      if (jobCount == 0 && mounted) {
        setState(() {
          _isLoading = false;
          _error = 'no_jobs';
        });
        return;
      }

      // Profile is complete and has jobs, load data
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'check_failed';
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();
      if (companyInfo == null) {
        throw Exception('Company information not found');
      }

      if (!mounted) return;
      setState(() {
        _companyInfo = companyInfo;
      });

      // Load all jobs
      final jobsSnapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(_companyInfo?['companyName'])
              .collection('jobPostings')
              .get();

      _jobs =
          jobsSnapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();

      // Load all applications
      final List<Map<String, dynamic>> allApplications = [];
      for (var job in _jobs) {
        try {
          final applicationsSnapshot =
              await FirebaseFirestore.instance
                  .collection('jobs')
                  .doc(_companyInfo?['companyName'])
                  .collection('jobPostings')
                  .doc(job['id'])
                  .collection('applicants')
                  .get();

          for (var doc in applicationsSnapshot.docs) {
            allApplications.add({
              ...doc.data(),
              'id': doc.id,
              'jobId': job['id'],
              'jobTitle': job['title'],
            });
          }
        } catch (e) {
          print('Error loading applications for job ${job['id']}: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _applications = allApplications;
      });

      // Process application data
      _processApplicationData(allApplications);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load analytics data: ${e.toString()}';
      });
    }
  }

  void _processApplicationData(List<Map<String, dynamic>> applications) {
    try {
      // Application status counts
      _applicationStatusCounts = {};
      for (var app in applications) {
        final status = app['status']?.toString().toLowerCase() ?? 'pending';
        _applicationStatusCounts[status] =
            (_applicationStatusCounts[status] ?? 0) + 1;
      }

      // Job type distribution
      _jobTypeDistribution = {};
      for (var job in _jobs) {
        final type = job['type']?.toString().toLowerCase() ?? 'full-time';
        _jobTypeDistribution[type] = (_jobTypeDistribution[type] ?? 0) + 1;
      }

      // Daily applications for last 30 days
      final now = DateTime.now();
      _dailyApplications =
          List.generate(30, (index) {
            final date = DateTime(now.year, now.month, now.day - index);
            final count =
                applications.where((app) {
                  try {
                    final appliedAt = DateTime.parse(
                      app['appliedAt']?.toString() ??
                          DateTime.now().toIso8601String(),
                    );
                    return appliedAt.year == date.year &&
                        appliedAt.month == date.month &&
                        appliedAt.day == date.day;
                  } catch (e) {
                    print('Error parsing date for application: $e');
                    return false;
                  }
                }).length;
            return {
              'date': DateFormat('MM/dd').format(date),
              'count': count,
              'fullDate': date,
            };
          }).reversed.toList();

      // Top skills
      final skillCounts = <String, int>{};
      for (var app in applications) {
        final skills = List<String>.from(app['skills'] ?? []);
        for (var skill in skills) {
          if (skill.isNotEmpty) {
            skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
          }
        }
      }
      _topSkills =
          skillCounts.entries
              .map((e) => {'skill': e.key, 'count': e.value})
              .toList()
            ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      _topSkills = _topSkills.take(10).toList();

      // More precise experience distribution
      _experienceDistribution = [
        {'range': 'Fresher (0-1 years)', 'count': 0},
        {'range': 'Junior (1-3 years)', 'count': 0},
        {'range': 'Mid-level (3-6 years)', 'count': 0},
        {'range': 'Senior (6-10 years)', 'count': 0},
        {'range': 'Expert (10-15 years)', 'count': 0},
        {'range': 'Veteran (15+ years)', 'count': 0},
      ];

      for (var app in applications) {
        try {
          final experience = (app['experience'] ?? 0).toDouble();
          if (experience <= 1) {
            _experienceDistribution[0]['count']++;
          } else if (experience <= 3) {
            _experienceDistribution[1]['count']++;
          } else if (experience <= 6) {
            _experienceDistribution[2]['count']++;
          } else if (experience <= 10) {
            _experienceDistribution[3]['count']++;
          } else if (experience <= 15) {
            _experienceDistribution[4]['count']++;
          } else {
            _experienceDistribution[5]['count']++;
          }
        } catch (e) {
          print('Error processing experience for application: $e');
        }
      }

      // Remove empty experience categories
      _experienceDistribution.removeWhere((item) => item['count'] == 0);
    } catch (e) {
      print('Error processing application data: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Error processing data: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.gigAppLightGray,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.gigAppPurple),
              const SizedBox(height: 16),
              Text(
                'Loading Analytics...',
                style: TextStyle(color: AppColors.gigAppDescriptionText, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      // Show different UI based on error type
      if (_error == 'no_jobs') {
        return Scaffold(
          backgroundColor: AppColors.gigAppLightGray,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gigAppPurple.withOpacity(0.15),
                          const Color(0xFF6C5CE7).withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work_outline,
                      size: 64,
                      color: AppColors.gigAppPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Jobs Posted Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gigAppProfileText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Post your first job to see analytics about applications, applicant insights, and hiring trends.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gigAppDescriptionText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to post job screen
                      Navigator.pushNamed(context, '/create-job-opening');
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Post Your First Job',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gigAppPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      
      if (_error == 'profile_incomplete') {
        return Scaffold(
          backgroundColor: AppColors.gigAppLightGray,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gigAppPurple.withOpacity(0.15),
                          const Color(0xFF6C5CE7).withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: AppColors.gigAppPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Analytics Locked',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gigAppProfileText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Complete your company profile to unlock detailed analytics about your job postings and applicant insights.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gigAppDescriptionText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await ProfileGatingService.canPerformAction(
                        context,
                        actionName: 'view analytics',
                      );
                      if (result && mounted) {
                        // Profile completed, reload data
                        _checkProfileAndLoadData();
                      }
                    },
                    icon: const Icon(Icons.lock_open, color: Colors.white),
                    label: const Text(
                      'Complete Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gigAppPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      
      // Show error UI for other errors
      return Scaffold(
        backgroundColor: AppColors.gigAppLightGray,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gigAppProfileText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gigAppPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.gigAppLightGray,
      body: Column(
        children: [
          _buildAnalyticsHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.gigAppPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(isSmallScreen),
              const SizedBox(height: 24),
              if (_applicationStatusCounts.isNotEmpty) ...[
                _buildApplicationStatusChart(),
                const SizedBox(height: 24),
              ],
              if (_dailyApplications.isNotEmpty) ...[
                _buildDailyApplicationsChart(),
                const SizedBox(height: 24),
              ],
              if (_jobTypeDistribution.isNotEmpty) ...[
                _buildJobTypeDistributionChart(),
                const SizedBox(height: 24),
              ],
              if (_experienceDistribution.isNotEmpty) ...[
                _buildExperienceDistributionChart(),
                const SizedBox(height: 24),
              ],
                    if (_topSkills.isNotEmpty) ...[_buildTopSkillsChart()],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
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
                AppColors.gigAppProfileGradientStart,
                AppColors.gigAppProfileGradientEnd,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track your hiring performance',
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
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.gigAppProfileText,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: isSmallScreen ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          childAspectRatio: isSmallScreen ? 1.4 : 1.8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildSummaryCard(
              title: 'Total Applications',
              value: _applications.length.toString(),
              icon: Icons.people_alt_outlined,
              color: const Color(0xFF2F51A7),
              subtitle: 'All time',
              onTap: () {
                // Navigate to all applicants screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllApplicantsScreen(
                      jobId: '', // Empty means show all jobs
                      companyName: _companyInfo?['companyName'] ?? '',
                      jobTitle: 'All Jobs',
                      initialStatus: 'all', // Show all applicants
                    ),
                  ),
                );
              },
            ),
            _buildSummaryCard(
              title: 'Active Jobs',
              value: _jobs.length.toString(),
              icon: Icons.work_outline,
              color: const Color(0xFF2F51A7),
              subtitle: 'Currently posted',
              onTap: () {
                // Navigate to all jobs screen
                // Don't pass initialJobs - let the screen load them via provider
                Navigator.pushNamed(
                  context,
                  AppRoutes.allJobListings,
                );
              },
            ),
            _buildSummaryCard(
              title: 'Pending Reviews',
              value: (_applicationStatusCounts['pending'] ?? 0).toString(),
              icon: Icons.hourglass_empty_outlined,
              color: const Color(0xFF2F51A7),
              subtitle: 'Awaiting action',
              onTap: () {
                // Navigate to applicants filtered by pending status
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllApplicantsScreen(
                      jobId: '', // Empty means show all jobs
                      companyName: _companyInfo?['companyName'] ?? '',
                      jobTitle: 'Pending Reviews',
                      initialStatus: 'pending', // Auto-filter to pending
                    ),
                  ),
                );
              },
            ),
            _buildSummaryCard(
              title: 'Hired',
              value: (_applicationStatusCounts['accepted'] ?? 0).toString(),
              icon: Icons.check_circle_outline,
              color: const Color(0xFF2F51A7),
              subtitle: 'Successful hires',
              onTap: () {
                // Navigate to applicants filtered by accepted status
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllApplicantsScreen(
                      jobId: '', // Empty means show all jobs
                      companyName: _companyInfo?['companyName'] ?? '',
                      jobTitle: 'Hired Candidates',
                      initialStatus: 'accepted', // Auto-filter to accepted
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.profileCardShadow,
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gigAppProfileText,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.gigAppDescriptionText),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildApplicationStatusChart() {
    return _buildChartContainer(
      title: 'Application Status Distribution',
      height: 250,
      child: PieChart(
        PieChartData(
          sections:
              _applicationStatusCounts.entries.map((entry) {
                final color = _getStatusColor(entry.key);
                final percentage = (entry.value / _applications.length * 100)
                    .toStringAsFixed(1);
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '$percentage%',
                  color: color,
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
        ),
      ),
      legend: _buildStatusLegend(),
    );
  }

  Widget _buildStatusLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          _applicationStatusCounts.entries.map((entry) {
            final color = _getStatusColor(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key.capitalize()} (${entry.value})',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gigAppDescriptionText,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildDailyApplicationsChart() {
    return _buildChartContainer(
      title: 'Daily Applications (Last 30 Days)',
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < _dailyApplications.length) {
                    if (value.toInt() % 5 == 0) {
                      return Text(
                        _dailyApplications[value.toInt()]['date'],
                        style: TextStyle(
                          color: AppColors.gigAppDescriptionText,
                          fontSize: 10,
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              left: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots:
                  _dailyApplications.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value['count'].toDouble(),
                    );
                  }).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF2F51A7),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF2F51A7),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2F51A7).withOpacity(0.3),
                    const Color(0xFF2F51A7).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTypeDistributionChart() {
    return _buildChartContainer(
      title: 'Job Types',
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections:
                    _jobTypeDistribution.entries.map((entry) {
                      final colors = [
                        AppColors.gigAppPurple,
                        const Color(0xFF2F51A7),
                        AppColors.gigAppProfileGradientEnd,
                        AppColors.gigAppDescriptionText,
                        AppColors.gigAppActiveIcon,
                      ];
                      final colorIndex = _jobTypeDistribution.keys
                          .toList()
                          .indexOf(entry.key);
                      final color = colors[colorIndex % colors.length];
                      final percentage = (entry.value / _jobs.length * 100)
                          .toStringAsFixed(1);

                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '$percentage%',
                        color: color,
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildJobTypeLegend(),
        ],
      ),
    );
  }

  Widget _buildJobTypeLegend() {
    final colors = [
      AppColors.gigAppPurple,
      const Color(0xFF2F51A7),
      AppColors.gigAppProfileGradientEnd,
      AppColors.gigAppDescriptionText,
      AppColors.gigAppActiveIcon,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _jobTypeDistribution.entries.map((entry) {
            final colorIndex = _jobTypeDistribution.keys.toList().indexOf(
              entry.key,
            );
            final color = colors[colorIndex % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key.capitalize(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gigAppDescriptionText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildExperienceDistributionChart() {
    // Ensure all experience levels are shown, even if count is 0
    final allExperienceLevels = [
      {'range': 'Fresher (0-1 years)', 'count': 0},
      {'range': 'Junior (1-3 years)', 'count': 0},
      {'range': 'Mid-level (3-6 years)', 'count': 0},
      {'range': 'Senior (6-10 years)', 'count': 0},
      {'range': 'Expert (10-15 years)', 'count': 0},
      {'range': 'Veteran (15+ years)', 'count': 0},
    ];

    // Update counts from actual data
    for (var level in allExperienceLevels) {
      final existingData = _experienceDistribution.firstWhere(
        (item) => item['range'] == level['range'],
        orElse: () => level,
      );
      level['count'] = existingData['count'];
    }

    return _buildChartContainer(
      title: 'Experience Levels',
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: allExperienceLevels
              .map((e) => (e['count'] as int).toDouble())
              .reduce((a, b) => a > b ? a : b),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${allExperienceLevels[groupIndex]['range']}\n${rod.toY.toInt()} applicants',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < allExperienceLevels.length) {
                    final range =
                        allExperienceLevels[value.toInt()]['range'] as String;
                    final shortRange = range.split(' ').first;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        shortRange,
                        style: TextStyle(
                          color: AppColors.gigAppDescriptionText,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.gigAppDescriptionText,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              left: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          barGroups:
              allExperienceLevels.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['count'] as int).toDouble(),
                      color: const Color(0xFF2F51A7),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopSkillsChart() {
    return _buildChartContainer(
      title: 'Top Skills in Demand',
      height: 400,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              _topSkills.isNotEmpty ? _topSkills.first['count'].toDouble() : 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${_topSkills[groupIndex]['skill']}\n${rod.toY.toInt()} mentions',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _topSkills.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          _topSkills[value.toInt()]['skill'],
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              left: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          barGroups:
              _topSkills.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value['count'].toDouble(),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue,
                          AppColors.primaryBlue.withOpacity(0.7),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 24,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartContainer({
    required String title,
    required Widget child,
    required double height,
    Widget? legend,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileCardShadow,
            blurRadius: 62,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gigAppProfileText,
            ),
          ),
          if (legend != null) ...[const SizedBox(height: 12), legend],
          const SizedBox(height: 20),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'shortlisted':
        return AppColors.warning;
      case 'interviewed':
        return const Color(0xFF2F51A7);
      default:
        return AppColors.gigAppPurple;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
