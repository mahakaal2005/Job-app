import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:get_work_app/widgets/custom_dropdown_field.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/cd_servi.dart';

class EmployerPersonalInfoEditScreen extends StatefulWidget {
  final Map<String, dynamic> employerData;

  const EmployerPersonalInfoEditScreen({
    super.key,
    required this.employerData,
  });

  @override
  State<EmployerPersonalInfoEditScreen> createState() => _EmployerPersonalInfoEditScreenState();
}

class _EmployerPersonalInfoEditScreenState extends State<EmployerPersonalInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingIdCard = false;

  // Text Controllers
  final _fullNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _employerIdController = TextEditingController();
  final _workLocationController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerEmailController = TextEditingController();

  // Dropdown values
  String? _selectedEmploymentType;
  
  // File handling
  File? _selectedIdCard;
  String? _currentIdCardUrl;

  // Employment type options
  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    // Personal information
    _fullNameController.text = widget.employerData['fullName'] ?? '';
    
    // Employer information from EMPLOYERInfo nested object
    final employerInfo = widget.employerData['EMPLOYERInfo'] as Map<String, dynamic>? ?? {};
    _jobTitleController.text = employerInfo['jobTitle'] ?? '';
    _departmentController.text = employerInfo['department'] ?? '';
    _employerIdController.text = employerInfo['EMPLOYERId'] ?? '';
    _workLocationController.text = employerInfo['workLocation'] ?? '';
    _managerNameController.text = employerInfo['managerName'] ?? '';
    _managerEmailController.text = employerInfo['managerEmail'] ?? '';
    _selectedEmploymentType = employerInfo['employmentType'];
    _currentIdCardUrl = employerInfo['EMPLOYERIdCard'];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _employerIdController.dispose();
    _workLocationController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickIdCard() async {
    try {
      setState(() => _isUploadingIdCard = true);

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedIdCard = File(pickedFile.path);
        });
        
        CustomToast.show(
          context,
          message: 'ID card selected successfully',
          isSuccess: true,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: 'Error selecting ID card: $e',
        isSuccess: false,
      );
    } finally {
      setState(() => _isUploadingIdCard = false);
    }
  }

  Future<void> _savePersonalInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Upload new ID card if selected
      String? idCardUrl = _currentIdCardUrl;
      if (_selectedIdCard != null) {
        idCardUrl = await CloudinaryService.uploadImage(_selectedIdCard!);
      }

      // Prepare updated data
      final updatedEmployerInfo = {
        'jobTitle': _jobTitleController.text.trim(),
        'department': _departmentController.text.trim(),
        'EMPLOYERId': _employerIdController.text.trim(),
        'workLocation': _workLocationController.text.trim(),
        'employmentType': _selectedEmploymentType,
        'managerName': _managerNameController.text.trim(),
        'managerEmail': _managerEmailController.text.trim(),
        'EMPLOYERIdCard': idCardUrl,
      };

      final updatedUserData = {
        'fullName': _fullNameController.text.trim(),
        'EMPLOYERInfo': updatedEmployerInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('employers')
          .doc(user.uid)
          .update(updatedUserData);

      // Update profile completion status
      AuthService.updateProfileCompletionStatus();

      if (mounted) {
        CustomToast.show(
          context,
          message: 'Personal information updated successfully!',
          isSuccess: true,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error updating information: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Personal Information',
                      children: [
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _jobTitleController,
                          label: 'Job Title',
                          hint: 'e.g., Software Developer, HR Manager',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Job title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _departmentController,
                          label: 'Department',
                          hint: 'e.g., Engineering, Human Resources',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Department is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _employerIdController,
                          label: 'Employee ID',
                          hint: 'e.g., EMP001, 12345',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Employee ID is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomDropdownField(
                          labelText: 'Employment Type',
                          hintText: 'Select employment type',
                          value: _selectedEmploymentType,
                          items: _employmentTypes.map((type) {
                            return DropdownItem(value: type, label: type);
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedEmploymentType = value;
                            });
                          },
                          enableSearch: false,
                          modalTitle: 'Select Employment Type',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _workLocationController,
                          label: 'Work Location',
                          hint: 'e.g., New York Office, Remote',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Work location is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Manager Information',
                      children: [
                        _buildTextField(
                          controller: _managerNameController,
                          label: 'Manager Name',
                          hint: 'Enter your manager\'s name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Manager name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _managerEmailController,
                          label: 'Manager Email',
                          hint: 'manager@company.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Manager email is required';
                            }
                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Employee ID Card',
                      children: [
                        _buildIdCardSection(),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
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
              padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 16),
              child: Row(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Edit your personal details',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.lookGigProfileText,
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.lookGigProfileText,
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.profileCardShadow,
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.lookGigProfileText,
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.lookGigDescriptionText,
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lookGigPurple, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.profileCardShadow,
            blurRadius: 62,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.badge_outlined,
                color: const Color(0xFFFF9228),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Employee ID Card',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lookGigProfileText,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentIdCardUrl != null || _selectedIdCard != null) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lookGigDescriptionText.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedIdCard != null
                    ? Image.file(_selectedIdCard!, fit: BoxFit.cover)
                    : Image.network(_currentIdCardUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploadingIdCard ? null : _pickIdCard,
              icon: _isUploadingIdCard
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.upload_file, color: AppColors.white),
              label: Text(
                _isUploadingIdCard
                    ? 'Uploading...'
                    : (_currentIdCardUrl != null || _selectedIdCard != null)
                        ? 'Change ID Card'
                        : 'Upload ID Card',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DM Sans',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9228),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePersonalInfo,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lookGigPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)
            : const Text(
                'Save Changes',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DM Sans',
                ),
              ),
      ),
    );
  }
}