import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:get_work_app/widgets/custom_dropdown_field.dart';

class CompanyInfoEditScreen extends StatefulWidget {
  final Map<String, dynamic> companyInfo;

  const CompanyInfoEditScreen({super.key, required this.companyInfo});

  @override
  State<CompanyInfoEditScreen> createState() => _CompanyInfoEditScreenState();
}

class _CompanyInfoEditScreenState extends State<CompanyInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  String? _selectedIndustry;
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.companyInfo['companyName'] ?? '');
    _selectedIndustry = widget.companyInfo['industry'];
    _addressController = TextEditingController(text: widget.companyInfo['companyAddress'] ?? '');
    _descriptionController = TextEditingController(text: widget.companyInfo['companyDescription'] ?? '');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update in employers collection
        await FirebaseFirestore.instance
            .collection('employers')
            .doc(user.uid)
            .update({
          'companyInfo.companyName': _companyNameController.text.trim(),
          'companyInfo.industry': _selectedIndustry,
          'companyInfo.companyAddress': _addressController.text.trim(),
          'companyInfo.companyDescription': _descriptionController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update profile completion status
        AuthService.updateProfileCompletionStatus();

        if (mounted) {
          CustomToast.show(
            context,
            message: 'Company information updated successfully',
            isSuccess: true,
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error saving: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
                  children: [
                    _buildTextField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      hint: 'Enter company name',
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Company Address',
                      hint: 'Enter full address',
                      icon: Icons.location_on,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Company Description',
                      hint: 'Describe your company',
                      icon: Icons.description,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
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
                          'Company Information',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Edit company details',
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

  Widget _buildDropdownField() {
    final List<DropdownItem> industryItems = _industries.map((industry) {
      return DropdownItem(value: industry, label: industry);
    }).toList();

    return CustomDropdownField(
      labelText: 'Industry',
      hintText: 'Select industry',
      value: _selectedIndustry,
      items: industryItems,
      onChanged: (value) {
        setState(() {
          _selectedIndustry = value;
        });
      },
      prefixIcon: Icons.business_center,
      enableSearch: true,
      modalTitle: 'Select Industry',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an industry';
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
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
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.lookGigProfileText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.lookGigDescriptionText),
              prefixIcon: maxLines > 1
                  ? Align(
                      alignment: Alignment.topLeft,
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, top: 16),
                        child: Icon(icon, color: const Color(0xFFFF9228)),
                      ),
                    )
                  : Icon(icon, color: const Color(0xFFFF9228)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF9228), width: 2),
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lookGigPurple,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
