import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/cd_servi.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/utils/error_handler.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:get_work_app/widgets/phone_input_field.dart';
import 'package:get_work_app/widgets/custom_dropdown_field.dart';
import 'dart:io';

// Enhanced validation result class for employer onboarding
class EmployerValidationResult {
  final bool isValid;
  final int? pageWithError;
  final String? fieldName;
  final String? errorMessage;
  final FocusNode? focusNode;

  EmployerValidationResult({
    required this.isValid,
    this.pageWithError,
    this.fieldName,
    this.errorMessage,
    this.focusNode,
  });

  // Helper constructor for valid result
  EmployerValidationResult.valid() : this(isValid: true);

  // Helper constructor for invalid result
  EmployerValidationResult.invalid({
    required int pageWithError,
    required String fieldName,
    required String errorMessage,
    FocusNode? focusNode,
  }) : this(
          isValid: false,
          pageWithError: pageWithError,
          fieldName: fieldName,
          errorMessage: errorMessage,
          focusNode: focusNode,
        );
}

// Field hint widget for employer onboarding
class EmployerFieldHintWidget extends StatelessWidget {
  final String hint;
  final IconData icon;
  final Color? color;

  const EmployerFieldHintWidget({
    super.key,
    required this.hint,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.lookGigPurple).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? AppColors.lookGigPurple).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? AppColors.lookGigPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.lookGigPurple,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployerOnboardingScreen extends StatefulWidget {
  const EmployerOnboardingScreen({super.key});

  @override
  State<EmployerOnboardingScreen> createState() =>
      _EmployerOnboardingScreenState();
}

class _EmployerOnboardingScreenState extends State<EmployerOnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _isLoading = false;
  bool _isPickingImage = false;
  bool _isPickingDocument = false;

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
  final TextEditingController _EMPLOYERCountController =
      TextEditingController();

  // EMPLOYER Information
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _EMPLOYERIdController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _managerEmailController = TextEditingController();

  // Files
  File? _companyLogo;
  File? _businessLicense;
  File? _EMPLOYERIdCard;
  final List<File> _companyDocuments = [];

  String? _selectedIndustry;
  String _selectedCountryCode = '+91'; // Default to India

  // Visual enhancement fields
  final Map<int, bool> _pageCompletionStatus = {};
  String? _highlightedFieldError;
  final Map<String, String> _fieldHints = {};
  final Map<String, bool> _fieldValidationStatus = {};
  String? _selectedCompanySize;
  String? _selectedEmploymentType;

  @override
  void initState() {
    super.initState();
    _updatePageCompletionStatus();
    
    // Add listeners to update text color when content changes
    _companyNameController.addListener(_onTextChanged);
    _companyEmailController.addListener(_onTextChanged);
    _companyAddressController.addListener(_onTextChanged);
    _companyWebsiteController.addListener(_onTextChanged);
    _EMPLOYERCountController.addListener(_onTextChanged);
    _companyDescriptionController.addListener(_onTextChanged);
    _jobTitleController.addListener(_onTextChanged);
    _departmentController.addListener(_onTextChanged);
    _EMPLOYERIdController.addListener(_onTextChanged);
    _workLocationController.addListener(_onTextChanged);
    _managerNameController.addListener(_onTextChanged);
    _managerEmailController.addListener(_onTextChanged);
    _establishedYearController.addListener(_onTextChanged);
  }

