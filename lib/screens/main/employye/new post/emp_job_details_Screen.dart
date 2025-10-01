import 'package:flutter/material.dart';
import 'package:get_work_app/provider/applicant_provider.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/screens/main/employye/applicants/all_applicants_screen.dart';
import 'package:get_work_app/screens/main/employye/applicants/applicant_details_screen.dart';
import 'package:get_work_app/screens/main/employye/new%20post/edi_jobs_scre.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;
  final Function(String, bool) onStatusChanged;
  final Function(String)? onJobDeleted;
  final Function(Job)? onJobUpdated;

  const JobDetailsScreen({
    super.key,
    required this.job,
    required this.onStatusChanged,
    this.onJobDeleted,
    this.onJobUpdated,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late Job _job;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _initializeApplicants();
  }

  Future<void> _initializeApplicants() async {
    final applicantProvider = Provider.of<ApplicantProvider>(
      context,
      listen: false,
    );
    final statusProvider = Provider.of<ApplicantStatusProvider>(
      context,
      listen: false,
    );
    // Initialize company-wide listeners
    applicantProvider.initializeCompanyListeners(_job.companyName);
    // Load applicants for this specific job
    await applicantProvider.loadApplicants(_job.companyName, _job.id);
    // Load statuses for this job
    await statusProvider.loadJobStatuses(_job.companyName, _job.id);
  }

  @override
  void dispose() {
    // Clear status cache when leaving the screen
    Provider.of<ApplicantStatusProvider>(
      context,
      listen: false,
    ).clearJobCache(_job.companyName, _job.id);
    super.dispose();
  }

  Future<void> _toggleJobStatus() async {
    setState(() => _isLoading = true);

    try {
      await Provider.of<JobProvider>(
        context,
        listen: false,
      ).updateJobStatus(_job.id, !_job.isActive);

      setState(() {
        _job = _job.copyWith(isActive: !_job.isActive);
      });

      widget.onStatusChanged(_job.id, _job.isActive);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _job.isActive
                ? 'Job activated successfully'
                : 'Job deactivated successfully',
          ),
          backgroundColor: AppColors.primaryAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update job status: $e'),
          backgroundColor: AppColors.primaryAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditJobScreen(job: _job)),
    );

    if (result != null && result is Job) {
      setState(() {
        _job = result;
      });
      if (widget.onJobUpdated != null) {
        widget.onJobUpdated!(result);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job updated successfully'),
          backgroundColor: AppColors.primaryAccent,
        ),
      );
    }
  }

  Future<void> _deleteJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Job',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this job posting? This action cannot be undone.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.textOnAccent),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await Provider.of<JobProvider>(
          context,
          listen: false,
        ).deleteJob(_job.id);

        // Notify parent screens about the deletion
        if (widget.onJobDeleted != null) {
          widget.onJobDeleted!(_job.id);
        }

        Navigator.pop(context); // Close the details screen

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted successfully'),
            backgroundColor: AppColors.primaryAccent,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete job: $e'),
            backgroundColor: AppColors.primaryAccent,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showApplicantDetails(Map<String, dynamic> applicant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ApplicantDetailsScreen(
              applicant: applicant,
              jobTitle: _job.title,
            ),
      ),
    );

    if (result != null && result is String) {
      try {
        // Use the ApplicantStatusProvider to update the status
        await context.read<ApplicantStatusProvider>().updateStatus(
          companyName: _job.companyName,
          jobId: _job.id,
          applicantId: applicant['id'],
          status: result,
        );

        // Refresh the applicants list
        await context.read<ApplicantProvider>().loadApplicants(
          _job.companyName,
          _job.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Application ${result.toLowerCase()}',
                style: const TextStyle(color: AppColors.textOnAccent),
              ),
              backgroundColor:
                  result == 'accepted'
                      ? AppColors.primaryAccent
                      : AppColors.primaryAccent,
            ),
          );
        }
      } catch (e) {
        print('Error updating applicant status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: AppColors.textOnAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _job.isActive ? Icons.toggle_on : Icons.toggle_off,
              color:
                  _job.isActive
                      ? AppColors.primaryAccent
                      : AppColors.primaryAccent,
              size: 30,
            ),
            onPressed: _isLoading ? null : _toggleJobStatus,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textOnAccent),
            onPressed: _editJob,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.textOnAccent),
            onPressed: _deleteJob,
          ),
        ],
      ),
      body: Consumer<ApplicantProvider>(
        builder: (context, applicantProvider, child) {
          final applicants = applicantProvider.applicants[_job.id] ?? [];
          final applicantCount =
              applicantProvider.applicantCounts[_job.id] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _job.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _job.companyName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.primaryAccent,
                                    fontWeight: FontWeight.w600,
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
                                  _job.isActive
                                      ? AppColors.primaryAccent
                                      : AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _job.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: AppColors.textOnAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.location_on, _job.location),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.work_outline, _job.employmentType),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.trending_up, _job.experienceLevel),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.work_outlined, _job.workFrom),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.currency_rupee, _job.salaryRange),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Job Details Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
                      Text(
                        'Job Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSection('Required Skills', _job.requiredSkills),
                      const SizedBox(height: 16),
                      _buildSection('Responsibilities', _job.responsibilities),
                      const SizedBox(height: 16),
                      _buildSection('Requirements', _job.requirements),
                      const SizedBox(height: 16),
                      _buildSection('Benefits', _job.benefits),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Applicants Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
                            'Applicants ($applicantCount)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AllApplicantsScreen(
                                        jobId: _job.id,
                                        companyName: _job.companyName,
                                        jobTitle: _job.title,
                                      ),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (applicants.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No applicants yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: applicants.length,
                          itemBuilder: (context, index) {
                            final applicant = applicants[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      applicant['applicantProfileImg'] !=
                                                  null &&
                                              applicant['applicantProfileImg']
                                                  .isNotEmpty
                                          ? NetworkImage(
                                            applicant['applicantProfileImg'],
                                          )
                                          : null,
                                  child:
                                      applicant['applicantProfileImg'] ==
                                                  null ||
                                              applicant['applicantProfileImg']
                                                  .isEmpty
                                          ? Text(
                                            applicant['applicantName'][0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: AppColors.primaryAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : null,
                                ),
                                title: Text(
                                  applicant['applicantName'] ?? 'Anonymous',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  'Applied on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(applicant['appliedAt']))}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Consumer<ApplicantStatusProvider>(
                                  builder: (context, provider, child) {
                                    final currentStatus = provider.getStatus(
                                      _job.companyName,
                                      _job.id,
                                      applicant['id'],
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          currentStatus,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        currentStatus.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(currentStatus),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                onTap: () => _showApplicantDetails(applicant),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
                            'Job Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: AppColors.primaryAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$applicantCount Applicants',
                                  style: TextStyle(
                                    color: AppColors.primaryAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _job.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Posted on ${_formatDate(_job.createdAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoRow(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          text ?? 'Not specified',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'No $title specified',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
      ],
    );
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
        return AppColors.primaryAccent;
    }
  }
}
