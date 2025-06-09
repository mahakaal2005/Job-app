// recent_jobs_card.dart
import 'package:flutter/material.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employye/new%20post/emp_job_details_Screen.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:provider/provider.dart';

class RecentJobsCard extends StatelessWidget {
  final List<Job> jobs;
  final VoidCallback onSeeAllPressed;
  final Function(String, bool) onStatusChanged; // Callback for status changes

  const RecentJobsCard({
    Key? key,
    required this.jobs,
    required this.onSeeAllPressed,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  
  Widget build(BuildContext context) {
        final jobProvider = Provider.of<JobProvider>(context);
    final recentJobs = jobProvider.jobs.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Job Listings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.allJobListings,
                    arguments: {
                      'initialJobs': jobs,
                      'onStatusChanged': onStatusChanged, // Pass the callback
                    },
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
                    if (jobProvider.jobs.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: recentJobs
                  .map((job) => _buildJobItem(context, job, jobProvider))
                  .toList(),
            ),
        ],
      ),
    );
  }


  Widget _buildJobItem(BuildContext context, Job job, JobProvider jobProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => JobDetailsScreen(
                    job: job,
                    onStatusChanged: onStatusChanged,
                  ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerColor, width: 1),
          ),
          child: Row(
            children: [
              // Company Initial Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    job.companyName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.companyName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status Toggle Button
                  GestureDetector(
                    onTap: () async {
                      try {
                        final newStatus = !job.isActive;
                        await JobService.toggleJobStatus(job.id, newStatus);
                        onStatusChanged(job.id, newStatus);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: $e'),
                          ),
                        );
                      }
                    },

                    child: // In _buildJobItem, remove the onTap for the status toggle and just show it
                    // Replace the GestureDetector with just the Container showing the status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            job.isActive
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              job.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            job.isActive ? Icons.check : Icons.close,
                            size: 14,
                            color:
                                job.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  job.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Applicants Count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${job.applicantsCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 48,
            color: AppColors.secondaryText.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No jobs posted yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Create your first job posting to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