  // Dedicated method to handle text changes and update UI
  void _onTextChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild to update text colors
      });
    }
  }

  // Helper method to get consistent text color for all fields
  Color _getTextColor(TextEditingController controller) {
    return controller.text.trim().isEmpty ? AppColors.hintText : Colors.black;
  }

  // Comprehensive validation helper methods
  String? _validateEmail(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address (e.g., user@gmail.com)';
    }
    
    return null;
  }

  String? _validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company website is required';
    }
    
    String url = value.trim();
    
    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    // Validate URL format
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}(\/.*)?$'
    );
    
    if (!urlRegex.hasMatch(url)) {
      return 'Please enter a valid website URL (e.g., https://www.company.com)';
    }
    
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateNumeric(String? value, String fieldName, {int? minValue, int? maxValue}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final numericValue = int.tryParse(value.trim());
    if (numericValue == null) {
      return '$fieldName must be a valid number';
    }
    
    if (minValue != null && numericValue < minValue) {
      return '$fieldName must be at least $minValue';
    }
    
    if (maxValue != null && numericValue > maxValue) {
      return '$fieldName must be at most $maxValue';
    }
    
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Established year is required';
    }
    
    final year = int.tryParse(value.trim());
    if (year == null) {
      return 'Please enter a valid year';
    }
    
    final currentYear = DateTime.now().year;
    if (year < 1800 || year > currentYear) {
      return 'Please enter a year between 1800 and $currentYear';
    }
    
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }
    
    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

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
    '1-10 Employees',
    '11-50 Employees',
    '51-200 Employees',
    '201-500 Employees',
    '500+ Employees',
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
    _EMPLOYERCountController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _EMPLOYERIdController.dispose();
    _workLocationController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    print('🎯 [PICK_IMAGE] Called for type: $type');
    
    // Prevent multiple simultaneous picker calls
    if (_isPickingImage) {
      print('⚠️ [PICK_IMAGE] Already active, ignoring request');
      return;
    }

    try {
      print('📱 [PICK_IMAGE] Setting picking flag to true');
      setState(() {
        _isPickingImage = true;
      });

      print('📸 [PICK_IMAGE] Creating ImagePicker instance');
      final ImagePicker picker = ImagePicker();
      
      print('🖼️ [PICK_IMAGE] Opening gallery...');
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      print('📊 [PICK_IMAGE] Picker returned: ${image != null ? image.path : 'null (cancelled)'}');

      if (image != null) {
        print('✅ Image selected: ${image.path}');
        
        final file = File(image.path);
        
        // Check if file exists and is accessible
        if (!await file.exists()) {
          _showSnackBar(
            'Unable to access selected file',
            isError: true,
          );
          return;
        }
        
        // Validate file size (max 5MB)
        final fileSize = await file.length();
        print('📊 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        if (fileSize > 5 * 1024 * 1024) {
          _showSnackBar(
            'Image must be less than 5MB',
            isError: true,
          );
          return;
        }

        setState(() {
          if (type == 'logo') {
            _companyLogo = file;
            print('✅ Company logo set: ${file.path}');
            print('   File exists: ${file.existsSync()}');
            _showSnackBar('Logo selected');
          } else if (type == 'idCard') {
            _EMPLOYERIdCard = file;
            print('✅ ID card set: ${file.path}');
            print('   File exists: ${file.existsSync()}');
            _showSnackBar('ID card selected');
          }
        });
        
        // Update page completion status
        _updatePageCompletionStatus();
      } else {
        print('ℹ️ User cancelled image selection');
      }
    } on PlatformException catch (e) {
      print('❌ Platform exception: ${e.code} - ${e.message}');
      
      if (e.code == 'already_active') {
        // Silently ignore - picker was already open
        return;
      } else if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        _showSnackBar(
          'Please grant photo access in settings',
          isError: true,
        );
      } else {
        _showSnackBar(
          'Failed to select image',
          isError: true,
        );
      }
    } catch (e) {
      print('❌ Error selecting image: $e');
      _showSnackBar(
        'Failed to select image',
        isError: true,
      );
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<void> _pickDocument(String type) async {
    // Prevent multiple simultaneous picker calls
    if (_isPickingDocument) {
      print('⚠️ Document picker already active, ignoring request');
      return;
    }

    try {
      setState(() {
        _isPickingDocument = true;
      });

      final typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        print('✅ Document selected: ${file.path}');
        
        final docFile = File(file.path);
        
        // Check if file exists and is accessible
        if (!await docFile.exists()) {
          _showSnackBar(
            'Unable to access selected file',
            isError: true,
          );
          return;
        }
        
        // Validate file size (max 10MB)
        final fileSize = await docFile.length();
        print('📊 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        if (fileSize > 10 * 1024 * 1024) {
          _showSnackBar(
            'Document must be less than 10MB',
            isError: true,
          );
          return;
        }

        setState(() {
          if (type == 'license') {
            _businessLicense = docFile;
            _showSnackBar('License selected');
          } else if (type == 'documents') {
            _companyDocuments.add(docFile);
            _showSnackBar('Document added');
          }
        });
        
        // Update page completion status
        _updatePageCompletionStatus();
      } else {
        print('ℹ️ User cancelled document selection');
      }
    } catch (e) {
      print('❌ Error selecting document: $e');
      _showSnackBar(
        'Failed to select document',
        isError: true,
      );
    } finally {
      setState(() {
        _isPickingDocument = false;
      });
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _companyDocuments.removeAt(index);
    });
  }

  // Skip onboarding confirmation dialog
  Future<bool?> _showSkipConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: const Text(
          'Skip Profile Setup?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.lookGigPurple,
            fontFamily: 'DM Sans',
          ),
        ),
        content: const Text(
          'You can complete your company profile anytime from the Settings section. A complete profile helps you attract better candidates!',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.lookGigDescriptionText,
            fontFamily: 'DM Sans',
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              // Go Back button with light purple background
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lookGigLightPurple,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Skip button with dark purple background
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lookGigPurple,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // Skip onboarding and go to home
  Future<void> _skipOnboarding() async {
    final confirmed = await _showSkipConfirmation();
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔵 [SKIP_ONBOARDING] Starting skip process...');
      
      // Mark onboarding as skipped in Firestore
      await AuthService.skipOnboarding();
      print('✅ [SKIP_ONBOARDING] Firestore updated successfully');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('✅ [SKIP_ONBOARDING] Loading state set to false');

        _showSnackBar('You can complete your profile later from Settings');
        print('✅ [SKIP_ONBOARDING] Toast shown');

        // Use a short delay to ensure the toast is shown and context is stable
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          print('🧭 [SKIP_ONBOARDING] Attempting navigation to ${AppRoutes.employerHome}');
          
          // Use Navigator.of(context, rootNavigator: true) to access the root navigator
          // This ensures we're working with the app's main navigation stack
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            AppRoutes.employerHome,
            (route) => false,
          );
          
          print('✅ [SKIP_ONBOARDING] Navigation command executed');
        } else {
          print('⚠️ [SKIP_ONBOARDING] Widget unmounted after delay, navigation cancelled');
        }
      } else {
        print('⚠️ [SKIP_ONBOARDING] Widget not mounted, skipping navigation');
      }
    } catch (e) {
      print('❌ [SKIP_ONBOARDING] Error occurred: $e');
      print('❌ [SKIP_ONBOARDING] Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        setState(() {
          _isLoading = false;
        });

        _showSnackBar(
          'Error: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _submitOnboarding() async {
    print('🎯 [EMPLOYER ONBOARDING] Starting completion process...');
    
    // Comprehensive validation of ALL pages
    final validationResult = _validateAllPages();
    if (!validationResult.isValid) {
      print('❌ [EMPLOYER ONBOARDING] Validation failed, navigating to problematic page');
      _showValidationError(validationResult);
      _navigateToPageWithError(validationResult);
      return;
    }
    
    print('✅ [EMPLOYER ONBOARDING] All validations passed, proceeding with completion');

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload files to Cloudinary
      String? companyLogoUrl = await CloudinaryService.uploadImage(
        _companyLogo!,
      );
      String? businessLicenseUrl = await CloudinaryService.uploadDocument(
        _businessLicense!,
      );
      String? EMPLOYERIdCardUrl = await CloudinaryService.uploadImage(
        _EMPLOYERIdCard!,
      );

      // Upload additional company documents if any
      List<String> companyDocumentUrls = [];
      if (_companyDocuments.isNotEmpty) {
        List<String?> uploadedUrls =
            await CloudinaryService.uploadMultipleFiles(_companyDocuments);
        companyDocumentUrls = uploadedUrls.whereType<String>().toList();
      }

      // Check if all required files were uploaded successfully
      if (companyLogoUrl == null ||
          businessLicenseUrl == null ||
          EMPLOYERIdCardUrl == null) {
        _showSnackBar(
          'Failed to upload one or more required documents',
          isError: true,
        );
        return;
      }

      // Prepare onboarding data with Cloudinary URLs
      Map<String, dynamic> onboardingData = {
        // Company Information (all required)
        'companyInfo': {
          'companyName': _companyNameController.text.trim(),
          'companyEmail': _companyEmailController.text.trim(),
          'companyPhone': '$_selectedCountryCode ${_companyPhoneController.text.trim()}',
          'companyPhoneCountryCode': _selectedCountryCode,
          'companyPhoneNumber': _companyPhoneController.text.trim(),
          'companyAddress': _companyAddressController.text.trim(),
          'companyWebsite': _companyWebsiteController.text.trim(),
          'companyDescription': _companyDescriptionController.text.trim(),
          'establishedYear': _establishedYearController.text.trim(),
          'EMPLOYERCount': _EMPLOYERCountController.text.trim(),
          'industry': _selectedIndustry,
          'companySize': _selectedCompanySize,
          'companyLogo': companyLogoUrl,
          'businessLicense': businessLicenseUrl,
          'companyDocuments': companyDocumentUrls,
        },
        // EMPLOYER Information
        'EMPLOYERInfo': {
          'jobTitle': _jobTitleController.text.trim(),
          'department': _departmentController.text.trim(),
          'EMPLOYERId': _EMPLOYERIdController.text.trim(),
          'workLocation': _workLocationController.text.trim(),
          'employmentType': _selectedEmploymentType,
          'managerName': _managerNameController.text.trim(),
          'managerEmail': _managerEmailController.text.trim(),
          'EMPLOYERIdCard': EMPLOYERIdCardUrl,
        },
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore using AuthService
      await AuthService.completeUserOnboarding(onboardingData);

      _showSnackBar('EMPLOYER onboarding completed successfully!');

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 1000));

      // Verify role before navigation
      if (mounted) {
        final role = await AuthService.getUserRole();
        final onboardingComplete = await AuthService.hasCurrentUserCompletedOnboarding();
        
        print('ðŸ” DEBUG EMPLOYER Onboarding: Role = $role');
        print('ðŸ” DEBUG EMPLOYER Onboarding: Onboarding Complete = $onboardingComplete');
        print('ðŸ” DEBUG EMPLOYER Onboarding: Navigating to ${AppRoutes.employerHome}');
        
        if (role == 'employer') {
          // Use a short delay to ensure the context is stable
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            print('🧭 [SUBMIT_ONBOARDING] Attempting navigation to ${AppRoutes.employerHome}');
            
            // Use Navigator.of(context, rootNavigator: true) to access the root navigator
            // This ensures we're working with the app's main navigation stack and prevents unmounted widget errors
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              AppRoutes.employerHome,
              (route) => false,
            );
            
            print('✅ [SUBMIT_ONBOARDING] Navigation command executed');
          } else {
            print('⚠️ [SUBMIT_ONBOARDING] Widget unmounted after delay, navigation cancelled');
          }
        } else {
          // Role mismatch - show error
          _showSnackBar(
            'Error: Role mismatch detected. Expected EMPLOYER, got $role. Please contact support.',
            isError: true,
          );
          print('âŒ ERROR: Role mismatch in EMPLOYER onboarding!');
        }
      }
    } catch (e) {
      print('❌ [SUBMIT_ONBOARDING] Error occurred: $e');
      print('❌ [SUBMIT_ONBOARDING] Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        _showSnackBar(
          'Failed to complete onboarding',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false, int? duration, SnackBarAction? action}) {
    if (!mounted) {
      print('⚠️ [SHOW_SNACKBAR] Widget not mounted, skipping toast: $message');
      return;
    }
    
    CustomToast.show(
      context,
      message: message,
      isSuccess: !isError,
      duration: Duration(seconds: duration ?? (isError ? 3 : 2)),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      // Validate and focus first empty field
      if (!_validateAndFocusFirstEmptyField()) {
        return;
      }

      // Update completion status
      _updatePageCompletionStatus();

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
        _EMPLOYERCountController.text.isEmpty) {
      _showSnackBar(
        'Please fill all company information fields',
        isError: true,
      );
      return false;
    }
    return true;
  }

  bool _validateEMPLOYERInfo() {
    if (_jobTitleController.text.isEmpty ||
        _departmentController.text.isEmpty ||
        _EMPLOYERIdController.text.isEmpty ||
        _selectedEmploymentType == null ||
        _workLocationController.text.isEmpty) {
      _showSnackBar(
        'Please fill all required EMPLOYER information fields',
        isError: true,
      );
      return false;
    }
    return true;
  }

  // Enhanced validation for current page (backward compatibility)
  bool _validateAndFocusFirstEmptyField() {
    final result = _validateSpecificPage(_currentPage);
    if (!result.isValid) {
      _showValidationError(result);
      return false;
    }
    return true;
  }

  // Comprehensive validation for ALL pages
  EmployerValidationResult _validateAllPages() {
    print('🔍 [EMPLOYER VALIDATION] Starting comprehensive validation of all pages...');
    
    for (int page = 0; page <= 2; page++) {
      final result = _validateSpecificPage(page);
      if (!result.isValid) {
        print('❌ [EMPLOYER VALIDATION] Found issue on page $page: ${result.errorMessage}');
        return result;
      }
    }
    
    print('✅ [EMPLOYER VALIDATION] All pages validated successfully');
    return EmployerValidationResult.valid();
  }

  // Validate a specific page and return detailed result
  EmployerValidationResult _validateSpecificPage(int pageIndex) {
    switch (pageIndex) {
      case 0: // Company Info page
        if (_companyNameController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Company Name',
            errorMessage: 'Company name is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        if (_companyEmailController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Company Email',
            errorMessage: 'Company email is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        if (_companyPhoneController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Company Phone',
            errorMessage: 'Company phone number is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        if (_companyAddressController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Company Address',
            errorMessage: 'Company address is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        if (_companyWebsiteController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Company Website',
            errorMessage: 'Company website is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        if (_selectedIndustry == null) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Industry',
            errorMessage: 'Please select your industry on Company Information page',
          );
        }
        if (_selectedCompanySize == null) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Company Size',
            errorMessage: 'Please select your company size on Company Information page',
          );
        }
        if (_establishedYearController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Established Year',
            errorMessage: 'Established year is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        if (_EMPLOYERCountController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Employee Count',
            errorMessage: 'Employee count is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        if (_companyDescriptionController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Company Description',
            errorMessage: 'Company description is required on Company Information page',
            focusNode: FocusNode(),
          );
        }
        break;
      
      case 1: // EMPLOYER Info page
        if (_jobTitleController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Job Title',
            errorMessage: 'Your job title is required on Employee Information page',
            focusNode: FocusNode(),
          );
        }
        if (_departmentController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Department',
            errorMessage: 'Department is required on Employee Information page',
            focusNode: FocusNode(),
          );
        }
        if (_EMPLOYERIdController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Employee ID',
            errorMessage: 'Employee ID is required on Employee Information page',
            focusNode: FocusNode(),
          );
        }
        if (_selectedEmploymentType == null) {
          return EmployerValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Employment Type',
            errorMessage: 'Please select your employment type on Employee Information page',
          );
        }
        if (_workLocationController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Work Location',
            errorMessage: 'Work location is required on Employee Information page',
            focusNode: FocusNode(),
          );
        }
        if (_managerNameController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Manager Name',
            errorMessage: 'Manager name is required on Employee Information page',
            focusNode: FocusNode(),
          );
        }
        if (_managerEmailController.text.trim().isEmpty) {
          return EmployerValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Manager Email',
            errorMessage: 'Manager email is required on Employee Information page',
            focusNode: FocusNode(),
          );
        }
        break;
      
      case 2: // Documents page
        if (_companyLogo == null) {
          return EmployerValidationResult.invalid(
            pageWithError: 2,
            fieldName: 'Company Logo',
            errorMessage: 'Company logo is required on Documents & Files page',
          );
        }
        if (_businessLicense == null) {
          return EmployerValidationResult.invalid(
            pageWithError: 2,
            fieldName: 'Business License',
            errorMessage: 'Business license document is required on Documents & Files page',
          );
        }
        if (_EMPLOYERIdCard == null) {
          return EmployerValidationResult.invalid(
            pageWithError: 2,
            fieldName: 'Employee ID Card',
            errorMessage: 'Employee ID card is required on Documents & Files page',
          );
        }
        break;
    }
    
    return EmployerValidationResult.valid();
  }

  // Show validation error with enhanced messaging
  void _showValidationError(EmployerValidationResult result) {
    if (result.isValid) return;
    
    _showSnackBar(
      result.errorMessage ?? 'Please complete all required fields',
      isError: true,
      duration: 4,
      action: SnackBarAction(
        label: 'Go to Page',
        textColor: Colors.white,
        onPressed: () => _navigateToPageWithError(result),
      ),
    );
    
    // Focus on field if it's a text field
    if (result.focusNode != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(result.focusNode!);
      });
    }
  }

  // Navigate to page with validation error
  void _navigateToPageWithError(EmployerValidationResult result) {
    if (result.pageWithError == null) return;
    
    print('🧭 [EMPLOYER NAVIGATION] Auto-navigating to page ${result.pageWithError} for field: ${result.fieldName}');
    
    // Set highlighted field for visual feedback
    setState(() {
      _highlightedFieldError = result.fieldName;
    });
    
    _pageController.animateToPage(
      result.pageWithError!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    // Focus on the field after navigation
    if (result.focusNode != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        FocusScope.of(context).requestFocus(result.focusNode!);
      });
    }
    
    // Clear highlight after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _highlightedFieldError = null;
        });
      }
    });
  }

  // Update page completion status
  void _updatePageCompletionStatus() {
    for (int page = 0; page <= 2; page++) {
      final result = _validateSpecificPage(page);
      _pageCompletionStatus[page] = result.isValid;
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Get completion percentage
  double _getCompletionPercentage() {
    int completedPages = _pageCompletionStatus.values.where((completed) => completed).length;
    return completedPages / 3.0;
  }

  // Get page completion icon
  Widget _getPageCompletionIcon(int pageIndex) {
    final isCompleted = _pageCompletionStatus[pageIndex] ?? false;
    final isCurrentPage = pageIndex == _currentPage;
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted 
            ? Colors.green 
            : isCurrentPage 
                ? AppColors.lookGigPurple 
                : Colors.grey.withOpacity(0.3),
        border: Border.all(
          color: isCurrentPage ? AppColors.lookGigPurple : Colors.transparent,
          width: 2,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check : Icons.circle,
        size: 12,
        color: isCompleted || isCurrentPage ? Colors.white : Colors.grey,
      ),
    );
  }

  // Get page title for progress indicators
  String _getPageTitle(int pageIndex) {
    switch (pageIndex) {
      case 0: return 'Company';
      case 1: return 'Employee';
      case 2: return 'Documents';
      default: return 'Step ${pageIndex + 1}';
    }
  }



  // Get helpful hint for employer fields
  Widget? _getFieldHint(String fieldName) {
    switch (fieldName) {
      case 'Company Email':
        return const EmployerFieldHintWidget(
          hint: 'Enter your official company email address',
          icon: Icons.email_outlined,
        );
      case 'Company Website':
        return const EmployerFieldHintWidget(
          hint: 'Enter your company website URL (e.g., www.company.com)',
          icon: Icons.language_outlined,
        );
      case 'Established Year':
        return const EmployerFieldHintWidget(
          hint: 'Enter the year your company was established',
          icon: Icons.calendar_today_outlined,
        );
      case 'Company Logo':
        return const EmployerFieldHintWidget(
          hint: 'Upload your company logo (PNG, JPG - max 5MB)',
          icon: Icons.image_outlined,
          color: Colors.blue,
        );
      case 'Business License':
        return const EmployerFieldHintWidget(
          hint: 'Upload your business registration or license document',
          icon: Icons.description_outlined,
          color: Colors.orange,
        );
      case 'Employee ID Card':
        return const EmployerFieldHintWidget(
          hint: 'Upload a photo of your employee ID card',
          icon: Icons.badge_outlined,
          color: Colors.green,
        );
      default:
        return null;
    }
  }

  // Show success feedback
  Widget _getSuccessFeedback(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.lookGigPurple,
          secondary: AppColors.lookGigPurple,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.lookGigPurple, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          hintStyle: const TextStyle(color: AppColors.hintText),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EMPLOYER Onboarding'),
          elevation: 0,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          actions: [
            // Skip button in top right
            if (_currentPage < 2)
              TextButton(
                onPressed: _isLoading ? null : _skipOnboarding,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
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
                          color:
                              i <= _currentPage
                                  ? AppColors.lookGigPurple
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
                physics: const NeverScrollableScrollPhysics(), // Prevent swipe to change pages
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  
                  // Debug: Check file status when page changes
                  print('📄 Page changed to: $index');
                  if (_companyLogo != null) {
                    print('   Logo file: ${_companyLogo!.path}');
                    print('   Logo exists: ${_companyLogo!.existsSync()}');
                  } else {
                    print('   Logo: null');
                  }
                  if (_businessLicense != null) {
                    print('   License file: ${_businessLicense!.path}');
                    print('   License exists: ${_businessLicense!.existsSync()}');
                  }
                  if (_EMPLOYERIdCard != null) {
                    print('   ID card file: ${_EMPLOYERIdCard!.path}');
                    print('   ID card exists: ${_EMPLOYERIdCard!.existsSync()}');
                  }
                },
                children: [
                  _buildCompanyInfoPage(),
                  _buildEMPLOYERInfoPage(),
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
                // Previous button (light purple from Figma: #D6CDFE)
                if (_currentPage > 0)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lookGigLightPurple,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          shadowColor: const Color(0x2E99ABC6),
                        ),
                        child: const Text(
                          'PREVIOUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.84,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 15),
                
                // Next/Complete button (dark purple from Figma: #130160)
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                if (_currentPage == 2) {
                                  if (_validateAndFocusFirstEmptyField()) {
                                    _submitOnboarding();
                                  }
                                } else {
                                  _nextPage();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lookGigPurple,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        shadowColor: const Color(0x2E99ABC6),
                        disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
                      ),
                      child:
                          _isLoading
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
                                    ? 'COMPLETE'
                                    : 'NEXT',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.84,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
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
            style: TextStyle(
              color: _getTextColor(_companyNameController),
            ),
            decoration: const InputDecoration(
              labelText: 'Company Name *',
              hintText: 'Enter your company name',
              hintStyle: TextStyle(color: AppColors.hintText),
            ),
            validator: (value) => _validateRequired(value, 'Company name'),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyEmailController,
            style: TextStyle(
              color: _getTextColor(_companyEmailController),
            ),
            decoration: const InputDecoration(
              labelText: 'Company Email *',
              hintText: 'company@example.com',
              hintStyle: TextStyle(color: AppColors.hintText),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _validateEmail(value, 'Company email'),
          ),
          const SizedBox(height: 16),

          PhoneInputField(
            phoneController: _companyPhoneController,
            labelText: 'Company Phone *',
            hintText: '1234567890',
            onCountryCodeChanged: (code) {
              setState(() {
                _selectedCountryCode = code;
              });
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyAddressController,
            style: TextStyle(
              color: _getTextColor(_companyAddressController),
            ),
            decoration: const InputDecoration(
              labelText: 'Company Address *',
              hintText: 'Enter complete address',
              hintStyle: TextStyle(color: AppColors.hintText),
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
            style: TextStyle(
              color: _getTextColor(_companyWebsiteController),
            ),
            decoration: const InputDecoration(
              labelText: 'Company Website *',
              hintText: 'https://www.company.com',
              hintStyle: TextStyle(color: AppColors.hintText),
            ),
            keyboardType: TextInputType.url,
            validator: (value) => _validateWebsite(value),
          ),
          const SizedBox(height: 16),

          CustomDropdownField(
            labelText: 'Industry *',
            hintText: 'Select industry',
            value: _selectedIndustry,
            items: _industries.map((industry) {
              return DropdownItem(value: industry, label: industry);
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIndustry = value;
              });
            },
            enableSearch: true,
            modalTitle: 'Select Industry',
          ),
          const SizedBox(height: 16),

          CustomDropdownField(
            labelText: 'Company Size *',
            hintText: 'Select company size',
            value: _selectedCompanySize,
            items: _companySizes.map((size) {
              return DropdownItem(value: size, label: size);
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCompanySize = value;
              });
            },
            enableSearch: false,
            modalTitle: 'Select Company Size',
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _establishedYearController.text.isEmpty 
                ? null 
                : _establishedYearController.text,
            style: TextStyle(
              color: _getTextColor(_establishedYearController),
            ),
            decoration: const InputDecoration(
              labelText: 'Established Year *',
              hintText: 'Select year',
              hintStyle: TextStyle(color: AppColors.hintText),
            ),
            items: List.generate(
              DateTime.now().year - 1799,
              (index) {
                final year = (DateTime.now().year - index).toString();
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              },
            ),
            onChanged: (value) {
              setState(() {
                _establishedYearController.text = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Established year is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _EMPLOYERCountController,
            style: TextStyle(
              color: _getTextColor(_EMPLOYERCountController),
            ),
            decoration: const InputDecoration(
              labelText: 'Employee Count *',
              hintText: '50',
              hintStyle: TextStyle(color: AppColors.hintText),
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
            style: TextStyle(
              color: _getTextColor(_companyDescriptionController),
            ),
            decoration: const InputDecoration(
              labelText: 'Company Description *',
              hintText: 'Brief description of your company',
              hintStyle: TextStyle(color: AppColors.hintText),
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

  Widget _buildEMPLOYERInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMPLOYER Information',
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
            style: TextStyle(
              color: _getTextColor(_jobTitleController),
            ),
            decoration: const InputDecoration(
              labelText: 'Job Title *',
              hintText: 'Software Developer',
              hintStyle: TextStyle(color: AppColors.hintText),
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
            style: TextStyle(
              color: _getTextColor(_departmentController),
            ),
            decoration: const InputDecoration(
              labelText: 'Department *',
              hintText: 'Engineering',
              hintStyle: TextStyle(color: AppColors.hintText),
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
            controller: _EMPLOYERIdController,
            style: TextStyle(
              color: _getTextColor(_EMPLOYERIdController),
            ),
            decoration: const InputDecoration(
              labelText: 'EMPLOYER ID *',
              hintText: 'EMP001',
              hintStyle: TextStyle(color: AppColors.hintText),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'EMPLOYER ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomDropdownField(
            labelText: 'Employment Type *',
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

          TextFormField(
            controller: _workLocationController,
            style: TextStyle(
              color: _getTextColor(_workLocationController),
            ),
            decoration: const InputDecoration(
              labelText: 'Work Location *',
              hintText: 'New York Office',
              hintStyle: TextStyle(color: AppColors.hintText),
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
            style: TextStyle(
              color: _getTextColor(_managerNameController),
            ),
            decoration: const InputDecoration(
              labelText: 'Manager Name *',
              hintText: 'John Smith',
              hintStyle: TextStyle(color: AppColors.hintText),
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
            style: TextStyle(
              color: _getTextColor(_managerEmailController),
            ),
            decoration: const InputDecoration(
              labelText: 'Manager Email *',
              hintText: 'manager@company.com',
              hintStyle: TextStyle(color: AppColors.hintText),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _validateEmail(value, 'Manager email'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsPage() {
    // Debug: Check file status when building documents page
    print('🏗️ Building documents page');
    if (_companyLogo != null) {
      print('   Logo: ${_companyLogo!.path}');
      print('   Logo exists: ${_companyLogo!.existsSync()}');
    } else {
      print('   Logo: null');
    }
    
    // Calculate completion status
    final bool allRequiredDocsUploaded = 
        _companyLogo != null && 
        _businessLicense != null && 
        _EMPLOYERIdCard != null;
    
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
          const SizedBox(height: 16),
          
          // Completion Status Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: allRequiredDocsUploaded 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: allRequiredDocsUploaded ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allRequiredDocsUploaded ? Icons.check_circle : Icons.info,
                  color: allRequiredDocsUploaded ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allRequiredDocsUploaded
                        ? 'All required documents uploaded! Click COMPLETE to finish.'
                        : 'Please upload all required documents to proceed',
                    style: TextStyle(
                      color: allRequiredDocsUploaded ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Company Logo (Required)
          _buildFileUploadSection(
            title: 'Company Logo *',
            subtitle: 'Upload your company logo (required)',
            file: _companyLogo,
            onTap: () {
              print('🔘 [LOGO_TAP] Company logo section tapped');
              _pickImage('logo');
            },
            isImage: true,
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Business License (Required)
          _buildFileUploadSection(
            title: 'Business License *',
            subtitle:
                'Upload business registration/license document (required)',
            file: _businessLicense,
            onTap: () => _pickDocument('license'),
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // EMPLOYER ID Card (Required)
          _buildFileUploadSection(
            title: 'EMPLOYER ID Card *',
            subtitle: 'Upload your EMPLOYER identification card (required)',
            file: _EMPLOYERIdCard,
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
              foregroundColor: AppColors.lookGigOrange,
              elevation: 0,
            ),
          ),
          const SizedBox(height: 16),

          if (_companyDocuments.isNotEmpty) ...[
            Column(
              children:
                  _companyDocuments.asMap().entries.map((entry) {
                    int index = entry.key;
                    File file = entry.value;
                    String fileName = file.path.split('/').last;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description, color: AppColors.lookGigOrange),
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
          onTap: () {
            print('👆 [GESTURE_TAP] File upload section tapped: $title');
            onTap();
          },
          child: Container(
            width: double.infinity,
            height: isImage ? 150 : 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.grey.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.grey.withOpacity(0.05),
            ),
            child:
                file != null
                    ? isImage
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            file, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Error loading image: $error');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 32,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image unavailable',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.description,
                                size: 24,
                                color: AppColors.lookGigOrange,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                file.path.split('/').last,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lookGigOrange,
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
                          color: isRequired ? Colors.red : AppColors.lookGigOrange,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isImage
                              ? 'Tap to select image'
                              : 'Tap to select file',
                          style: TextStyle(
                            fontSize: 14,
                            color: isRequired ? Colors.red : AppColors.lookGigOrange,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'File uploaded successfully',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
