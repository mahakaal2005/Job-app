import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/user/jobs/job_application_model.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/services/auth_services.dart';

class JobApplicationForm extends StatefulWidget {
  final Job job;

  const JobApplicationForm({super.key, required this.job});

  @override
  State<JobApplicationForm> createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _whyJoinController = TextEditingController();
  final _experienceController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasAlreadyApplied = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkIfAlreadyApplied();
  }

  Future<void> _checkIfAlreadyApplied() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final applicationSnapshot =
          await _firestore
              .collection('jobs')
              .doc(widget.job.companyName)
              .collection('jobPostings')
              .doc(widget.job.id)
              .collection('applicants')
              .where('applicantId', isEqualTo: user.uid)
              .get();

      if (mounted) {
        setState(() {
          _hasAlreadyApplied = applicationSnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking application status: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser!;
      final applicationId =
          '${user.uid}_${widget.job.id}_${DateTime.now().millisecondsSinceEpoch}';

      // Fetch user profile data
      final userData = await AuthService.getUserData();
      if (userData == null) {
        throw Exception('User profile data not found');
      }

      final application = JobApplication(
        id: applicationId,
        jobId: widget.job.id,
        jobTitle: widget.job.title,
        companyName: widget.job.companyName,
        applicantId: user.uid,
        applicantName: userData['fullName'] ?? user.displayName ?? '',
        applicantEmail: user.email ?? '',
        applicantPhone: userData['phone'] ?? user.phoneNumber ?? '',
        applicantAddress: userData['address'] ?? '',
        applicantSkills: List<String>.from(userData['skills'] ?? []),
        applicantProfileImg: userData['profileImageUrl'] ?? user.photoURL ?? '',
        applicantGender: userData['gender'] ?? '',
        resumeUrl: userData['resumeUrl'] ?? '',
        resumePreviewUrl: userData['resumePreviewUrl'],
        whyJoin: _whyJoinController.text.trim(),
        yearsOfExperience: _experienceController.text.trim(),
        appliedAt: DateTime.now(),
      );

      await _firestore
          .collection('jobs')
          .doc(widget.job.companyName)
          .collection('jobPostings')
          .doc(widget.job.id)
          .collection('applicants')
          .doc(applicationId)
          .set(application.toJson());

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasAlreadyApplied) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: 24),
                Text(
                  'Already Applied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You have already applied for this position.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildForm(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Image
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedText.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Apply for ${widget.job.title}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'at ${widget.job.companyName}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumeSection(),
            const SizedBox(height: 20),
            _buildApplicationFormCard(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeSection() {
    if (_userData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mutedText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.royalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Resume',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Show resume filename if available
          if (_userData?['resumeFileName'] != null) ...[
            Text(
              'Current Resume: ${_userData!['resumeFileName']}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Resume Preview and PDF View
          if (_userData?['resumePreviewUrl'] != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.mutedText.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _userData!['resumePreviewUrl']!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: AppColors.primaryBlue,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load resume preview',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            // Show message if no resume is uploaded
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error.withOpacity(0.8),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Please upload your resume in your profile before applying',
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicationFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mutedText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.royalBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Application Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _whyJoinController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Why do you want to join this company?',
              hintText: 'Share your motivation and interest in this role...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.mutedText.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue),
              ),
              filled: true,
              fillColor: AppColors.backgroundColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please tell us why you want to join';
              }
              if (value.trim().length < 20) {
                return 'Please provide a more detailed answer (at least 20 characters)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _experienceController,
            decoration: InputDecoration(
              labelText: 'Years of experience in this field',
              hintText: 'e.g., 2 years, 6 months, Fresh Graduate',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.mutedText.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue),
              ),
              filled: true,
              fillColor: AppColors.backgroundColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your experience level';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: !_isSubmitting ? _submitApplication : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Submit Application',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _whyJoinController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}
