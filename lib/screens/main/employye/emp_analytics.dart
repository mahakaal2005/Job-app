import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              Text(
                'Loading Analytics...',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
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
                    color: AppColors.primaryText,
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
                    backgroundColor: AppColors.primaryBlue,
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
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
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
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 16),
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
              color: AppColors.primaryBlue,
              subtitle: 'All time',
            ),
            _buildSummaryCard(
              title: 'Active Jobs',
              value: _jobs.length.toString(),
              icon: Icons.work_outline,
              color: AppColors.success,
              subtitle: 'Currently posted',
            ),
            _buildSummaryCard(
              title: 'Pending Reviews',
              value: (_applicationStatusCounts['pending'] ?? 0).toString(),
              icon: Icons.hourglass_empty_outlined,
              color: AppColors.warning,
              subtitle: 'Awaiting action',
            ),
            _buildSummaryCard(
              title: 'Hired',
              value: (_applicationStatusCounts['accepted'] ?? 0).toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              subtitle: 'Successful hires',
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
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
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
            ],
          ),
        ],
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
                    color: AppColors.secondaryText,
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
                          color: AppColors.secondaryText,
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
              color: AppColors.primaryBlue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.primaryBlue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.3),
                    AppColors.primaryBlue.withOpacity(0.05),
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
                        AppColors.primaryBlue,
                        AppColors.success,
                        AppColors.warning,
                        Colors.purple,
                        Colors.teal,
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
      AppColors.primaryBlue,
      AppColors.success,
      AppColors.warning,
      Colors.purple,
      Colors.teal,
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
                      color: AppColors.secondaryText,
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
                          color: AppColors.secondaryText,
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
              allExperienceLevels.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['count'] as int).toDouble(),
                      color: AppColors.success,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              color: AppColors.primaryText,
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
        return Colors.orange;
      default:
        return AppColors.primaryBlue;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
