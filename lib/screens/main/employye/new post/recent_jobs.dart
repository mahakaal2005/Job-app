// recent_jobs_card.dart
import 'package:flutter/material.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/provider/applicant_provider.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employye/new post/emp_job_details_screen.dart';
import 'package:get_work_app/screens/main/employye/new post/job_new_model.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:provider/provider.dart';

class RecentJobsCard extends StatefulWidget {
  final List<Job> jobs;
  final VoidCallback onSeeAllPressed;
  final Function(String, bool) onStatusChanged;

  const RecentJobsCard({
    super.key,
    required this.jobs,
    required this.onSeeAllPressed,
    required this.onStatusChanged,
  });

  @override
  State<RecentJobsCard> createState() => _RecentJobsCardState();
}

class _RecentJobsCardState extends State<RecentJobsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jobs.isNotEmpty) {
        Provider.of<ApplicantProvider>(
          context,
          listen: false,
        ).initializeCompanyListeners(widget.jobs[0].companyName);
      }
    });
  }

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
                      'initialJobs': widget.jobs,
                      'onStatusChanged': widget.onStatusChanged,
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
              children:
                  recentJobs
                      .map((job) => _buildJobItem(context, job, jobProvider))
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildJobItem(BuildContext context, Job job, JobProvider jobProvider) {
    return Consumer<ApplicantProvider>(
      builder: (context, applicantProvider, child) {
        final applicantCount = applicantProvider.applicantCounts[job.id] ?? 0;

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
                        onStatusChanged: widget.onStatusChanged,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Initial Circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
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
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$applicantCount Applied',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            job.isActive ? AppColors.success : AppColors.error,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.work_outline, size: 48, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              'No jobs posted yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first job posting to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
