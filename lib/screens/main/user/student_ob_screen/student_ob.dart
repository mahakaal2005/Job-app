import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
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
  
  String _selectedGender = '';
  String _selectedEducationLevel = '';
  DateTime? _selectedDateOfBirth;
  
  // New fields for student model
  List<String> _selectedSkills = [];
  int _weeklyHours = 10;
  List<String> _selectedTimeSlots = [];
  File? _resumeFile;
  String? _resumeFileName;
  bool _isUploadingResume = false;

  // Education level options
  final List<String> _educationLevels = [
    'High School',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Other'
  ];

  // Skills options
  final List<String> _availableSkills = [
    'Data Entry',
    'Content Writing',
    'Social Media Management',
    'Graphic Design',
    'Web Development',
    'Customer Service',
    'Translation',
    'Research',
    'Virtual Assistant',
    'Video Editing',
    'Photography',
    'Marketing',
    'Tutoring',
    'Other'
  ];

  // Time slots options
  final List<String> _availableTimeSlots = [
    'Morning (6AM - 12PM)',
    'Afternoon (12PM - 6PM)',
    'Evening (6PM - 10PM)',
    'Night (10PM - 2AM)',
    'Weekend Only',
    'Flexible'
  ];

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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
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
            (DateTime.now().month == picked.month && DateTime.now().day < picked.day)) {
          age--;
        }
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _resumeFile = File(result.files.single.path!);
          _resumeFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, String>?> _uploadResumeToCloudinary() async {
    if (_resumeFile == null) return null;

    setState(() {
      _isUploadingResume = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dteigt5oc/upload'),
      );

      request.fields['upload_preset'] = 'get_work';
      request.fields['resource_type'] = 'raw';
      request.files.add(
        await http.MultipartFile.fromPath('file', _resumeFile!.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return {
          'url': jsonResponse['secure_url'],
          'public_id': jsonResponse['public_id'],
        };
      } else {
        throw Exception('Upload failed: ${jsonResponse['message']}');
      }
    } catch (e) {
      throw Exception('Failed to upload resume: $e');
    } finally {
      setState(() {
        _isUploadingResume = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 3) { // Updated to 4 pages (0-3)
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
        // Fixed validation - check if all address fields are properly filled
        bool addressValid = _addressController.text.trim().isNotEmpty &&
               _cityController.text.trim().isNotEmpty &&
               _stateController.text.trim().isNotEmpty &&
               _zipController.text.trim().isNotEmpty;
        
        // Debug print to help identify the issue
        print('Address validation: ${_addressController.text.trim()}');
        print('City validation: ${_cityController.text.trim()}');
        print('State validation: ${_stateController.text.trim()}');
        print('ZIP validation: ${_zipController.text.trim()}');
        print('Overall address valid: $addressValid');
        
        return addressValid;
      case 2:
        return _selectedEducationLevel.isNotEmpty &&
               _collegeController.text.trim().isNotEmpty;
      case 3:
        return _selectedSkills.isNotEmpty && _selectedTimeSlots.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_validateCurrentPage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload resume if selected
      Map<String, String>? resumeData;
      if (_resumeFile != null) {
        resumeData = await _uploadResumeToCloudinary();
      }

      // Prepare onboarding data with student model structure
      Map<String, dynamic> onboardingData = {
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDateOfBirth,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _zipController.text.trim(),
        'educationLevel': _selectedEducationLevel,
        'bio': _bioController.text.trim(),
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now(),
        
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
        'resumeUrl': resumeData?['url'],
        'resumeCloudinaryId': resumeData?['public_id'],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
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
                    'Step ${_currentPage + 1} of 4',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 4,
                    backgroundColor: AppColors.grey.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
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
                      onPressed: _isLoading
                          ? null
                          : _currentPage == 3
                              ? _completeOnboarding
                              : _validateCurrentPage()
                                  ? _nextPage
                                  : null,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_currentPage == 3 ? 'Complete Setup' : 'Next'),
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
            onChanged: (value) => setState(() {}), // Trigger rebuild for validation
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
                      color: _selectedDateOfBirth != null
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
            onChanged: (value) => setState(() {}), // Trigger rebuild for validation
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
            onChanged: (value) => setState(() {}), // Trigger rebuild for validation
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        hintText: 'State',
                        prefixIcon: Icon(Icons.map),
                      ),
                      onChanged: (value) => setState(() {}), // Trigger rebuild for validation
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'ZIP',
                        prefixIcon: Icon(Icons.local_post_office),
                      ),
                      onChanged: (value) => setState(() {}), // Trigger rebuild for validation
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
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _educationLevels.map((level) {
                return Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(level),
                      value: level,
                      groupValue: _selectedEducationLevel,
                      onChanged: (value) {
                        setState(() {
                          _selectedEducationLevel = value!;
                        });
                      },
                    ),
                    if (level != _educationLevels.last) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // College/University
          const Text(
            'College/University *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _collegeController,
            decoration: const InputDecoration(
              hintText: 'Enter your college or university name',
              prefixIcon: Icon(Icons.school),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Bio (Optional)
          const Text(
            'Bio (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us a bit about yourself, your interests, or goals...',
              prefixIcon: Icon(Icons.info_outline),
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

          // Skills
          const Text(
            'Skills *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all skills that apply to you:',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSkills.map((skill) {
              bool isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
                selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppColors.primaryBlue,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Weekly Hours
          const Text(
            'Weekly Hours Availability *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Hours per week: $_weeklyHours',
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          Slider(
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
          const SizedBox(height: 20),

          // Preferred Time Slots
          const Text(
            'Preferred Time Slots *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your preferred working hours:',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          Column(
            children: _availableTimeSlots.map((slot) {
              bool isSelected = _selectedTimeSlots.contains(slot);
              return CheckboxListTile(
                title: Text(slot),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedTimeSlots.add(slot);
                    } else {
                      _selectedTimeSlots.remove(slot);
                    }
                  });
                },
                activeColor: AppColors.primaryBlue,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Resume Upload
          const Text(
            'Resume (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your resume to help employers find you:',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (_resumeFile == null) ...[
                  const Icon(
                    Icons.upload_file,
                    size: 48,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No file selected',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickResume,
                    icon: const Icon(Icons.attachment),
                    label: const Text('Choose File'),
                  ),
                ] else ...[
                  const Icon(
                    Icons.description,
                    size: 48,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resumeFileName!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _pickResume,
                        icon: const Icon(Icons.edit),
                        label: const Text('Change'),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _resumeFile = null;
                            _resumeFileName = null;
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
                if (_isUploadingResume) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Uploading resume...'),
                ],
              ],
            ),
          ),
          const Text(
            'Accepted formats: PDF, DOC, DOCX',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}