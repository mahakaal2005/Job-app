import 'package:flutter/material.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/provider/applicant_provider.dart';
import 'package:get_work_app/screens/main/employye/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/employye/new post/emp_job_details_screen.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:provider/provider.dart';

class AllJobListingsScreen extends StatefulWidget {
  const AllJobListingsScreen({super.key, this.initialJobs, this.onStatusChanged});

  final List<Job>? initialJobs;
  final Function(String, bool)? onStatusChanged;

  @override
  State<AllJobListingsScreen> createState() => _AllJobListingsScreenState();
}

class _AllJobListingsScreenState extends State<AllJobListingsScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      final applicantProvider = Provider.of<ApplicantProvider>(
        context,
        listen: false,
      );

      // Load jobs and initialize applicant listeners
      jobProvider.loadJobs().then((_) {
        if (jobProvider.jobs.isNotEmpty) {
          // Initialize listeners for the company of the first job
          // Assuming all jobs are from the same company
          applicantProvider.initializeCompanyListeners(
            jobProvider.jobs[0].companyName,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Job Listings',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.whiteText),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createJobOpening);
            },
          ),
        ],
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          // Apply filters based on _selectedFilter
          List<Job> filteredJobs = _applyFilters(jobProvider.jobs);

          return Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Filter: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active', 'active'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Inactive', 'inactive'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Jobs List
              Expanded(
                child:
                    jobProvider.isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue,
                            ),
                          ),
                        )
                        : filteredJobs.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                          onRefresh: () => jobProvider.loadJobs(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredJobs.length,
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              return _buildJobCard(context, job, jobProvider);
                            },
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Job> _applyFilters(List<Job> jobs) {
    switch (_selectedFilter) {
      case 'active':
        return jobs.where((job) => job.isActive).toList();
      case 'inactive':
        return jobs.where((job) => !job.isActive).toList();
      default:
        return jobs;
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.whiteText : AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Job job, JobProvider jobProvider) {
    return Consumer<ApplicantProvider>(
      builder: (context, applicantProvider, child) {
        final applicantCount = applicantProvider.applicantCounts[job.id] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => JobDetailsScreen(
                        job: job,
                        onStatusChanged: (jobId, isActive) {
                          jobProvider.updateJobStatus(jobId, isActive);
                          if (widget.onStatusChanged != null) {
                            widget.onStatusChanged!(jobId, isActive);
                          }
                        },
                        onJobDeleted: (jobId) {
                          jobProvider.loadJobs();
                        },
                      ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            job.isActive
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              job.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        job.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color:
                              job.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.location,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.work_outline,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.employmentType,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatChip(
                      Icons.people,
                      '$applicantCount Applicants',
                      AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.visibility,
                      '${job.viewCount} Views',
                      AppColors.success,
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(job.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.hintText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline,
              size: 64,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Jobs Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'You haven\'t posted any jobs yet.\nTap the + button to create your first job listing.'
                : _selectedFilter == 'active'
                ? 'No active jobs found.'
                : 'No inactive jobs found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createJobOpening);
            },
            icon: const Icon(Icons.add, color: AppColors.whiteText),
            label: const Text(
              'Create Job',
              style: TextStyle(
                color: AppColors.whiteText,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
