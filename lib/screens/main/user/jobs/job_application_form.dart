import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/user/jobs/job_application_model.dart';
import 'package:get_work_app/utils/app_colors.dart';

class JobApplicationForm extends StatefulWidget {
  final Job job;
  final String resumeUrl;

  const JobApplicationForm({
    Key? key,
    required this.job,
    required this.resumeUrl,
  }) : super(key: key);

  @override
  _JobApplicationFormState createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _canRelocate = false;
  bool _availableImmediately = false;
  bool _isResumeCorrect = true;
  bool _isSubmitting = false;
  String? _newResumeUrl;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isResumeCorrect && _newResumeUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a new resume')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Fetch complete user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) throw Exception('User data not found');

      final userData = userDoc.data()!;
      final resumeUrl = _isResumeCorrect ? widget.resumeUrl : _newResumeUrl!;

      // Create application model with all user data
      final application = {
        'userId': user.uid,
        'jobId': widget.job.id,
        'companyId': widget.job.companyName,
        'applicationDate': DateTime.now(),
        'canRelocate': widget.job.workFrom == 'Onsite' ? _canRelocate : null,
        'hireReason': _reasonController.text,
        'availableImmediately': _availableImmediately,
        'resumeUrl': resumeUrl,
        'status': 'Applied',
        // User details
        'userName': userData['name'] ?? '',
        'userEmail': user.email,
        'userPhone': userData['phone'] ?? '',
        'userAge': userData['age'] ?? '',
        'userGender': userData['gender'] ?? '',
        'userBio': userData['bio'] ?? '',
        'userEducation': userData['educationLevel'] ?? '',
        'userCollege': userData['college'] ?? '',
        'userSkills': userData['skills'] ?? [],
        'userAddress': userData['address'] ?? '',
        'userProfilePic': userData['profilePic'] ?? '',
      };

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.job.companyName)
          .collection('jobPostings')
          .doc(widget.job.id)
          .collection('applicants')
          .doc(user.uid)
          .set(application);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting application: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _uploadNewResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() => _isSubmitting = true);
        
        // Initialize Cloudinary
        final cloudinary = Cloudinary.signedConfig(
          apiKey: dotenv.env['CLOUDINARY_API_KEY']!,
          apiSecret: dotenv.env['CLOUDINARY_API_SECRET']!,
          cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME']!,
        );

        // Upload file
        final response = await cloudinary.upload(
          file: result.files.single.path!,
          fileBytes: result.files.single.bytes,
          resourceType: CloudinaryResourceType.auto,
          folder: 'resumes',
        );

        if (response.isSuccessful) {
          // Save to Firebase user profile
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({'resumeUrl': response.secureUrl});

          setState(() {
            _newResumeUrl = response.secureUrl;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading resume: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Application'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application Form',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 20),

              // Relocation question (only for onsite jobs)
              if (widget.job.workFrom == 'Onsite') ...[
                const Text(
                  'Can you relocate to the job location?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _canRelocate,
                      onChanged: (value) => setState(() => _canRelocate = value!),
                      activeColor: AppColors.primaryBlue,
                    ),
                    const Text('Yes'),
                    const SizedBox(width: 20),
                    Radio<bool>(
                      value: false,
                      groupValue: _canRelocate,
                      onChanged: (value) => setState(() => _canRelocate = value!),
                      activeColor: AppColors.primaryBlue,
                    ),
                    const Text('No'),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Why should you be hired question
              const Text(
                'Why should you be hired for this role?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Explain why you are the best candidate...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Availability question
              const Text(
                'Are you available to join immediately?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _availableImmediately,
                    onChanged: (value) => setState(() => _availableImmediately = value!),
                    activeColor: AppColors.primaryBlue,
                  ),
                  const Text('Yes'),
                  const SizedBox(width: 20),
                  Radio<bool>(
                    value: false,
                    groupValue: _availableImmediately,
                    onChanged: (value) => setState(() => _availableImmediately = value!),
                    activeColor: AppColors.primaryBlue,
                  ),
                  const Text('No'),
                ],
              ),
              const SizedBox(height: 20),

              // Resume verification
              const Text(
                'Your Resume',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.resumeUrl.split('/').last,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Is this your current resume?',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _isResumeCorrect,
                            onChanged: (value) => setState(() => _isResumeCorrect = value!),
                            activeColor: AppColors.primaryBlue,
                          ),
                          const Text('Yes'),
                          const SizedBox(width: 20),
                          Radio<bool>(
                            value: false,
                            groupValue: _isResumeCorrect,
                            onChanged: (value) => setState(() => _isResumeCorrect = value!),
                            activeColor: AppColors.primaryBlue,
                          ),
                          const Text('No'),
                        ],
                      ),
                      if (!_isResumeCorrect) ...[
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _uploadNewResume,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Upload New Resume',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        if (_newResumeUrl != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'New resume: ${_newResumeUrl!.split('/').last}',
                            style: const TextStyle(color: AppColors.success),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}