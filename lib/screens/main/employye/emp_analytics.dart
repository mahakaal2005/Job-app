import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/services/auth_services.dart';
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final companyInfo = await AuthService.getEmployeeCompanyInfo();
      if (companyInfo == null) {
        throw Exception('Company information not found');
      }

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

      setState(() {
        _applications = allApplications;
      });

      // Process application data
      _processApplicationData(allApplications);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
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
      setState(() {
        _error = 'Error processing data: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryAccent),
              const SizedBox(height: 16),
              Text(
                'Loading Analytics...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.primaryAccent),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Data',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Analytics Dashboard', style: Theme.of(context).textTheme.displayMedium),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatisticsCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              title: 'Active Jobs',
              value: _jobs.length.toString(),
            ),
            _buildStatCard(
              title: 'Applicants',
              value: _applications.length.toString(),
            ),
            _buildStatCard(
              title: 'Pending Reviews',
              value: (_applicationStatusCounts['pending'] ?? 0).toString(),
            ),
            _buildStatCard(
              title: 'Hired',
              value: (_applicationStatusCounts['accepted'] ?? 0).toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.primaryAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
