import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:get_work_app/widgets/phone_input_field.dart';

class ContactInfoEditScreen extends StatefulWidget {
  final Map<String, dynamic> companyInfo;

  const ContactInfoEditScreen({super.key, required this.companyInfo});

  @override
  State<ContactInfoEditScreen> createState() => _ContactInfoEditScreenState();
}

class _ContactInfoEditScreenState extends State<ContactInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isSaving = false;
  String _selectedCountryCode = '+91'; // Default to India
  String? _phoneError; // Track phone validation error

  @override
  void initState() {
    super.initState();
    _websiteController = TextEditingController(text: widget.companyInfo['companyWebsite'] ?? '');
    _emailController = TextEditingController(text: widget.companyInfo['companyEmail'] ?? '');
    _phoneController = TextEditingController(text: widget.companyInfo['companyPhone'] ?? '');
  }

  // Country-aware phone length validation
  Map<String, int> _getCountryPhoneLengths(String countryCode) {
    final Map<String, Map<String, int>> countryLengths = {
      '+91': {'min': 10, 'max': 10},   // India
      '+1': {'min': 10, 'max': 10},    // US/Canada
      '+44': {'min': 10, 'max': 10},   // UK
      '+61': {'min': 9, 'max': 9},     // Australia
      '+49': {'min': 10, 'max': 11},   // Germany
      '+33': {'min': 9, 'max': 9},     // France
      '+81': {'min': 10, 'max': 10},   // Japan
      '+86': {'min': 11, 'max': 11},   // China
      '+55': {'min': 10, 'max': 11},   // Brazil
      '+7': {'min': 10, 'max': 10},    // Russia
      '+82': {'min': 9, 'max': 10},    // South Korea
      '+52': {'min': 10, 'max': 10},   // Mexico
      '+39': {'min': 9, 'max': 10},    // Italy
      '+34': {'min': 9, 'max': 9},     // Spain
      '+31': {'min': 9, 'max': 9},     // Netherlands
      '+41': {'min': 9, 'max': 9},     // Switzerland
      '+46': {'min': 9, 'max': 10},    // Sweden
      '+65': {'min': 8, 'max': 8},     // Singapore
      '+971': {'min': 9, 'max': 9},    // UAE
      '+966': {'min': 9, 'max': 9},    // Saudi Arabia
      '+27': {'min': 9, 'max': 9},     // South Africa
      '+92': {'min': 10, 'max': 10},   // Pakistan
      '+880': {'min': 10, 'max': 10},  // Bangladesh
      '+94': {'min': 9, 'max': 9},     // Sri Lanka
      '+977': {'min': 10, 'max': 10},  // Nepal
      '+60': {'min': 9, 'max': 10},    // Malaysia
      '+62': {'min': 10, 'max': 12},   // Indonesia
      '+66': {'min': 9, 'max': 9},     // Thailand
      '+63': {'min': 10, 'max': 10},   // Philippines
      '+84': {'min': 9, 'max': 10},    // Vietnam
      '+90': {'min': 10, 'max': 10},   // Turkey
      '+48': {'min': 9, 'max': 9},     // Poland
      '+54': {'min': 10, 'max': 10},   // Argentina
      '+56': {'min': 9, 'max': 9},     // Chile
      '+57': {'min': 10, 'max': 10},   // Colombia
      '+20': {'min': 10, 'max': 10},   // Egypt
      '+234': {'min': 10, 'max': 10},  // Nigeria
      '+254': {'min': 9, 'max': 9},    // Kenya
      '+64': {'min': 9, 'max': 10},    // New Zealand
    };
    
    return countryLengths[countryCode] ?? {'min': 10, 'max': 10};
  }

  // Validate phone number with country-aware rules
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.isEmpty) {
      return 'Please enter a valid phone number';
    }
    
    // Get country-specific requirements
    final countryLengths = _getCountryPhoneLengths(_selectedCountryCode);
    final minLength = countryLengths['min'] ?? 10;
    final maxLength = countryLengths['max'] ?? 10;
    
    // Validate length
    if (cleaned.length < minLength) {
      if (minLength == maxLength) {
        return 'Phone number must be exactly $minLength digits';
      }
      return 'Phone number must be at least $minLength digits';
    }
    if (cleaned.length > maxLength) {
      if (minLength == maxLength) {
        return 'Phone number must be exactly $maxLength digits';
      }
      return 'Phone number must not exceed $maxLength digits';
    }
    
    // Country-specific format rules
    if (_selectedCountryCode == '+91') {
      final firstDigit = cleaned[0];
      if (!['6', '7', '8', '9'].contains(firstDigit)) {
        return 'Indian mobile numbers must start with 6, 7, 8, or 9';
      }
    }
    
    return null; // Valid
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Validate phone first and show error
    final phoneValidationError = _validatePhone(_phoneController.text);
    if (phoneValidationError != null) {
      setState(() {
        _phoneError = phoneValidationError;
      });
      CustomToast.show(
        context,
        message: phoneValidationError,
        isSuccess: false,
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      CustomToast.show(
        context,
        message: 'Please fix all errors before saving',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update in employers collection
        await FirebaseFirestore.instance
            .collection('employers')
            .doc(user.uid)
            .update({
          'companyInfo.companyWebsite': _websiteController.text.trim(),
          'companyInfo.companyEmail': _emailController.text.trim(),
          'companyInfo.companyPhone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update profile completion status
        AuthService.updateProfileCompletionStatus();

        if (mounted) {
          CustomToast.show(
            context,
            message: 'Contact information updated successfully',
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
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Company Website',
                      hint: 'e.g., https://www.company.com',
                      icon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Company Email',
                      hint: 'e.g., contact@company.com',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildPhoneField(),
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
                          'Contact Information',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Edit contact details',
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
              if (keyboardType == TextInputType.emailAddress) {
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email';
                }
              }
              if (keyboardType == TextInputType.url) {
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Phone',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.lookGigProfileText,
          ),
        ),
        const SizedBox(height: 8),
        PhoneInputField(
          phoneController: _phoneController,
          labelText: '',
          hintText: 'Enter phone number',
          onCountryCodeChanged: (countryCode) {
            setState(() {
              _selectedCountryCode = countryCode;
              _phoneError = null; // Clear error on country change
            });
            // Revalidate when country changes
            final error = _validatePhone(_phoneController.text);
            if (error != null) {
              setState(() {
                _phoneError = error;
              });
            }
          },
          validator: (value) {
            final error = _validatePhone(value);
            setState(() {
              _phoneError = error;
            });
            return error;
          },
        ),
        // Display error message prominently
        if (_phoneError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _phoneError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Show hint for current country
        if (_phoneError == null) ...[
          const SizedBox(height: 8),
          Text(
            _getPhoneHint(),
            style: TextStyle(
              color: AppColors.lookGigDescriptionText,
              fontSize: 12,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ],
    );
  }

  String _getPhoneHint() {
    final countryLengths = _getCountryPhoneLengths(_selectedCountryCode);
    final minLength = countryLengths['min'] ?? 10;
    final maxLength = countryLengths['max'] ?? 10;
    
    if (minLength == maxLength) {
      if (_selectedCountryCode == '+91') {
        return 'Enter $minLength digits starting with 6, 7, 8, or 9';
      }
      return 'Enter exactly $minLength digits';
    } else {
      return 'Enter $minLength to $maxLength digits';
    }
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
