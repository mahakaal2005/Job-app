import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/cd_servi.dart';
import 'package:get_work_app/screens/main/employer/profile/employer_settings_screen.dart';
import 'package:get_work_app/screens/main/employer/profile/company_info_edit_screen.dart';
import 'package:get_work_app/screens/main/employer/profile/company_details_edit_screen.dart';
import 'package:get_work_app/screens/main/employer/profile/contact_info_edit_screen.dart';
import 'package:get_work_app/screens/main/employer/profile/company_logo_edit_screen.dart';
import 'package:get_work_app/screens/main/employer/profile/employer_personal_info_edit_screen.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/error_handler.dart';
import 'package:get_work_app/widgets/profile_completion_widget.dart';

import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class EmpProfile extends StatefulWidget {
  const EmpProfile({super.key});

  @override
  State<EmpProfile> createState() => _EmpProfileState();
}

class _EmpProfileState extends State<EmpProfile> {
  Map<String, dynamic>? employerData;
  Map<String, dynamic>? companyInfo;
  bool isEditing = false;
  bool isUploadingLogo = false;
  bool isLoading = true;
  int _jobCount = 0; // Count of jobs posted by employer
  
  // Profile completion tracking
  bool _profileCompleted = true;
  int _profileCompletionPercentage = 100;
  bool _skippedOnboarding = false;

  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyDescriptionController =
      TextEditingController();
  final TextEditingController _companyWebsiteController =
      TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _EMPLOYERCountController =
      TextEditingController();
  final TextEditingController _establishedYearController =
      TextEditingController();

  String? logoUrl;
  final ImagePicker _picker = ImagePicker();

