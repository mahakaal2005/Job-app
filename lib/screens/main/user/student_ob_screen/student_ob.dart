import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/services/pdf_service.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'skills_list.dart';
import 'package:get_work_app/screens/main/employye/emp_ob/cd_servi.dart';
import 'package:file_selector/file_selector.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() =>
      _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _bioController = TextEditingController();
  final _collegeController = TextEditingController();
  final _ageController = TextEditingController();
  final _customEducationController = TextEditingController();
  final _skillsSearchController = TextEditingController();

  String _selectedGender = '';
  String _selectedEducationLevel = '';
  DateTime? _selectedDateOfBirth;

  // New fields for student model
  List<String> _selectedSkills = [];
  List<String> _filteredSkills = [];
  int _weeklyHours = 10;
  List<String> _selectedTimeSlots = [];
  File? _resumeFile;
  String? _resumeFileName;
  String? _resumePreviewUrl;
  File? _profileImage;
  bool _isUploadingResume = false;
  bool _isUploadingImage = false;

  // Enhanced education level options
  final List<String> _educationLevels = [
    'High School Diploma',
    'High School (In Progress)',
    'Associate Degree',
    'Bachelor\'s Degree',
    'Bachelor\'s Degree (In Progress)',
    'Master\'s Degree',
    'Master\'s Degree (In Progress)',
    'PhD',
    'PhD (In Progress)',
    'Professional Certificate',
    'Trade School',
    'Bootcamp Graduate',
    'Self-Taught',
    'Other',
  ];

  // All skills flattened for search

  // Time slots options
  final List<String> _availableTimeSlots = [
    'Early Morning (5AM - 8AM)',
    'Morning (8AM - 12PM)',
    'Afternoon (12PM - 5PM)',
    'Evening (5PM - 9PM)',
    'Night (9PM - 12AM)',
    'Late Night (12AM - 5AM)',
    'Weekdays Only',
    'Weekends Only',
    'Flexible Schedule',
  ];

  @override
  void initState() {
    super.initState();
    _filteredSkills = [];
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _bioController.dispose();
    _collegeController.dispose();
    _ageController.dispose();
    _customEducationController.dispose();
    _skillsSearchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _filterSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = [];
      } else {
        final queryLower = query.toLowerCase();
        _filteredSkills =
            allSkills
                .where(
                  (skill) =>
                      (skill.toLowerCase().contains(queryLower) ||
                          skill
                              .toLowerCase()
                              .split(' ')
                              .any((word) => word.startsWith(queryLower))) &&
                      !_selectedSkills.contains(skill),
                )
                .take(10)
                .toList();
      }
    });
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        // Calculate age from date of birth
        int age = DateTime.now().year - picked.year;
        if (DateTime.now().month < picked.month ||
            (DateTime.now().month == picked.month &&
                DateTime.now().day < picked.day)) {
          age--;
        }
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageFromSource(ImageSource.camera);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickResume() async {
    try {
      final typeGroup = XTypeGroup(label: 'PDFs', extensions: ['pdf']);

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        setState(() {
          _isUploadingResume = true;
        });

        final fileBytes = await file.readAsBytes();
        final tempFile = File(file.path);
        final fileName = file.name;

        // Use PDFService to handle the upload
        final uploadResult = await PDFService.uploadResumePDF(tempFile);

        if (uploadResult['pdfUrl'] != null) {
          setState(() {
            _resumeFile = tempFile;
            _resumeFileName = fileName;
            _resumePreviewUrl = uploadResult['previewUrl'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resume uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to upload resume');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading resume: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingResume = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      // Updated to 5 pages (0-4)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _phoneController.text.trim().isNotEmpty &&
            _selectedGender.isNotEmpty &&
            _selectedDateOfBirth != null &&
            _ageController.text.trim().isNotEmpty;
      case 1:
        return _addressController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            _stateController.text.trim().isNotEmpty &&
            _zipController.text.trim().isNotEmpty;
      case 2:
        bool educationValid = _selectedEducationLevel.isNotEmpty;
        if (_selectedEducationLevel == 'Other') {
          educationValid =
              educationValid &&
              _customEducationController.text.trim().isNotEmpty;
        }
        return educationValid && _collegeController.text.trim().isNotEmpty;
      case 3:
        return _selectedSkills.isNotEmpty && _selectedTimeSlots.isNotEmpty;
      case 4:
        // Make resume required
        if (_resumeFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload your resume'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_validateCurrentPage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload profile image if selected
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await CloudinaryService.uploadImage(_profileImage!);
        if (profileImageUrl == null) {
          throw Exception('Failed to upload profile image');
        }
      }

      // Upload resume and get URLs if selected
      Map<String, String?> resumeUrls = {};
      if (_resumeFile != null) {
        resumeUrls = await PDFService.uploadResumePDF(_resumeFile!);
        if (resumeUrls['pdfUrl'] == null) {
          throw Exception('Failed to upload resume');
        }
      }

      // Prepare education level
      String finalEducationLevel = _selectedEducationLevel;
      if (_selectedEducationLevel == 'Other' &&
          _customEducationController.text.trim().isNotEmpty) {
        finalEducationLevel = _customEducationController.text.trim();
      }

      // Prepare onboarding data with student model structure
      Map<String, dynamic> onboardingData = {
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _zipController.text.trim(),
        'educationLevel': finalEducationLevel,
        'bio': _bioController.text.trim(),
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),

        // Student model specific fields
        'userType': 'student',
        'name': '', // This should be filled from user's display name
        'age': int.tryParse(_ageController.text.trim()) ?? 18,
        'college': _collegeController.text.trim(),
        'skills': _selectedSkills,
        'availability': {
          'weeklyHours': _weeklyHours,
          'preferredSlots': _selectedTimeSlots,
        },
        'totalEarned': 0.0,
        'upiLinked': false,
        'profileImageUrl': profileImageUrl,
        'resumeUrl': resumeUrls['pdfUrl'],
        'resumePreviewUrl': resumeUrls['previewUrl'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save onboarding data to user profile
      await AuthService.completeUserOnboarding(onboardingData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to user home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userHome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${_currentPage + 1} of 5',
                    style: const TextStyle(fontSize: 16, color: AppColors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 5,
                    backgroundColor: AppColors.grey.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPersonalInfoPage(),
                  _buildAddressPage(),
                  _buildEducationPage(),
                  _buildSkillsAndAvailabilityPage(),
                  _buildProfileAndResumeUploadPage(),
                ],
              ),
            ),

            // Bottom navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _currentPage == 4
                              ? _completeOnboarding
                              : _validateCurrentPage()
                              ? _nextPage
                              : null,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                _currentPage == 4 ? 'Complete Setup' : 'Next',
                              ),
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

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Phone Number
          const Text(
            'Phone Number *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Gender
          const Text(
            'Gender *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Male'),
                  value: 'Male',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('Female'),
                  value: 'Female',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('Other'),
                  value: 'Other',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date of Birth
          const Text(
            'Date of Birth *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDateOfBirth,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.grey),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDateOfBirth != null
                        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                        : 'Select your date of birth',
                    style: TextStyle(
                      color:
                          _selectedDateOfBirth != null
                              ? AppColors.black
                              : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Age (Auto-calculated)
          const Text(
            'Age *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            readOnly: true,
            decoration: const InputDecoration(
              hintText: 'Age will be calculated from date of birth',
              prefixIcon: Icon(Icons.cake),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Address
          const Text(
            'Street Address *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: 'Enter your street address',
              prefixIcon: Icon(Icons.home),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // City
          const Text(
            'City *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: 'Enter your city',
              prefixIcon: Icon(Icons.location_city),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // State and ZIP in a row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'State *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        hintText: 'State',
                        prefixIcon: Icon(Icons.map),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ZIP Code *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'ZIP',
                        prefixIcon: Icon(Icons.local_post_office),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Education & Background',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Education Level
          const Text(
            'Education Level *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value:
                _selectedEducationLevel.isEmpty
                    ? null
                    : _selectedEducationLevel,
            decoration: const InputDecoration(
              hintText: 'Select your education level',
              prefixIcon: Icon(Icons.school),
            ),
            items:
                _educationLevels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedEducationLevel = newValue!;
              });
            },
          ),

          // Custom education field for "Other"
          if (_selectedEducationLevel == 'Other') ...[
            const SizedBox(height: 16),
            const Text(
              'Please specify your education level *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customEducationController,
              decoration: const InputDecoration(
                hintText: 'Enter your education level',
                prefixIcon: Icon(Icons.edit),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],

          const SizedBox(height: 20),

          // College/Institution
          const Text(
            'College/Institution *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _collegeController,
            decoration: const InputDecoration(
              hintText: 'Enter your college or institution name',
              prefixIcon: Icon(Icons.business),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Bio
          const Text(
            'Bio (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Tell us about yourself, your interests, and what you\'re looking for...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsAndAvailabilityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Availability',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Skills Section
          const Text(
            'Skills *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search and select skills that match your expertise',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),

          // Skills search field
          TextFormField(
            controller: _skillsSearchController,
            decoration: InputDecoration(
              hintText: 'Search skills...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _skillsSearchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _skillsSearchController.clear();
                          _filterSkills('');
                        },
                      )
                      : null,
            ),
            onChanged: _filterSkills,
          ),

          // Selected skills chips
          if (_selectedSkills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _selectedSkills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedSkills.remove(skill);
                        });
                      },
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      deleteIconColor: AppColors.primaryBlue,
                    );
                  }).toList(),
            ),
          ],

          // Search results
          if (_skillsSearchController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  _filteredSkills.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No skills found',
                          style: TextStyle(color: AppColors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredSkills.length,
                        itemBuilder: (context, index) {
                          final skill = _filteredSkills[index];
                          return ListTile(
                            title: Text(skill),
                            onTap: () {
                              setState(() {
                                if (!_selectedSkills.contains(skill)) {
                                  _selectedSkills.add(skill);
                                }
                                _skillsSearchController.clear();
                                _filterSkills('');
                              });
                            },
                          );
                        },
                      ),
            ),
          ],
          const SizedBox(height: 24),
          // Weekly Hours
          const Text(
            'Weekly Availability',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'How many hours per week are you available to work?',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weeklyHours.toDouble(),
                  min: 5,
                  max: 40,
                  divisions: 7,
                  label: '$_weeklyHours hours',
                  onChanged: (value) {
                    setState(() {
                      _weeklyHours = value.round();
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_weeklyHours hrs/week',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Time Slots
          const Text(
            'Preferred Time Slots *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your preferred working hours',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),

          Column(
            children:
                _availableTimeSlots.map((timeSlot) {
                  final isSelected = _selectedTimeSlots.contains(timeSlot);
                  return CheckboxListTile(
                    title: Text(timeSlot),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedTimeSlots.add(timeSlot);
                        } else {
                          _selectedTimeSlots.remove(timeSlot);
                        }
                      });
                    },
                    activeColor: AppColors.primaryBlue,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAndResumeUploadPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile & Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a profile photo and upload your resume to stand out',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 24),

          // Profile Image Section
          const Text(
            'Profile Photo (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child:
                      _profileImage != null
                          ? ClipOval(
                            child: Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          )
                          : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.grey,
                          ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickProfileImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryBlue,
                      ),
                      child:
                          _isUploadingImage
                              ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Resume Section
          _buildResumeSection(),

          // Tips section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tips for Success',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• A profile photo increases your chances of getting hired by 40%\n'
                  '• Upload a well-formatted resume to showcase your experience\n'
                  '• Complete profiles get 3x more job opportunities',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Resume',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(' *', style: TextStyle(color: Colors.red, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your resume in PDF format',
          style: TextStyle(fontSize: 14, color: AppColors.grey),
        ),
        const SizedBox(height: 12),
        if (_resumeFile != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _resumeFileName ?? 'Resume uploaded',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploadingResume ? null : _pickResume,
            icon:
                _isUploadingResume
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.upload_file),
            label: Text(
              _resumeFile == null ? 'Upload Resume' : 'Change Resume',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
