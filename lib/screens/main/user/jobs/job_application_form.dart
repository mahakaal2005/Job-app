import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/user/jobs/job_application_model.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/services/auth_services.dart';

class JobApplicationForm extends StatefulWidget {
  final Job job;

  const JobApplicationForm({Key? key, required this.job}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService.getUserData();
    setState(() {
      _userData = userData;
    });
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
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              image: DecorationImage(
                image: NetworkImage(
                  widget.job.companyLogo ??
                      'https://via.placeholder.com/800x200?text=Company+Banner',
                ),
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.8),
                  AppColors.royalBlue.withOpacity(0.6),
                ],
              ),
            ),
          ),
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
            _buildResumePreview(),
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

  Widget _buildResumePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
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
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Resume Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userData != null) ...[
            _buildProfileSection(),
            const Divider(height: 32),
            _buildResumeDetails(),
          ] else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(
            _userData?['profileImageUrl'] ?? 'https://via.placeholder.com/60',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userData?['fullName'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userData?['email'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userData?['phone'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumeDetails() {
    // Convert the skills data from List<dynamic> to List<String>
    final List<String> skills =
        (_userData?['skills'] as List<dynamic>?)
            ?.map((skill) => skill.toString())
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      color: AppColors.royalBlue,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
        ),
        if (_userData?['resumeUrl'] != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // Add resume preview functionality
            },
            icon: const Icon(Icons.remove_red_eye_outlined),
            label: const Text('Preview Full Resume'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ],
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