  // Add company size options
  final List<String> _companySizes = [
    '1-10 EMPLOYERs',
    '11-50 EMPLOYERs',
    '51-200 EMPLOYERs',
    '201-500 EMPLOYERs',
    '500+ EMPLOYERs',
  ];
  String? _selectedCompanySize;

  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEmployerData();
      // Refresh profile completion data when screen loads
      // Profile completion refresh temporarily disabled
    });
  }

  Future<void> _fetchEmployerData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final userData = await AuthService.getUserData();
      final companyData = await AuthService.getEMPLOYERCompanyInfo();
      // Profile completion status removed
      
      // Fetch job count from nested collection structure
      if (companyData != null && companyData['companyName'] != null) {
        final companyName = companyData['companyName'];
        final jobsSnapshot = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(companyName)
            .collection('jobPostings')
            .get();
        _jobCount = jobsSnapshot.docs.length;
      }

      if (mounted) {
        setState(() {
          employerData = userData;
          companyInfo = companyData;
          logoUrl = companyData?['companyLogo'] ?? '';
          _selectedCompanySize = companyData?['companySize'];
          
          // Set profile completion data - simplified
          _skippedOnboarding = userData?['skippedOnboarding'] ?? false;
          _profileCompletionPercentage = 100; // Always complete
          _profileCompleted = true; // Always complete
          
          _populateControllers();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching employer data: $e');
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading profile data: $e', isError: true);
    }
  }

  void _populateControllers() {
    if (companyInfo != null) {
      _industryController.text = companyInfo?['industry'] ?? '';
      _companyAddressController.text = companyInfo?['companyAddress'] ?? '';
      _companyDescriptionController.text =
          companyInfo?['companyDescription'] ?? '';
      _companyWebsiteController.text = companyInfo?['companyWebsite'] ?? '';
      _companyEmailController.text = companyInfo?['companyEmail'] ?? '';
      _companyPhoneController.text = companyInfo?['companyPhone'] ?? '';
      _EMPLOYERCountController.text = companyInfo?['EMPLOYERCount'] ?? '';
      _establishedYearController.text = companyInfo?['establishedYear'] ?? '';
      logoUrl = companyInfo?['companyLogo'];
    }
  }

  Future<void> _uploadLogo() async {
    try {
      setState(() {
        isUploadingLogo = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final String? uploadedUrl = await CloudinaryService.uploadImage(
          imageFile,
        );

        if (uploadedUrl != null) {
          setState(() {
            logoUrl = uploadedUrl;
          });

          // Update in Firestore
          await _updateProfileField('companyLogo', logoUrl!);

          _showSnackBar('Logo updated successfully!');
        } else {
          _showSnackBar('Failed to upload logo', isError: true);
        }
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
      debugPrint('Logo upload error: $e');
    } finally {
      setState(() {
        isUploadingLogo = false;
      });
    }
  }

  Future<void> _updateProfileField(String field, dynamic value) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({field: value});
      } catch (e) {
        debugPrint('Error updating field: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Map<String, dynamic> updatedData = {
          'industry': _industryController.text,
          'companyAddress': _companyAddressController.text,
          'companyDescription': _companyDescriptionController.text,
          'companyWebsite': _companyWebsiteController.text,
          'companyEmail': _companyEmailController.text,
          'companyPhone': _companyPhoneController.text,
          'companySize': _selectedCompanySize,
          'EMPLOYERCount': _EMPLOYERCountController.text,
          'establishedYear': _establishedYearController.text,
          'companyLogo': logoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update in the companyInfo subcollection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('companyInfo')
            .doc('details')
            .set(updatedData, SetOptions(merge: true));

        setState(() {
          companyInfo = {...companyInfo ?? {}, ...updatedData};
          isEditing = false;
        });

        _showSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }



  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  // Profile completion banner widget
  Widget _buildProfileCompletionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF130160), Color(0xFF6C5CE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF130160).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Your Company Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_profileCompletionPercentage% complete',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _profileCompletionPercentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Complete Now button
          ElevatedButton(
            onPressed: _navigateToCompleteProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF130160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Complete',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'DM Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to onboarding to complete profile
  Future<void> _navigateToCompleteProfile() async {
    try {
      if (mounted) {
        await Navigator.pushNamed(context, AppRoutes.employerOnboarding);
        // Reload profile data after returning from onboarding
        _fetchEmployerData();
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lookGigProfileText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.lookGigDescriptionText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
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
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            enabled: isEditing,
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  isEditing ? AppColors.white : AppColors.lookGigLightGray,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.lookGigPurple,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonEditableField({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lookGigLightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                fontSize: 16,
                color:
                    value.isEmpty
                        ? AppColors.hintText
                        : AppColors.lookGigDescriptionText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9228).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFF9228), size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.lookGigProfileText,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.lookGigDescriptionText,
          ),
        ),
      ),
    );
  }



  Widget _buildSectionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9228).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF9228), size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.lookGigProfileText,
            ),
          ),
          iconColor: AppColors.lookGigPurple,
          collapsedIconColor: AppColors.lookGigDescriptionText,
          children: children,
        ),
      ),
    );
  }

  Widget _buildCompanySizeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Size',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (isEditing)
            DropdownButtonFormField<String>(
              initialValue: _selectedCompanySize,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.lookGigPurple,
                    width: 2,
                  ),
                ),
              ),
              items:
                  _companySizes.map((size) {
                    return DropdownMenuItem(value: size, child: Text(size));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCompanySize = value;
                });
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lookGigLightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Text(
                _selectedCompanySize ?? 'Not provided',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _selectedCompanySize == null
                          ? AppColors.hintText
                          : AppColors.lookGigDescriptionText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lookGigLightGray,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.lookGigPurple),
        ),
      );
    }

    final fullName = employerData?['fullName'] ?? 'Full Name';
    final companyName = companyInfo?['companyName'] ?? 'Company Name';
    final industry = companyInfo?['industry'] ?? 'Industry';
    final EMPLOYERCount = companyInfo?['EMPLOYERCount'] ?? '0';
    final establishedYear = companyInfo?['establishedYear'] ?? 'N/A';
    final companySize = companyInfo?['companySize'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: Column(
        children: [
          _buildEMPLOYERProfileHeader(fullName, companyName, industry),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile completion card
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ProfileCompletionWidget(),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          title: 'Jobs',
                          value: _jobCount.toString(),
                          icon: Icons.work_outline,
                          color: const Color(0xFFFF9228),
                        ),
                        _buildStatCard(
                          title: 'Since',
                          value: establishedYear,
                          icon: Icons.access_time,
                          color: const Color(0xFFFF9228),
                        ),
                        _buildStatCard(
                          title: 'Size',
                          value: companySize.split(' ')[0],
                          icon: Icons.business,
                          color: const Color(0xFFFF9228),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildNavigationCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployerPersonalInfoEditScreen(
                            employerData: employerData ?? {},
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _fetchEmployerData();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    title: 'Company Information',
                    icon: Icons.business,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyInfoEditScreen(
                            companyInfo: companyInfo ?? {},
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _fetchEmployerData();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    title: 'Company Details',
                    icon: Icons.info_outline,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyDetailsEditScreen(
                            companyInfo: companyInfo ?? {},
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _fetchEmployerData();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactInfoEditScreen(
                            companyInfo: companyInfo ?? {},
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _fetchEmployerData();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    title: 'Company Logo',
                    icon: Icons.image,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyLogoEditScreen(
                            companyInfo: companyInfo ?? {},
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _fetchEmployerData();
                      }
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEMPLOYERProfileHeader(
    String fullName,
    String companyName,
    String industry,
  ) {
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
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(27, 8, 27, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row with settings icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EMPLOYERSettingsScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _fetchEmployerData(); // Reload data if changes were made
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Profile content - centered with proper spacing
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                          // Company logo
                          Stack(
                            alignment: Alignment.center,
                            children: [
                            Container(
                              width: 90,
                              height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(45),
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child:
                                    logoUrl != null && logoUrl!.isNotEmpty
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            45,
                                          ),
                                          child: Image.network(
                                            logoUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                  color:
                                                      AppColors.lookGigPurple,
                                                ),
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Center(
                                                child: Text(
                                                  companyName.isNotEmpty
                                                      ? companyName[0]
                                                          .toUpperCase()
                                                      : 'C',
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.lookGigPurple,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : Center(
                                          child: Text(
                                            companyName.isNotEmpty
                                                ? companyName[0].toUpperCase()
                                                : 'C',
                                            style: const TextStyle(
                                              color: AppColors.lookGigPurple,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                              ),
                              if (isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _uploadLogo,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child:
                                          isUploadingLogo
                                              ? const Padding(
                                                padding: EdgeInsets.all(6),
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          AppColors
                                                              .lookGigPurple,
                                                    ),
                                              )
                                              : const Icon(
                                                Icons.camera_alt,
                                                size: 16,
                                                color: AppColors.lookGigPurple,
                                              ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name and company info
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  companyName,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                if (industry.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      industry,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _industryController.dispose();
    _companyAddressController.dispose();
    _companyDescriptionController.dispose();
    _companyWebsiteController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _EMPLOYERCountController.dispose();
    _establishedYearController.dispose();
    super.dispose();
  }
}

//test
