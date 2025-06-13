import 'package:flutter/material.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/screens/main/employye/new%20post/edi_jobs_scre.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/employye/applicants/applicant_details_screen.dart';
import 'package:get_work_app/screens/main/employye/applicants/all_applicants_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;
  final Function(String, bool) onStatusChanged;
  final Function(String)? onJobDeleted;
  final Function(Job)? onJobUpdated;

  const JobDetailsScreen({
    Key? key,
    required this.job,
    required this.onStatusChanged,
    this.onJobDeleted,
    this.onJobUpdated,
  }) : super(key: key);

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late Job _job;
  bool _isLoading = false;
  List<Map<String, dynamic>> _applicants = [];

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      final applicantsSnapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(_job.companyName)
              .collection('jobPostings')
              .doc(_job.id)
              .collection('applicants')
              .orderBy('appliedAt', descending: true)
              .limit(3)
              .get();

      final List<Map<String, dynamic>> applicants = [];
      for (var doc in applicantsSnapshot.docs) {
        final data = doc.data();
        applicants.add(data);
      }

      // Update applicants count in jobPostings collection
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(_job.companyName)
          .collection('jobPostings')
          .doc(_job.id)
          .update({'applicantsCount': applicants.length});

      setState(() {
        _applicants = applicants;
      });
    } catch (e) {
      print('Error loading applicants: $e');
    }
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
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update job status: $e'),
          backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Job',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this job posting? This action cannot be undone.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.whiteText),
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
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete job: $e'),
            backgroundColor: AppColors.error,
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
      // Update applicant status in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(_job.companyName)
            .collection('jobPostings')
            .doc(_job.id)
            .collection('applicants')
            .doc(applicant['id'])
            .update({'status': result});

        // Refresh applicants list
        _loadApplicants();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Application ${result.toLowerCase()}',
              style: const TextStyle(color: AppColors.whiteText),
            ),
            backgroundColor:
                result == 'accepted' ? AppColors.success : AppColors.error,
          ),
        );
      } catch (e) {
        print('Error updating applicant status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update application status'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          'Job Details',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.whiteText),
            onPressed: _editJob,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.whiteText),
            onPressed: _deleteJob,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _job.companyName,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.primaryBlue,
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
                                  ? AppColors.success
                                  : AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _job.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _job.location,
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
                        _job.employmentType,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Applicants Section
            Container(
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
                        'Applicants (${_applicants.length})',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
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
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_applicants.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No applicants yet',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _applicants.length,
                      itemBuilder: (context, index) {
                        final applicant = _applicants[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  applicant['applicantProfileImg'] != null &&
                                          applicant['applicantProfileImg']
                                              .isNotEmpty
                                      ? NetworkImage(
                                        applicant['applicantProfileImg'],
                                      )
                                      : null,
                              child:
                                  applicant['applicantProfileImg'] == null ||
                                          applicant['applicantProfileImg']
                                              .isEmpty
                                      ? Text(
                                        applicant['applicantName'][0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : null,
                            ),
                            title: Text(
                              applicant['applicantName'] ?? 'Anonymous',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Experience: ${applicant['yearsOfExperience']}',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                Text(
                                  'Status: ${applicant['status'] ?? 'Pending'}',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.arrow_forward_ios, size: 16),
                              onPressed: () => _showApplicantDetails(applicant),
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
                        'Job Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              color: AppColors.primaryBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_applicants.length} Applicants',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
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
                      color: AppColors.secondaryText,
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
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Posted on ${_formatDate(_job.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
