import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/provider/applicant_provider.dart';
import 'package:get_work_app/screens/main/employer/new post/edi_jobs_scre.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/image_utils.dart';
import 'package:get_work_app/screens/main/employer/applicants/applicant_details_screen.dart';
import 'package:get_work_app/screens/main/employer/applicants/all_applicants_screen.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:intl/intl.dart';

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
  ApplicantStatusProvider? _statusProvider;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApplicants();
    });
  }

  Future<void> _initializeApplicants() async {
    final applicantProvider = Provider.of<ApplicantProvider>(
      context,
      listen: false,
    );
    _statusProvider = Provider.of<ApplicantStatusProvider>(
      context,
      listen: false,
    );
    // Initialize company-wide listeners
    applicantProvider.initializeCompanyListeners(_job.companyName);
    // Load applicants for this specific job
    await applicantProvider.loadApplicants(_job.companyName, _job.id);
    // Load statuses for this job
    await _statusProvider!.loadJobStatuses(_job.companyName, _job.id);
  }

  @override
  void dispose() {
    // Clear status cache when leaving the screen
    // Use saved reference instead of accessing context in dispose
    _statusProvider?.clearJobCache(_job.companyName, _job.id);
    super.dispose();
  }

  Future<void> _toggleJobStatus() async {
    setState(() => _isLoading = true);

    try {
      await Provider.of<JobProvider>(
        context,
        listen: false,
      ).updateJobStatus(_job.id, !_job.isActive);

      if (!mounted) return;

      setState(() {
        _job = _job.copyWith(isActive: !_job.isActive);
      });

      widget.onStatusChanged(_job.id, _job.isActive);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _job.isActive ? Icons.check_circle : Icons.toggle_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _job.isActive
                        ? 'Job activated successfully'
                        : 'Job deactivated successfully',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to update job status',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditJobScreen(job: _job)),
    );

    if (!mounted) return;

    if (result != null && result is Job) {
      setState(() {
        _job = result;
      });
      if (widget.onJobUpdated != null) {
        widget.onJobUpdated!(result);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Job updated successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
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
      if (!mounted) return;
      
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

        if (!mounted) return;

        Navigator.pop(context); // Close the details screen
        
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Job deleted successfully',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to delete job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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

    if (!mounted) return;

    if (result != null && result is String) {
      try {
        // Use the ApplicantStatusProvider to update the status
        await context.read<ApplicantStatusProvider>().updateStatus(
          companyName: _job.companyName,
          jobId: _job.id,
          applicantId: applicant['id'],
          status: result,
        );

        if (!mounted) return;

        // Refresh the applicants list
        await context.read<ApplicantProvider>().loadApplicants(
          _job.companyName,
          _job.id,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    result == 'accepted' ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Application ${result.toLowerCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor:
                  result == 'accepted' ? Colors.orange : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
      } catch (e) {
        print('Error updating applicant status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: Column(
        children: [
          // Custom Header matching All Job Listings design
          _buildCustomHeader(context),
          // Body Content
          Expanded(
            child: Consumer<ApplicantProvider>(
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
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lookGigPurple,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _job.companyName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.lookGigPurple,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'DM Sans',
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
                                      ? Colors.orange
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
                      const Text(
                        'Job Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lookGigPurple,
                          fontFamily: 'DM Sans',
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
                            'Applicants ($applicantCount)',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lookGigPurple,
                              fontFamily: 'DM Sans',
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
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.lookGigPurple,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'DM Sans',
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
                              style: const TextStyle(
                                color: AppColors.lookGigDescriptionText,
                                fontSize: 16,
                                fontFamily: 'DM Sans',
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
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: ImageUtils.buildSafeCircleAvatar(
                                  radius: 20,
                                  imagePath: applicant['applicantProfileImg'],
                                  child: applicant['applicantProfileImg'] ==
                                                  null ||
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
                                subtitle: Text(
                                  'Applied on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(applicant['appliedAt']))}',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
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
                              color: AppColors.lookGigPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$applicantCount Applicants',
                                  style: const TextStyle(
                                    color: Colors.orange,
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
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoRow(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.lookGigPurple, size: 18),
        const SizedBox(width: 8),
        Text(
          text ?? 'Not specified',
          style: const TextStyle(
            color: AppColors.lookGigDescriptionText,
            fontSize: 14,
            fontFamily: 'DM Sans',
          ),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.lookGigPurple,
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'No $title specified',
            style: const TextStyle(
              color: AppColors.lookGigDescriptionText,
              fontStyle: FontStyle.italic,
              fontFamily: 'DM Sans',
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
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppColors.lookGigPurple,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.lookGigDescriptionText,
                              fontSize: 14,
                              fontFamily: 'DM Sans',
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

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160, // Increased from 140 to 160 to fix overflow
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
                AppColors.lookGigProfileGradientStart,
                AppColors.lookGigProfileGradientEnd,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Job Details',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                      // Action buttons aligned with title
                      GestureDetector(
                        onTap: _isLoading ? null : _toggleJobStatus,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _job.isActive ? Icons.toggle_on : Icons.toggle_off,
                            color: _job.isActive ? Colors.orange : AppColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _editJob,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _deleteJob,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      SizedBox(width: 56), // Align with title (back button width + spacing)
                      Expanded(
                        child: Text(
                          'View and manage job posting',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DM Sans',
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
      ),
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
        return AppColors.lookGigPurple;
    }
  }
}
