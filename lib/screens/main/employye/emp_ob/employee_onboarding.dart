import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/emp_ob/cd_servi.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/routes/routes.dart';
import 'dart:io';

class EmployeeOnboardingScreen extends StatefulWidget {
  const EmployeeOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeOnboardingScreen> createState() =>
      _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState extends State<EmployeeOnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _isLoading = false;

  // Company Information
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyWebsiteController =
      TextEditingController();
  final TextEditingController _companyDescriptionController =
      TextEditingController();
  final TextEditingController _establishedYearController =
      TextEditingController();
  final TextEditingController _employeeCountController =
      TextEditingController();

  // Employee Information
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _managerEmailController = TextEditingController();

  // Files
  File? _companyLogo;
  File? _businessLicense;
  File? _employeeIdCard;
  List<File> _companyDocuments = [];

  String? _selectedIndustry;
  String? _selectedCompanySize;
  String? _selectedEmploymentType;

  final List<String> _industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Retail',
    'Construction',
    'Transportation',
    'Hospitality',
    'Other',
  ];

  final List<String> _companySizes = [
    '1-10 employees',
    '11-50 employees',
    '51-200 employees',
    '201-500 employees',
    '500+ employees',
  ];

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _companyWebsiteController.dispose();
    _companyDescriptionController.dispose();
    _establishedYearController.dispose();
    _employeeCountController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    _workLocationController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        if (type == 'logo') {
          _companyLogo = File(image.path);
        } else if (type == 'idCard') {
          _employeeIdCard = File(image.path);
        }
      });
    }
  }

  Future<void> _pickDocument(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (type == 'license') {
          _businessLicense = File(result.files.single.path!);
        } else if (type == 'documents') {
          _companyDocuments.add(File(result.files.single.path!));
        }
      });
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _companyDocuments.removeAt(index);
    });
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    // Additional validation for company documents
    if (_companyLogo == null) {
      _showSnackBar('Company logo is required', isError: true);
      return;
    }

    if (_businessLicense == null) {
      _showSnackBar('Business license is required', isError: true);
      return;
    }

    if (_employeeIdCard == null) {
      _showSnackBar('Employee ID card is required', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll store file paths locally or you can implement your file upload service
      String? companyLogoUrl = _companyLogo!.path;
      String? businessLicenseUrl = _businessLicense!.path;
      String? employeeIdCardUrl = _employeeIdCard!.path;
      List<String> companyDocumentUrls = _companyDocuments.map((doc) => doc.path).toList();

      // Prepare onboarding data
      Map<String, dynamic> onboardingData = {
        // Company Information (all required)
        'companyInfo': {
          'companyName': _companyNameController.text.trim(),
          'companyEmail': _companyEmailController.text.trim(),
          'companyPhone': _companyPhoneController.text.trim(),
          'companyAddress': _companyAddressController.text.trim(),
          'companyWebsite': _companyWebsiteController.text.trim(),
          'companyDescription': _companyDescriptionController.text.trim(),
          'establishedYear': _establishedYearController.text.trim(),
          'employeeCount': _employeeCountController.text.trim(),
          'industry': _selectedIndustry,
          'companySize': _selectedCompanySize,
          'companyLogo': companyLogoUrl,
          'businessLicense': businessLicenseUrl,
          'companyDocuments': companyDocumentUrls,
        },
        // Employee Information
        'employeeInfo': {
          'jobTitle': _jobTitleController.text.trim(),
          'department': _departmentController.text.trim(),
          'employeeId': _employeeIdController.text.trim(),
          'workLocation': _workLocationController.text.trim(),
          'employmentType': _selectedEmploymentType,
          'managerName': _managerNameController.text.trim(),
          'managerEmail': _managerEmailController.text.trim(),
          'employeeIdCard': employeeIdCardUrl,
        },
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore using AuthService
      await AuthService.completeUserOnboarding(onboardingData);

      _showSnackBar('Employee onboarding completed successfully!');

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 1000));

      // Navigate to employee home via AuthWrapper
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Failed to complete onboarding: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryBlue,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      // Validate current page before proceeding
      if (_currentPage == 0 && !_validateCompanyInfo()) {
        return;
      } else if (_currentPage == 1 && !_validateEmployeeInfo()) {
        return;
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCompanyInfo() {
    if (_companyNameController.text.isEmpty ||
        _companyEmailController.text.isEmpty ||
        _companyPhoneController.text.isEmpty ||
        _companyAddressController.text.isEmpty ||
        _selectedIndustry == null ||
        _selectedCompanySize == null ||
        _establishedYearController.text.isEmpty ||
        _employeeCountController.text.isEmpty) {
      _showSnackBar('Please fill all company information fields', isError: true);
      return false;
    }
    return true;
  }

  bool _validateEmployeeInfo() {
    if (_jobTitleController.text.isEmpty ||
        _departmentController.text.isEmpty ||
        _employeeIdController.text.isEmpty ||
        _selectedEmploymentType == null ||
        _workLocationController.text.isEmpty) {
      _showSnackBar('Please fill all required employee information fields', isError: true);
      return false;
    }
    return true;
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Onboarding'),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppColors.primaryBlue
                            : AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          // Page Content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildCompanyInfoPage(),
                  _buildEmployeeInfoPage(),
                  _buildDocumentsPage(),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _previousPage,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_currentPage == 2) {
                              _submitOnboarding();
                            } else {
                              _nextPage();
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _currentPage == 2
                                ? 'Complete Onboarding'
                                : 'Next',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'All company details are required',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              labelText: 'Company Name *',
              hintText: 'Enter your company name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyEmailController,
            decoration: const InputDecoration(
              labelText: 'Company Email *',
              hintText: 'company@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyPhoneController,
            decoration: const InputDecoration(
              labelText: 'Company Phone *',
              hintText: '+1234567890',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company phone is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyAddressController,
            decoration: const InputDecoration(
              labelText: 'Company Address *',
              hintText: 'Enter complete address',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyWebsiteController,
            decoration: const InputDecoration(
              labelText: 'Company Website *',
              hintText: 'https://www.company.com',
            ),
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company website is required';
              }
              if (!value.startsWith('http://') && !value.startsWith('https://')) {
                return 'Please include http:// or https://';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedIndustry,
            decoration: const InputDecoration(labelText: 'Industry *'),
            items: _industries.map((industry) {
              return DropdownMenuItem(
                value: industry,
                child: Text(industry),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIndustry = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an industry';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedCompanySize,
            decoration: const InputDecoration(labelText: 'Company Size *'),
            items: _companySizes.map((size) {
              return DropdownMenuItem(value: size, child: Text(size));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCompanySize = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select company size';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _establishedYearController,
            decoration: const InputDecoration(
              labelText: 'Established Year *',
              hintText: '2020',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Established year is required';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid year';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _employeeCountController,
            decoration: const InputDecoration(
              labelText: 'Employee Count *',
              hintText: '50',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Employee count is required';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Company Description *',
              hintText: 'Brief description of your company',
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company description is required';
              }
              if (value.trim().length < 30) {
                return 'Description should be at least 30 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employee Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your role and position details',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _jobTitleController,
            decoration: const InputDecoration(
              labelText: 'Job Title *',
              hintText: 'Software Developer',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Job title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Department *',
              hintText: 'Engineering',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Department is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _employeeIdController,
            decoration: const InputDecoration(
              labelText: 'Employee ID *',
              hintText: 'EMP001',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Employee ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedEmploymentType,
            decoration: const InputDecoration(labelText: 'Employment Type *'),
            items: _employmentTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEmploymentType = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select employment type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _workLocationController,
            decoration: const InputDecoration(
              labelText: 'Work Location *',
              hintText: 'New York Office',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Work location is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _managerNameController,
            decoration: const InputDecoration(
              labelText: 'Manager Name *',
              hintText: 'John Smith',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Manager name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _managerEmailController,
            decoration: const InputDecoration(
              labelText: 'Manager Email *',
              hintText: 'manager@company.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Manager email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documents & Files',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'All documents are required for verification',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Company Logo (Required)
          _buildFileUploadSection(
            title: 'Company Logo *',
            subtitle: 'Upload your company logo (required)',
            file: _companyLogo,
            onTap: () => _pickImage('logo'),
            isImage: true,
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Business License (Required)
          _buildFileUploadSection(
            title: 'Business License *',
            subtitle: 'Upload business registration/license document (required)',
            file: _businessLicense,
            onTap: () => _pickDocument('license'),
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Employee ID Card (Required)
          _buildFileUploadSection(
            title: 'Employee ID Card *',
            subtitle: 'Upload your employee identification card (required)',
            file: _employeeIdCard,
            onTap: () => _pickImage('idCard'),
            isImage: true,
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Additional Company Documents (Optional)
          const Text(
            'Additional Company Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload any other relevant company documents (optional)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => _pickDocument('documents'),
            icon: const Icon(Icons.add),
            label: const Text('Add Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey.withOpacity(0.1),
              foregroundColor: AppColors.primaryBlue,
              elevation: 0,
            ),
          ),
          const SizedBox(height: 16),

          if (_companyDocuments.isNotEmpty) ...[
            Column(
              children: _companyDocuments.asMap().entries.map((entry) {
                int index = entry.key;
                File file = entry.value;
                String fileName = file.path.split('/').last;

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(
                      fileName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeDocument(index),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileUploadSection({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    bool isImage = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: isImage ? 150 : 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: isRequired && file == null
                    ? Colors.red
                    : AppColors.grey.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.grey.withOpacity(0.05),
            ),
            child: file != null
                ? isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(file, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.description,
                              size: 24,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              file.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isImage ? Icons.image : Icons.upload_file,
                        size: 32,
                        color: isRequired ? Colors.red : AppColors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isImage ? 'Tap to select image' : 'Tap to select file',
                        style: TextStyle(
                          fontSize: 14,
                          color: isRequired ? Colors.red : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (isRequired && file == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'This document is required',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}