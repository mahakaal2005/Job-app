import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isUploadingResume = false;
  Map<String, dynamic> _userData = {};

  // Track expanded sections
  final Map<String, bool> _expandedSections = {
    'basic': true,
    'skills': false,
    'social': false,
    'availability': false,
    'address': false,
  };

  // Text controllers
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _collegeController = TextEditingController();
  final _weeklyHoursController = TextEditingController();
  final _ageController = TextEditingController();

  // Social media controllers
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _twitterController = TextEditingController();

  // Dropdown options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _educationOptions = [
    'High School',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Other',
  ];
  final List<String> _availabilityOptions = [
    'Full-time',
    'Part-time',
    'Freelance',
    'Unavailable',
  ];
  final List<String> _timeSlots = [
    'Morning (9AM-12PM)',
    'Afternoon (12PM-5PM)',
    'Evening (5PM-9PM)',
    'Night (9PM-12AM)',
  ];

  List<String> _skills = [];
  List<String> _preferredSlots = [];
  String _selectedGender = 'Male';
  String _selectedEducation = 'Bachelor\'s Degree';
  String _selectedAvailability = 'Full-time';
  DateTime? _dateOfBirth;
  File? _selectedImage;
  File? _selectedResume;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _addressController.dispose();
    _collegeController.dispose();
    _weeklyHoursController.dispose();
    _ageController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employee' ? 'employees' : 'users_specific';

        final doc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .get();

        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data() ?? {};
            _populateControllers();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading profile: $e');
      }
    }
  }

  void _populateControllers() {
    _fullNameController.text = _userData['fullName'] ?? '';
    _bioController.text = _userData['bio'] ?? '';
    _phoneController.text = _userData['phone'] ?? '';
    _cityController.text = _userData['city'] ?? '';
    _stateController.text = _userData['state'] ?? '';
    _zipCodeController.text = _userData['zipCode'] ?? '';
    _addressController.text = _userData['address'] ?? '';
    _collegeController.text = _userData['college'] ?? '';
    _weeklyHoursController.text = (_userData['weeklyHours'] ?? 0).toString();
    _ageController.text = (_userData['age'] ?? 0).toString();

    final socialMedia = _userData['socialMedia'] as Map<String, dynamic>? ?? {};
    _instagramController.text = socialMedia['instagram'] ?? '';
    _linkedinController.text = socialMedia['linkedin'] ?? '';
    _githubController.text = socialMedia['github'] ?? '';
    _portfolioController.text = socialMedia['portfolio'] ?? '';
    _twitterController.text = socialMedia['twitter'] ?? '';

    _skills = List<String>.from(_userData['skills'] ?? []);
    _preferredSlots = List<String>.from(_userData['preferredSlots'] ?? []);
    _selectedGender = _userData['gender'] ?? 'Male';
    _selectedEducation = _userData['educationLevel'] ?? 'Bachelor\'s Degree';
    _selectedAvailability =
        _userData['availability'] is String
            ? _userData['availability']
            : _userData['availability']?['type'] ?? 'Full-time';

    if (_userData['dateOfBirth'] != null) {
      _dateOfBirth = (_userData['dateOfBirth'] as Timestamp).toDate();
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploadingImage = true;
      });

      try {
        final url = await _uploadToCloudinary(_selectedImage!);

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final role = await AuthService.getUserRole();
          final collectionName =
              role == 'employee' ? 'employees' : 'users_specific';

          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid)
              .update({
                'profileImageUrl': url,
                'updatedAt': FieldValue.serverTimestamp(),
              });

          setState(() {
            _userData['profileImageUrl'] = url;
            _isUploadingImage = false;
          });

          _showSuccessSnackBar('Profile picture updated successfully!');
        }
      } catch (e) {
        setState(() => _isUploadingImage = false);
        _showErrorSnackBar('Error uploading image: $e');
      }
    }
  }

  Future<void> _uploadResume() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedResume = File(pickedFile.path);
        _isUploadingResume = true;
      });

      try {
        final url = await _uploadToCloudinary(_selectedResume!);

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final role = await AuthService.getUserRole();
          final collectionName =
              role == 'employee' ? 'employees' : 'users_specific';

          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid)
              .update({
                'resumeUrl': url,
                'updatedAt': FieldValue.serverTimestamp(),
              });

          setState(() {
            _userData['resumeUrl'] = url;
            _isUploadingResume = false;
          });

          _showSuccessSnackBar('Resume updated successfully!');
        }
      } catch (e) {
        setState(() => _isUploadingResume = false);
        _showErrorSnackBar('Error uploading resume: $e');
      }
    }
  }

  Future<String> _uploadToCloudinary(File file) async {
    const cloudName = 'dteigt5oc';
    const uploadPreset = 'get_work';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload?upload_preset=$uploadPreset',
    );

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: path.basename(file.path),
        ),
      );

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final result = String.fromCharCodes(responseData);
    final jsonResponse = json.decode(result);

    if (response.statusCode == 200) {
      return jsonResponse['secure_url'];
    } else {
      throw Exception('Failed to upload file to Cloudinary');
    }
  }

  Future<void> _saveProfile() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employee' ? 'employees' : 'users_specific';

        final updatedData = {
          'fullName': _fullNameController.text.trim(),
          'bio': _bioController.text.trim(),
          'phone': _phoneController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zipCode': _zipCodeController.text.trim(),
          'address': _addressController.text.trim(),
          'college': _collegeController.text.trim(),
          'weeklyHours': int.tryParse(_weeklyHoursController.text) ?? 0,
          'age': int.tryParse(_ageController.text) ?? 0,
          'skills': _skills,
          'preferredSlots': _preferredSlots,
          'gender': _selectedGender,
          'educationLevel': _selectedEducation,
          'availability': _selectedAvailability,
          'socialMedia': {
            'instagram': _instagramController.text.trim(),
            'linkedin': _linkedinController.text.trim(),
            'github': _githubController.text.trim(),
            'portfolio': _portfolioController.text.trim(),
            'twitter': _twitterController.text.trim(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_dateOfBirth != null) {
          updatedData['dateOfBirth'] = Timestamp.fromDate(_dateOfBirth!);
        }

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update(updatedData);

        // Upload image if selected
        if (_selectedImage != null) {
          await _uploadImage();
        }

        // Upload resume if selected
        if (_selectedResume != null) {
          await _uploadResume();
        }

        if (mounted) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
            _userData.addAll(updatedData);
          });
          _showSuccessSnackBar('Profile updated successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving profile: $e');
      }
    }
  }

  bool _validateInputs() {
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Full name is required');
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      _showErrorSnackBar('Please enter a valid phone number');
      return false;
    }
    return true;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.white, size: 20),
            SizedBox(width: 12),
            Text(message, style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: AppColors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildResumeField() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.hintText,
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: _isEditing ? _uploadResume : null,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEditing ? AppColors.lightBlue : AppColors.softGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _isEditing
                          ? AppColors.primaryBlue
                          : AppColors.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_rounded,
                    color:
                        _isEditing ? AppColors.primaryBlue : AppColors.hintText,
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData['resumeUrl'] != null
                              ? 'Resume uploaded'
                              : 'No resume uploaded',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        if (_userData['resumeUrl'] != null)
                          Text(
                            'Tap to change',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.hintText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isUploadingResume)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  else if (_userData['resumeUrl'] != null)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          if (_userData['resumeUrl'] != null && !_isEditing)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () async {
                  // Open resume URL in browser
                  final Uri resumeUri = Uri.parse(_userData['resumeUrl']);
if (await canLaunchUrl(resumeUri)) {
  await launchUrl(resumeUri, mode: LaunchMode.externalApplication);
} else {
  // Handle the error
  print('Could not launch resume URL');
}

                  
                },
                child: Text(
                  'View Resume',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    String availabilityText = 'Available';
    if (_userData['availability'] is String) {
      availabilityText = _userData['availability'];
    } else if (_userData['availability'] is Map) {
      availabilityText = _userData['availability']['type'] ?? 'Available';
    }

    return Container(
      decoration: BoxDecoration(
        gradient:
            _isEditing
                ? LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.9),
                    AppColors.neonBlue.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (_isEditing) {
                          _saveProfile();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                      icon:
                          _isSaving
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                _isEditing
                                    ? Icons.save_rounded
                                    : Icons.edit_rounded,
                                color: AppColors.white,
                              ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Stack(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _uploadImage : null,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.neonBlue,
                        backgroundImage:
                            _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : _userData['profileImageUrl'] != null
                                ? NetworkImage(_userData['profileImageUrl'])
                                : null,
                        child:
                            _isUploadingImage
                                ? CircularProgressIndicator(
                                  color: AppColors.white,
                                )
                                : _selectedImage == null &&
                                    _userData['profileImageUrl'] == null
                                ? Text(
                                  (_userData['fullName'] ?? 'U')[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                _userData['fullName'] ?? 'User Name',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  availabilityText,
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.work_outline_rounded,
            value: '${_userData['totalEarned'] ?? 0}',
            label: 'Total Earned',
            color: AppColors.success,
          ),
          Container(width: 1, height: 40, color: AppColors.dividerColor),
          _buildStatItem(
            icon: Icons.schedule_rounded,
            value: '${_userData['weeklyHours'] ?? 0}h',
            label: 'Weekly Hours',
            color: AppColors.primaryBlue,
          ),
          Container(width: 1, height: 40, color: AppColors.dividerColor),
          _buildStatItem(
            icon: Icons.star_rounded,
            value: '4.8',
            label: 'Rating',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.hintText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required String sectionKey,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                _isEditing
                    ? AppColors.blueShadow.withOpacity(0.2)
                    : AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        key: Key(sectionKey),
        initiallyExpanded: _expandedSections[sectionKey] ?? false,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections[sectionKey] = expanded;
          });
        },
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    _isEditing
                        ? AppColors.primaryBlue.withOpacity(0.2)
                        : AppColors.softGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: _isEditing ? AppColors.primaryBlue : AppColors.hintText,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isEditing ? AppColors.primaryBlue : AppColors.black,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _isEditing
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : AppColors.softGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: _isEditing ? AppColors.primaryBlue : AppColors.hintText,
              size: 20,
            ),
          ),
          labelStyle: TextStyle(
            color: _isEditing ? AppColors.primaryBlue : AppColors.hintText,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: _isEditing ? AppColors.lightBlue : AppColors.softGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
  required String value,
  required List<String> options,
  required String label,
  required IconData icon,
  required Function(String?) onChanged,
}) {
  // Ensure the current value exists in options, if not use the first option
  final String dropdownValue = options.contains(value) ? value : options.first;

  return Container(
    margin: EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      value: dropdownValue,
      onChanged: _isEditing ? onChanged : null,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: EdgeInsets.all(12),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isEditing
                ? AppColors.primaryBlue.withOpacity(0.1)
                : AppColors.softGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _isEditing ? AppColors.primaryBlue : AppColors.hintText,
            size: 20,
          ),
        ),
        labelStyle: TextStyle(
          color: _isEditing ? AppColors.primaryBlue : AppColors.hintText,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: _isEditing ? AppColors.lightBlue : AppColors.softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
    ),
  );
}

  Widget _buildSkillsSection() {
    return _buildSectionCard(
      title: 'Skills',
      icon: Icons.stars_rounded,
      sectionKey: 'skills',
      children: [
        if (_isEditing)
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a skill',
                      filled: true,
                      fillColor: AppColors.lightBlue,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty &&
                          !_skills.contains(value.trim())) {
                        setState(() => _skills.add(value.trim()));
                      }
                    },
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Show skill adding dialog
                    },
                    icon: Icon(Icons.add_rounded, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _skills.map((skill) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient:
                        _isEditing
                            ? AppColors.blueGradient
                            : LinearGradient(
                              colors: [AppColors.softGrey, AppColors.softGrey],
                            ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _isEditing
                                ? AppColors.blueShadow.withOpacity(0.3)
                                : Colors.transparent,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        skill,
                        style: TextStyle(
                          color: _isEditing ? AppColors.white : AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isEditing) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _skills.remove(skill)),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return _buildSectionCard(
      title: 'Social Media',
      icon: Icons.link_rounded,
      sectionKey: 'social',
      children: [
        _buildSocialMediaField(
          controller: _instagramController,
          label: 'Instagram',
          icon: Icons.camera_alt_rounded,
          color: Color(0xFFE4405F),
        ),
        _buildSocialMediaField(
          controller: _linkedinController,
          label: 'LinkedIn',
          icon: Icons.business_center_rounded,
          color: Color(0xFF0077B5),
        ),
        _buildSocialMediaField(
          controller: _githubController,
          label: 'GitHub',
          icon: Icons.code_rounded,
          color: Color(0xFF333333),
        ),
        _buildSocialMediaField(
          controller: _portfolioController,
          label: 'Portfolio',
          icon: Icons.web_rounded,
          color: AppColors.primaryBlue,
        ),
        _buildSocialMediaField(
          controller: _twitterController,
          label: 'Twitter',
          icon: Icons.alternate_email_rounded,
          color: Color(0xFF1DA1F2),
        ),
      ],
    );
  }

  Widget _buildSocialMediaField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          labelStyle: TextStyle(
            color: _isEditing ? color : AppColors.hintText,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: _isEditing ? AppColors.lightBlue : AppColors.softGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return _buildSectionCard(
      title: 'Availability',
      icon: Icons.access_time_rounded,
      sectionKey: 'availability',
      children: [
        _buildDropdown(
          value: _selectedAvailability,
          options: _availabilityOptions,
          label: 'Availability Type',
          icon: Icons.work_outline_rounded,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedAvailability = value);
            }
          },
        ),
        _buildTextField(
          controller: _weeklyHoursController,
          label: 'Weekly Hours Available',
          icon: Icons.timer_rounded,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 12),
        Text(
          'Preferred Time Slots',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _timeSlots.map((slot) {
                final isSelected = _preferredSlots.contains(slot);
                return FilterChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected:
                      _isEditing
                          ? (selected) {
                            setState(() {
                              if (selected) {
                                _preferredSlots.add(slot);
                              } else {
                                _preferredSlots.remove(slot);
                              }
                            });
                          }
                          : null,
                  selectedColor: AppColors.primaryBlue,
                  checkmarkColor: AppColors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _buildSectionCard(
      title: 'Address',
      icon: Icons.location_on_outlined,
      sectionKey: 'address',
      children: [
        _buildTextField(
          controller: _addressController,
          label: 'Street Address',
          icon: Icons.home_rounded,
        ),
        _buildTextField(
          controller: _cityController,
          label: 'City',
          icon: Icons.location_city_rounded,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _stateController,
                label: 'State',
                icon: Icons.map_rounded,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _zipCodeController,
                label: 'Zip Code',
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor:
          _isEditing
              ? AppColors.lightBlue.withOpacity(0.1)
              : AppColors.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsRow(),

            // Basic Information
            _buildSectionCard(
              title: 'Basic Information',
              icon: Icons.person_outline_rounded,
              sectionKey: 'basic',
              children: [
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_rounded,
                ),
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  icon: Icons.info_rounded,
                  maxLines: 3,
                ),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                ),
                _buildDropdown(
                  value: _selectedGender,
                  options: _genderOptions,
                  label: 'Gender',
                  icon: Icons.transgender_rounded,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGender = value);
                    }
                  },
                ),
                _buildDropdown(
                  value: _selectedEducation,
                  options: _educationOptions,
                  label: 'Education Level',
                  icon: Icons.school_rounded,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedEducation = value);
                    }
                  },
                ),
                _buildTextField(
                  controller: _collegeController,
                  label: 'College/University',
                  icon: Icons.account_balance_rounded,
                ),
                _buildResumeField(), // Added resume field here
              ], // This is the correct closing bracket for the children of _buildSectionCard
            ),

            // Skills Section
            _buildSkillsSection(),

            // Social Media Section
            _buildSocialMediaSection(),

            // Availability Section
            _buildAvailabilitySection(),

            // Address Section
            _buildAddressSection(),
            if (_isEditing)
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _selectedImage = null;
                            _populateControllers(); // Reset changes
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSaving
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
          ], // This is the correct closing bracket for the Column children
        ),
      ),
    );
  }
}
