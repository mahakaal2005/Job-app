import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:get_work_app/widgets/custom_dropdown_field.dart';

class CompanyDetailsEditScreen extends StatefulWidget {
  final Map<String, dynamic> companyInfo;

  const CompanyDetailsEditScreen({super.key, required this.companyInfo});

  @override
  State<CompanyDetailsEditScreen> createState() => _CompanyDetailsEditScreenState();
}

class _CompanyDetailsEditScreenState extends State<CompanyDetailsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _EMPLOYERCountController;
  late TextEditingController _establishedYearController;
  String? _selectedCompanySize;
  bool _isSaving = false;

  final List<String> _companySizes = [
    '1-10 Employees',
    '11-50 Employees',
    '51-200 Employees',
    '201-500 Employees',
    '500+ Employees',
  ];

  @override
  void initState() {
    super.initState();
    _EMPLOYERCountController = TextEditingController(text: widget.companyInfo['EMPLOYERCount'] ?? '');
    _establishedYearController = TextEditingController(text: widget.companyInfo['establishedYear'] ?? '');
    
    // Normalize company size value to match dropdown items
    final storedSize = widget.companyInfo['companySize'];
    if (storedSize != null && _companySizes.contains(storedSize)) {
      _selectedCompanySize = storedSize;
    } else if (storedSize != null) {
      // Try to find a case-insensitive match
      _selectedCompanySize = _companySizes.firstWhere(
        (size) => size.toLowerCase() == storedSize.toLowerCase(),
        orElse: () => _companySizes[0],
      );
    }
  }

  @override
  void dispose() {
    _EMPLOYERCountController.dispose();
    _establishedYearController.dispose();
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
          'companyInfo.companySize': _selectedCompanySize,
          'companyInfo.EMPLOYERCount': _EMPLOYERCountController.text.trim(),
          'companyInfo.establishedYear': _establishedYearController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          CustomToast.show(
            context,
            message: 'Company details updated successfully',
            isSuccess: true,
          );
          Navigator.pop(context, true);
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
                    _buildDropdownField(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _EMPLOYERCountController,
                      label: 'Employee Count',
                      hint: 'e.g., 50',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _establishedYearController,
                      label: 'Established Year',
                      hint: 'e.g., 2020',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
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
                          'Company Details',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Edit company size and details',
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
    final List<DropdownItem> companySizeItems = _companySizes.map((size) {
      return DropdownItem(value: size, label: size);
    }).toList();

    return CustomDropdownField(
      labelText: 'Company Size',
      hintText: 'Select company size',
      value: _selectedCompanySize,
      items: companySizeItems,
      onChanged: (value) {
        setState(() {
          _selectedCompanySize = value;
        });
      },
      prefixIcon: Icons.business,
      enableSearch: false,
      modalTitle: 'Select Company Size',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select company size';
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
    TextInputType keyboardType = TextInputType.text,
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
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.lookGigProfileText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.lookGigDescriptionText),
              prefixIcon: Icon(icon, color: const Color(0xFFFF9228)),
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
              if (keyboardType == TextInputType.number) {
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
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
