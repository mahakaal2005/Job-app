import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_work_app/screens/main/user/profile/about_me_screen.dart';
import 'package:get_work_app/screens/main/user/profile/address_edit_screen.dart';
import 'package:get_work_app/screens/main/user/profile/appreciation_screen.dart';
import 'package:get_work_app/screens/main/user/profile/education_screen.dart';
import 'package:get_work_app/screens/main/user/profile/language_screen.dart';
import 'package:get_work_app/screens/main/user/profile/resume_screen.dart';
import 'package:get_work_app/screens/main/user/profile/settings_screen.dart';
import 'package:get_work_app/screens/main/user/profile/skills_screen.dart';
import 'package:get_work_app/screens/main/user/profile/work_experience_screen.dart';
import 'package:get_work_app/screens/main/user/applications/my_applications_screen.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/services/pdf_service.dart';
import 'package:get_work_app/widgets/profile_completion_widget.dart';

import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/image_utils.dart';
import 'package:get_work_app/widgets/phone_input_field.dart';
import 'package:get_work_app/widgets/custom_dropdown_field.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
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
  bool _isSavingFromSettingsIcon = false; // Track if save was triggered from settings icon
  bool _isUploadingImage = false;
  bool _isUploadingResume = false;
  bool _isPickingImage = false; // Prevent multiple simultaneous picker calls

  // Helper method to check if any uploads are in progress
  bool get _isAnyUploadInProgress => _isUploadingImage || _isUploadingResume;
  Map<String, dynamic> _userData = {};
  final _skillSearchController = TextEditingController();
  // Removed unused fields to fix analyzer warnings
  
  // Profile completion tracking
  bool _profileCompleted = true;
  int _profileCompletionPercentage = 100;
  bool _skippedOnboarding = false;

  // Text controllers
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
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

  // Dropdown options (moved to local variables where used)

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
    // Profile completion refresh temporarily disabled
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
    _skillSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employer' ? 'employers' : 'users_specific';

        final doc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .get();

        if (doc.exists && mounted) {
          // Profile completion status removed
          
          setState(() {
            _userData = doc.data() ?? {};
            // Log user data for debugging (only essential info)
            debugPrint('=== User Data Loaded ===');
            debugPrint('User Name: ${_userData['fullName'] ?? 'N/A'}');
            final profileImg = _userData['profileImageUrl']?.toString() ?? '';
            debugPrint('Profile Image URL: ${profileImg.isNotEmpty ? profileImg : '(empty)'}');
            debugPrint('=======================');
            
            // Set profile completion data - simplified
            _skippedOnboarding = false;
            _profileCompletionPercentage = 100; // Always complete
            _profileCompleted = true; // Always complete
            
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

    // Load resume data from onboarding
    if (_userData['resumeUrl'] != null) {
      setState(() {
        _userData['resumeFileName'] =
            _userData['resumeFileName'] ?? 'Resume.pdf';
        _userData['resumePreviewUrl'] = _userData['resumePreviewUrl'];
      });
    }

    if (_userData['dateOfBirth'] != null) {
      final dob = _userData['dateOfBirth'];
      if (dob is Timestamp) {
        _dateOfBirth = dob.toDate();
      } else if (dob is DateTime) {
        _dateOfBirth = dob;
      } else if (dob is String) {
        _dateOfBirth = DateTime.tryParse(dob);
      } else {
        _dateOfBirth = null;
      }
    }
  }

  Future<void> _uploadImage() async {
    print('🎯 [UPLOAD_IMAGE] Called');
    
    // Prevent multiple simultaneous picker calls
    if (_isPickingImage) {
      print('⚠️ [UPLOAD_IMAGE] Already picking, ignoring request');
      return;
    }

    try {
      print('📱 [UPLOAD_IMAGE] Setting picking flag to true');
      setState(() {
        _isPickingImage = true;
      });

      print('📸 [UPLOAD_IMAGE] Opening image picker...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      print('📊 [UPLOAD_IMAGE] Picker returned: ${pickedFile != null ? pickedFile.path : 'null (cancelled)'}');

      if (pickedFile != null) {
        print('✅ Image selected: ${pickedFile.path}');
        
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
                role == 'employer' ? 'employers' : 'users_specific';

            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .update({
                  'profileImageUrl': url,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

            if (mounted) {
              setState(() {
                _userData['profileImageUrl'] = url;
                _isUploadingImage = false;
                _selectedImage = null; // Clear selected image after successful upload
              });

              _showSuccessSnackBar('Profile picture updated successfully!');
            }
          }
        } catch (e) {
          print('❌ [UPLOAD_IMAGE] Error uploading: $e');
          if (mounted) {
            setState(() => _isUploadingImage = false);
            _showErrorSnackBar('Error uploading image: $e');
          }
        }
      } else {
        print('ℹ️ [UPLOAD_IMAGE] User cancelled selection');
      }
    } on PlatformException catch (e) {
      print('❌ [UPLOAD_IMAGE] Platform exception: ${e.code} - ${e.message}');
      
      if (e.code == 'already_active') {
        // Silently ignore - picker was already open
        return;
      } else if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        if (mounted) {
          _showErrorSnackBar('Please grant photo access in settings');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Failed to select image');
        }
      }
    } catch (e) {
      print('❌ [UPLOAD_IMAGE] Error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to select image');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _uploadResume() async {
    try {
      // Use file_picker for mobile compatibility
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        setState(() {
          _selectedResume = File(filePath);
          _isUploadingResume = true;
        });

        // Verify file exists
        if (!await _selectedResume!.exists()) {
          throw Exception('Selected file not found');
        }

        // Use PDFService to handle the upload and preview generation
        final uploadResult = await PDFService.uploadResumePDF(_selectedResume!);
        if (uploadResult['pdfUrl'] == null) {
          throw Exception('Failed to upload resume to server');
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted) {
          print('🔍 [PROFILE] Getting user role...');
          final role = await AuthService.getUserRole();
          print('✅ [PROFILE] User role obtained: $role');
          
          if (!mounted) {
            print('⚠️ [PROFILE] Widget unmounted after getUserRole, aborting');
            return;
          }
          
          final collectionName =
              role == 'employer' ? 'employers' : 'users_specific';
          print('📁 [PROFILE] Using collection: $collectionName');

          // Update Firestore with available data
          final updateData = {
            'resumeUrl': uploadResult['pdfUrl'],
            'resumeFileName': fileName,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Only add preview URL if it was successfully generated
          if (uploadResult['previewUrl'] != null) {
            updateData['resumePreviewUrl'] = uploadResult['previewUrl'];
          }

          print('💾 [PROFILE] Updating Firestore...');
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid)
              .update(updateData);
          print('✅ [PROFILE] Firestore updated successfully');

          if (!mounted) {
            print('⚠️ [PROFILE] Widget unmounted after Firestore update, aborting');
            return;
          }

          print('🔄 [PROFILE] Updating UI state...');
          setState(() {
            _userData['resumeUrl'] = uploadResult['pdfUrl'];
            _userData['resumeFileName'] = fileName;
            if (uploadResult['previewUrl'] != null) {
              _userData['resumePreviewUrl'] = uploadResult['previewUrl'];
            }
            _selectedResume = null; // Clear selected resume after successful upload
          });
          print('✅ [PROFILE] UI state updated successfully');

          _showSuccessSnackBar(
            uploadResult['previewUrl'] != null
                ? 'Resume updated successfully!'
                : 'Resume uploaded successfully (preview generation failed)',
          );
          print('✅ [PROFILE] Success message shown');
        } else if (!mounted) {
          print('⚠️ [PROFILE] Widget not mounted at start, aborting upload process');
        }
      } else {
        // User cancelled the picker
        debugPrint('Resume selection cancelled by user');
      }
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      _showErrorSnackBar('Error uploading resume: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingResume = false;
          _selectedResume = null;
        });
      }
    }
  }

  Future<String> _uploadToCloudinary(File file) async {
    // Use environment variables instead of hardcoded values
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
    
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Cloudinary configuration missing in .env file');
    }

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

    // Prevent saving if uploads are in progress
    if (_isAnyUploadInProgress) {
      _showErrorSnackBar('Please wait for file uploads to complete before saving your profile');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employer' ? 'employers' : 'users_specific';

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

        // Note: Image and resume uploads are handled immediately when selected
        // No need to upload again here to avoid duplicates

        if (mounted) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
            _isSavingFromSettingsIcon = false;
            _userData.addAll(updatedData);
          });
          _showSuccessSnackBar('Profile updated successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSavingFromSettingsIcon = false;
        });
        _showErrorSnackBar('Error saving profile: $e');
      }
    }
  }

  bool _validateInputs() {
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Full name is required');
      return false;
    }
    // Phone validation is handled by PhoneInputField widget
    if (_phoneController.text.trim().isEmpty) {
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

  Future<void> _shareProfile() async {
    debugPrint('=== SHARE PROFILE STARTED ===');
    try {
      // Log user data availability
      debugPrint('User data isEmpty: ${_userData.isEmpty}');
      debugPrint('User data keys: ${_userData.keys.toList()}');
      
      // Build profile summary text
      final name = _userData['fullName'] ?? 'Job Seeker';
      debugPrint('Extracted name: $name');
      
      final availability = _userData['availability'] is String
          ? _userData['availability']
          : _userData['availability']?['type'] ?? 'Full-time';
      debugPrint('Extracted availability: $availability');
      
      // Get skills
      final skills = _userData['skills'] as List<dynamic>?;
      debugPrint('Skills data: $skills');
      final skillsText = skills != null && skills.isNotEmpty
          ? skills.take(5).join(', ')
          : 'Not specified';
      debugPrint('Skills text: $skillsText');
      
      // Get work experience
      String workExpText = 'Not specified';
      try {
        final workExpData = _userData['workExperience'];
        debugPrint('Work experience data type: ${workExpData.runtimeType}');
        debugPrint('Work experience data: $workExpData');
        
        if (workExpData != null) {
          if (workExpData is List && workExpData.isNotEmpty) {
            final latest = workExpData.first as Map<String, dynamic>;
            final position = latest['position'] ?? latest['jobTitle'] ?? '';
            final company = latest['company'] ?? '';
            if (position.isNotEmpty || company.isNotEmpty) {
              workExpText = '$position at $company';
            }
          } else if (workExpData is Map<String, dynamic>) {
            final position = workExpData['position'] ?? workExpData['jobTitle'] ?? '';
            final company = workExpData['company'] ?? '';
            if (position.isNotEmpty || company.isNotEmpty) {
              workExpText = '$position at $company';
            }
          }
        }
        debugPrint('Work experience text: $workExpText');
      } catch (e, stackTrace) {
        debugPrint('Error getting work experience for share: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      // Get bio
      final bio = _userData['bio'] ?? '';
      debugPrint('Bio length: ${bio.length}');
      
      // Build share text
      String shareText = '''
🌟 Professional Profile

👤 Name: $name
💼 Availability: $availability
🎯 Skills: $skillsText
💡 Experience: $workExpText''';

      if (bio.isNotEmpty) {
        shareText += '\n\n📝 About:\n$bio';
      }

      // Add resume link - PDF URL now works correctly with proper file extension
      final resumePreviewUrl = _userData['resumePreviewUrl'];
      final resumeUrl = _userData['resumeUrl'];
      
      debugPrint('Resume Preview URL: $resumePreviewUrl');
      debugPrint('Resume PDF URL: $resumeUrl');
      
      // Share the PDF URL (now has proper .pdf extension and opens correctly)
      if (resumeUrl != null && resumeUrl.toString().isNotEmpty) {
        shareText += '\n\n📄 Resume: $resumeUrl';
      } else if (resumePreviewUrl != null && resumePreviewUrl.toString().isNotEmpty) {
        // Fallback to preview image if PDF URL not available
        shareText += '\n\n📄 Resume Preview: $resumePreviewUrl';
      }

      shareText += '\n\n✨ Shared from Gig Work App';

      debugPrint('=== FINAL SHARE TEXT ===');
      debugPrint(shareText);
      debugPrint('=== CALLING Share.share() ===');
      
      // Share using share_plus
      final result = await Share.share(
        shareText,
        subject: '$name - Professional Profile',
      );
      
      debugPrint('Share result: ${result.status}');
      debugPrint('Share result raw: $result');
      debugPrint('=== SHARE COMPLETED SUCCESSFULLY ===');
      
    } catch (e, stackTrace) {
      debugPrint('=== SHARE PROFILE ERROR ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=========================');
      _showErrorSnackBar('Failed to share profile: $e');
    }
  }

  String _getContentForSection(String title) {
    switch (title.toLowerCase()) {
      case 'about me':
        return _userData['bio'] ?? '';
      case 'work experience':
        try {
          final workExpData = _userData['workExperience'];
          if (workExpData == null) return '';

          // Handle both single Map and List of Maps
          if (workExpData is List) {
            if (workExpData.isNotEmpty) {
              final latest = workExpData.first as Map<String, dynamic>;
              return '${latest['position'] ?? latest['jobTitle'] ?? ''} at ${latest['company'] ?? ''}';
            }
          } else if (workExpData is Map<String, dynamic>) {
            return '${workExpData['position'] ?? workExpData['jobTitle'] ?? ''} at ${workExpData['company'] ?? ''}';
          }
        } catch (e) {
          debugPrint('Error getting work experience content: $e');
        }
        return '';
      case 'education':
        try {
          final educationData = _userData['education'];
          if (educationData is List && educationData.isNotEmpty) {
            // Handle list of educations - show the first one
            final firstEducation = educationData.first as Map<String, dynamic>;
            final field = firstEducation['field'] ?? '';
            final institution = firstEducation['institution'] ?? '';
            if (field.isNotEmpty || institution.isNotEmpty) {
              return field.isNotEmpty ? field : institution;
            }
          } else if (educationData is Map<String, dynamic>) {
            final field = educationData['field'] ?? '';
            final institution = educationData['institution'] ?? '';
            if (field.isNotEmpty || institution.isNotEmpty) {
              return field.isNotEmpty ? field : institution;
            }
          }
          // Only use old college field if there's no new education data structure
          if (educationData == null) {
            return _userData['college'] ?? '';
          }
          return '';
        } catch (e) {
          debugPrint('Error getting education content: $e');
          // Only use old college field if there's an error and no education data
          if (_userData['education'] == null) {
            return _userData['college'] ?? '';
          }
          return '';
        }
      case 'skill':
        try {
          final skills = _userData['skills'];
          if (skills is List && skills.isNotEmpty) {
            return skills.take(3).join(', ') + (skills.length > 3 ? '...' : '');
          }
        } catch (e) {
          debugPrint('Error getting skills content: $e');
        }
        return '';
      case 'language':
        try {
          final languages = _userData['languages'];
          if (languages is List && languages.isNotEmpty) {
            final languageNames =
                languages
                    .map((lang) {
                      if (lang is Map<String, dynamic>) {
                        return lang['name'] ?? '';
                      } else if (lang is String) {
                        return lang;
                      }
                      return '';
                    })
                    .where((name) => name.isNotEmpty)
                    .toList();

            if (languageNames.isNotEmpty) {
              return languageNames.take(3).join(', ') +
                  (languageNames.length > 3 ? '...' : '');
            }
          }
        } catch (e) {
          debugPrint('Error getting languages content: $e');
        }
        return '';
      case 'appreciation':
        try {
          final appreciations = _userData['appreciations'];
          if (appreciations is List && appreciations.isNotEmpty) {
            final latest = appreciations.first as Map<String, dynamic>;
            return '${latest['title'] ?? ''} - ${latest['organization'] ?? ''}';
          }
        } catch (e) {
          debugPrint('Error getting appreciation content: $e');
        }
        return '';
      case 'address':
        final address = _userData['address'] ?? '';
        final city = _userData['city'] ?? '';
        final state = _userData['state'] ?? '';
        final zipCode = _userData['zipCode'] ?? '';
        
        List<String> addressParts = [];
        
        if (address.isNotEmpty) {
          addressParts.add(address);
        }
        
        if (city.isNotEmpty && state.isNotEmpty) {
          addressParts.add('$city, $state');
        } else if (city.isNotEmpty) {
          addressParts.add(city);
        } else if (state.isNotEmpty) {
          addressParts.add(state);
        }
        
        if (zipCode.isNotEmpty) {
          addressParts.add(zipCode);
        }
        
        return addressParts.join('\n');
      
      case 'resume':
        return _userData['resumeFileName'] ?? '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lookGigLightGray,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.lookGigPurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: Column(
        children: [_buildNewProfileHeader(), Expanded(child: _buildBody())],
      ),
    );
  }

  Widget _buildBody() {
    print('_buildBody called with _isEditing: $_isEditing');
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: _isEditing ? _buildEditForm() : _buildProfileSections(),
    );
  }

  Widget _buildProfileSections() {
    return Column(
      children: [
        // Profile completion card
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ProfileCompletionWidget(),
        ),
        
        _buildProfileSection(
          title: 'About me',
          iconPath: 'assets/images/basic_info_icon.png',
          onTap: () => _navigateToAboutMe(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'Work experience',
          iconPath: 'assets/images/work_experience_icon.png',
          onTap: () => _navigateToWorkExperience(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'Education',
          iconPath: 'assets/images/education_icon.png',
          onTap: () => _navigateToEducation(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'Skill',
          iconPath: 'assets/images/skill_icon.png',
          onTap: () => _navigateToSkills(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'Language',
          iconPath: 'assets/images/language_icon.png',
          onTap: () => _navigateToLanguage(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'Appreciation',
          iconPath: 'assets/images/appreciation_icon.png',
          onTap: () => _navigateToAppreciation(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'Address',
          iconPath: 'assets/images/address_icon.png',
          onTap: () => _navigateToAddress(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'Resume',
          iconPath: 'assets/images/resume_icon.png',
          onTap: () => _navigateToResume(),
        ),
        const SizedBox(height: 10),
        _buildProfileSection(
          title: 'My Applications',
          iconPath: 'assets/images/work_experience_icon.png',
          onTap: () => _navigateToMyApplications(),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  // Profile completion banner widget
  Widget _buildProfileCompletionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  'Complete Your Profile',
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
      String? role = await AuthService.getUserRole();
      String route = role == 'employer' 
        ? AppRoutes.employerOnboarding 
        : AppRoutes.studentOnboarding;
      
      if (mounted) {
        await Navigator.pushNamed(context, route);
        // Reload profile data after returning from onboarding
        _loadUserData();
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Widget _buildEditForm() {
    print('_buildEditForm called!');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Full name field
          _buildEditField(
            label: 'Fullname',
            controller: _fullNameController,
            value: _userData['fullName'] ?? '',
          ),
          const SizedBox(height: 15),

          // Date of birth field
          _buildDateField(
            label: 'Date of birth',
            value: _formatDateOfBirth(),
            onTap: _selectDateOfBirth,
          ),
          const SizedBox(height: 15),

          // Gender selection
          _buildGenderSelection(),
          const SizedBox(height: 15),

          // Email field
          _buildEditField(
            label: 'Email address',
            controller: _emailController,
            value: _userData['email'] ?? '',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),

          // Phone number field with country code
          _buildPhoneFieldWithCountryCode(),
          const SizedBox(height: 15),

          // Location field
          _buildEditField(
            label: 'Location',
            controller: _addressController,
            value: _userData['address'] ?? '',
          ),
          const SizedBox(height: 15),

          // Availability field
          _buildAvailabilityField(),
          const SizedBox(height: 40),

          // Save button
          _buildSaveButton(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // New UI Methods for Figma Design
  Widget _buildProfileSection({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    // Get content for each section
    String content = _getContentForSection(title);
    bool hasContent = content.isNotEmpty;

    // Special handling for education - only show content if there's actual education data
    if (title.toLowerCase() == 'education') {
      final educationData = _userData['education'];
      hasContent = false;

      if (educationData is List && educationData.isNotEmpty) {
        hasContent = true;
      } else if (educationData is Map<String, dynamic>) {
        final field = educationData['field'] ?? '';
        final institution = educationData['institution'] ?? '';
        hasContent = field.isNotEmpty || institution.isNotEmpty;
      }
    }

    // Work Experience, Education, Appreciation, and Resume always show plus icon for adding new entries
    bool showPlusIcon =
        title.toLowerCase() == 'work experience' ||
        title.toLowerCase() == 'education' ||
        title.toLowerCase() == 'appreciation' ||
        title.toLowerCase() == 'resume' ||
        !hasContent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 335,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header section with icon, title, and edit button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 23, 20, 0),
                child: Row(
                  children: [
                    // Icon (positioned at x: 20, y: 23 from Figma)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          title.toLowerCase() == 'language'
                              ? const Icon(
                                Icons.language,
                                size: 24,
                                color: Color(0xFF2F51A7),
                              )
                              : title.toLowerCase() == 'appreciation'
                              ? const Icon(
                                Icons.emoji_events,
                                size: 24,
                                color: Color(0xFF2F51A7),
                              )
                              : Image.asset(
                                iconPath,
                                width: 24,
                                height: 24,
                                color: const Color(0xFF2F51A7),
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.info,
                                    size: 24,
                                    color: Color(0xFF2F51A7),
                                  );
                                },
                              ),
                    ),
                    const SizedBox(width: 10), // Gap between icon and title
                    // Title (positioned at x: 54, y: 25 from Figma)
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.302,
                          color: Color(0xFF150B3D), // From Figma fill_EEL0Z0
                        ),
                      ),
                    ),
                    // Edit/Add button (positioned at x: 291, y: 23 from Figma)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          (title.toLowerCase() == 'work experience' ||
                                  title.toLowerCase() == 'education')
                              ? Image.asset(
                                title.toLowerCase() == 'education'
                                    ? 'assets/images/education_add_icon.png'
                                    : 'assets/images/add_icon.png',
                                width: 24,
                                height: 24,
                                color: const Color(0xFF2F51A7),
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.add,
                                    size: 24,
                                    color: Color(0xFF2F51A7),
                                  );
                                },
                              )
                              : showPlusIcon
                              ? Image.asset(
                                'assets/images/add_icon.png',
                                width: 24,
                                height: 24,
                                color: const Color(0xFF2F51A7),
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.add,
                                    size: 24,
                                    color: Color(0xFF2F51A7),
                                  );
                                },
                              )
                              : Image.asset(
                                'assets/images/edit_icon.png',
                                width: 24,
                                height: 24,
                                color: const Color(0xFF2F51A7),
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.edit,
                                    size: 24,
                                    color: Color(0xFF2F51A7),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),

              // Content section for Work Experience (special handling)
              if (title.toLowerCase() == 'work experience' && hasContent) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 0.5,
                  width: 295,
                  color: const Color(0xFFDEE1E7),
                ),
                _buildWorkExperienceList(),
              ] else if (title.toLowerCase() == 'education' && hasContent) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 0.5,
                  width: 295,
                  color: const Color(0xFFDEE1E7),
                ),
                _buildEducationContent(),
              ] else if (title.toLowerCase() == 'language' && hasContent) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 0.5,
                  width: 295,
                  color: const Color(0xFFDEE1E7),
                ),
                _buildLanguageChips(),
              ] else if (title.toLowerCase() == 'appreciation' &&
                  hasContent) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 0.5,
                  width: 295,
                  color: const Color(0xFFDEE1E7),
                ),
                _buildAppreciationContent(),
              ] else if (title.toLowerCase() == 'skill' && hasContent) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 0.5,
                  width: 295,
                  color: const Color(0xFFDEE1E7),
                ),
                _buildSkillChips(),
              ] else if (title.toLowerCase() == 'resume' && hasContent) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 0.5,
                  width: 295,
                  color: const Color(0xFFDEE1E7),
                ),
                _buildResumeContent(),
              ] else if (hasContent &&
                  title.toLowerCase() != 'work experience' &&
                  title.toLowerCase() != 'education' &&
                  title.toLowerCase() != 'language' &&
                  title.toLowerCase() != 'appreciation' &&
                  title.toLowerCase() != 'skill' &&
                  title.toLowerCase() != 'resume') ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 0.5,
                  width: 295,
                  color: const Color(0xFFDEE1E7),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 41, 23),
                  child: SizedBox(
                    width: 279,
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 1.302,
                        color: Color(0xFF524B6B),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkExperienceList() {
    try {
      final workExpData = _userData['workExperience'];
      debugPrint('Work experience raw data: $workExpData');
      List<Map<String, dynamic>> workExperiences = [];

      // Handle both single Map and List of Maps
      if (workExpData is List) {
        workExperiences = workExpData.cast<Map<String, dynamic>>();
        debugPrint('Processed as List: $workExperiences');
      } else if (workExpData is Map<String, dynamic>) {
        workExperiences = [workExpData];
        debugPrint('Processed as single Map: $workExperiences');
      }

      if (workExperiences.isEmpty) {
        return const SizedBox(height: 23);
      }

      return Column(
        children:
            workExperiences.map<Widget>((experience) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Position
                            Text(
                              experience['position'] ??
                                  experience['jobTitle'] ??
                                  'Position',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.302,
                                color: Color(0xFF150B3D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Company
                            Text(
                              experience['company'] ?? 'Company',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                height: 1.302,
                                color: Color(0xFF524B6B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Duration
                            Text(
                              _formatWorkExperienceDuration(experience),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.302,
                                color: Color(0xFF524B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit icon for individual experience
                      GestureDetector(
                        onTap: () => _editWorkExperience(experience),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/images/edit_icon.png',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF2F51A7),
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.edit,
                                size: 24,
                                color: Color(0xFF2F51A7),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()
              ..add(const SizedBox(height: 23)), // Bottom padding
      );
    } catch (e) {
      debugPrint('Error building work experience list: $e');
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 23),
        child: Text(
          'Error loading work experience',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF524B6B),
          ),
        ),
      );
    }
  }

  String _formatWorkExperienceDuration(Map<String, dynamic> experience) {
    try {
      final startDate = experience['startDate'] as String?;
      final endDate = experience['endDate'] as String?;
      final isCurrentJob = experience['isCurrentJob'] as bool? ?? false;

      if (startDate == null) return 'Duration not specified';

      final start = DateTime.tryParse(startDate);
      if (start == null) return 'Invalid start date';

      final startFormatted = '${_getMonthName(start.month)} ${start.year}';

      if (isCurrentJob) {
        final duration = _calculateDuration(start, DateTime.now());
        return '$startFormatted - Present • $duration';
      } else if (endDate != null) {
        final end = DateTime.tryParse(endDate);
        if (end != null) {
          final endFormatted = '${_getMonthName(end.month)} ${end.year}';
          final duration = _calculateDuration(start, end);
          return '$startFormatted - $endFormatted • $duration';
        }
      }

      return '$startFormatted - Present';
    } catch (e) {
      return 'Duration not available';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final difference = end.difference(start);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();

    if (years > 0 && months > 0) {
      return '$years Year${years > 1 ? 's' : ''} $months Month${months > 1 ? 's' : ''}';
    } else if (years > 0) {
      return '$years Year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months Month${months > 1 ? 's' : ''}';
    } else {
      return 'Less than a month';
    }
  }

  void _editWorkExperience(Map<String, dynamic> experience) {
    debugPrint('Editing work experience with data: $experience');
    // Navigate to work experience screen with specific experience to edit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorkExperienceScreen(experienceToEdit: experience),
      ),
    ).then((result) {
      if (result == true) {
        _loadUserData(); // Reload data if changes were made
      }
    });
  }

  Widget _buildEducationContent() {
    try {
      final educationData = _userData['education'];
      debugPrint('Education raw data: $educationData');
      List<Map<String, dynamic>> educationEntries = [];

      // Handle both single Map and List of Maps (like work experience)
      if (educationData is List) {
        educationEntries = educationData.cast<Map<String, dynamic>>();
        debugPrint('Processed as List: $educationEntries');
      } else if (educationData is Map<String, dynamic>) {
        educationEntries = [educationData];
        debugPrint('Processed as single Map: $educationEntries');
      }

      if (educationEntries.isEmpty) {
        return const SizedBox(height: 23);
      }

      return Column(
        children:
            educationEntries.map<Widget>((education) {
                final field = education['field'] ?? '';
                final institution = education['institution'] ?? '';
                final startDate = education['startDate'] as String?;
                final endDate = education['endDate'] as String?;
                final isCurrentEducation =
                    education['isCurrentEducation'] as bool? ?? false;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Field of study (Information Technology)
                            if (field.isNotEmpty)
                              Text(
                                field,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.302,
                                  color: Color(
                                    0xFF150B3D,
                                  ), // From Figma fill_00V3P7
                                ),
                              ),
                            if (field.isNotEmpty) const SizedBox(height: 4),
                            // Institution (University of Oxford)
                            if (institution.isNotEmpty)
                              Text(
                                institution,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: Color(
                                    0xFF524B6B,
                                  ), // From Figma fill_I529E0
                                ),
                              ),
                            if (institution.isNotEmpty)
                              const SizedBox(height: 4),
                            // Duration (Sep 2010 - Aug 2013 • 5 Years)
                            Text(
                              _formatEducationDuration(
                                startDate,
                                endDate,
                                isCurrentEducation,
                              ),
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.36,
                                color: Color(
                                  0xFF524B6B,
                                ), // From Figma fill_I529E0
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit icon for individual education
                      GestureDetector(
                        onTap: () => _editEducation(education),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/images/education_edit_icon.png',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF2F51A7),
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.edit,
                                size: 24,
                                color: Color(0xFF2F51A7),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()
              ..add(const SizedBox(height: 23)), // Bottom padding
      );
    } catch (e) {
      debugPrint('Error building education content: $e');
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 23),
        child: Text(
          'Error loading education',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF524B6B),
          ),
        ),
      );
    }
  }

  Widget _buildLanguageChips() {
    try {
      final languages = _userData['languages'];
      if (languages is List && languages.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 23),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                languages.map<Widget>((language) {
                  String languageName = '';
                  if (language is Map<String, dynamic>) {
                    languageName = language['name'] ?? '';
                  } else if (language is String) {
                    languageName = language;
                  }

                  if (languageName.isEmpty) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5), // Light gray background
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      languageName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: Color(0xFF524B6B),
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error building language chips: $e');
    }
    return const SizedBox(height: 23);
  }

  Widget _buildSkillChips() {
    try {
      final skills = _userData['skills'];
      if (skills is List && skills.isNotEmpty) {
        List<String> skillList = List<String>.from(skills);

        // Show maximum 5 skills as chips
        List<String> displaySkills = skillList.take(5).toList();
        int remainingSkills = skillList.length - 5;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skills chips with wrap layout
              Wrap(
                spacing: 10, // Horizontal spacing between chips
                runSpacing: 10, // Vertical spacing between rows
                children: [
                  // Display first 5 skills as chips
                  ...displaySkills.map((skill) => _buildSkillChip(skill)),

                  // Show "+X more" as plain text if there are more than 5 skills
                  if (remainingSkills > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: Text(
                        '+$remainingSkills more',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.302,
                          color: Color(0xFF524B6B), // From Figma fill_CGYNOA
                        ),
                      ),
                    ),
                ],
              ),

              // "See more" text
              if (skillList.length > 5) ...[
                const SizedBox(height: 16), // Spacing before "See more"
                Center(
                  child: GestureDetector(
                    onTap: () => _navigateToSkills(),
                    child: Text(
                      'See more',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color:
                            AppColors
                                .lookGigActiveIcon, // From Figma fill_I1PCYA
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 23), // Bottom padding
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error building skill chips: $e');
    }
    return const SizedBox(height: 23);
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ), // Match Figma positioning
      decoration: BoxDecoration(
        color: const Color(
          0xFFCBC9D4,
        ).withOpacity(0.2), // From Figma fill_RVD7FX with opacity
        borderRadius: BorderRadius.circular(10), // From Figma borderRadius
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontFamily: 'DM Sans', // From Figma style_T3ZG1Q
          fontWeight: FontWeight.w400,
          fontSize: 12,
          height: 1.302,
          color: Color(0xFF524B6B), // From Figma fill_CGYNOA
        ),
      ),
    );
  }

  Widget _buildResumeContent() {
    try {
      final resumeUrl = _userData['resumeUrl'];
      if (resumeUrl != null) {
        final fileName = _userData['resumeFileName'] ?? 'Resume.pdf';
        final fileSize = '867 Kb'; // Placeholder
        final uploadDate = _getResumeUploadDate();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            15,
            20,
            15,
            0,
          ), // From Figma layout_1YLRPE
          child: Column(
            children: [
              SizedBox(
                width: 300, // From Figma layout_1YLRPE
                height: 44,
                child: Row(
                  children: [
                    // PDF icon using the correct expanded version
                    Image.asset(
                      'assets/images/pdf_icon_expanded.png',
                      width: 44,
                      height: 44,
                    ),
                    const SizedBox(width: 15),
                    // File info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File name (positioned at x: 59, y: 4 from Figma)
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontFamily: 'DM Sans', // From Figma style_OXUNNW
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.302,
                              color: Color(
                                0xFF150B3D,
                              ), // From Figma fill_P3XIW5
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          // File size and upload date
                          Row(
                            children: [
                              Text(
                                fileSize,
                                style: const TextStyle(
                                  fontFamily:
                                      'DM Sans', // From Figma style_OXUNNW
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: Color(
                                    0xFF8983A3,
                                  ), // From Figma fill_M77X8V
                                ),
                              ),
                              const SizedBox(width: 5),
                              // Dot separator
                              Container(
                                width: 2,
                                height: 2,
                                decoration: const BoxDecoration(
                                  color: Color(
                                    0xFF8983A3,
                                  ), // From Figma fill_M77X8V
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                uploadDate,
                                style: const TextStyle(
                                  fontFamily:
                                      'DM Sans', // From Figma style_OXUNNW
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: Color(
                                    0xFF8983A3,
                                  ), // From Figma fill_M77X8V
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Delete icon using the same one from language screen
                    GestureDetector(
                      onTap: _removeResume,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                          'assets/images/language_delete_icon.png', // Same as language screen
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.delete_outline,
                              size: 24,
                              color: Color(0xFFFC4646),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23), // Bottom padding
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error building resume content: $e');
    }
    return const SizedBox(height: 23);
  }

  Future<void> _removeResume() async {
    try {
      setState(() => _isSaving = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employer' ? 'employers' : 'users_specific';

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update({
              'resumeUrl': FieldValue.delete(),
              'resumeFileName': FieldValue.delete(),
              'resumePreviewUrl': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        setState(() {
          _userData.remove('resumeUrl');
          _userData.remove('resumeFileName');
          _userData.remove('resumePreviewUrl');
        });

        _showSuccessSnackBar('Resume removed successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Error removing resume: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _getResumeUploadDate() {
    // For now, return a formatted date. In a real app, you'd use the actual upload timestamp
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${now.day} ${months[now.month - 1]} ${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'pm' : 'am'}';
  }

  Widget _buildAppreciationContent() {
    try {
      final appreciations = _userData['appreciations'];
      if (appreciations is List && appreciations.isNotEmpty) {
        return Column(
          children:
              appreciations.map<Widget>((appreciation) {
                  final title = appreciation['title'] ?? '';
                  final organization = appreciation['organization'] ?? '';
                  final year = appreciation['year'] ?? '';
                  final description = appreciation['description'] ?? '';

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Content (no icon needed according to Figma)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Organization name (positioned at x: 0, y: 0 from Figma)
                                  if (organization.isNotEmpty)
                                    Text(
                                      organization,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        height: 1.302,
                                        color: Color(
                                          0xFF150B3D,
                                        ), // From Figma fill_BU3HQJ
                                      ),
                                    ),
                                  if (organization.isNotEmpty)
                                    const SizedBox(height: 4),

                                  // Title (positioned at x: 0, y: 29 from Figma)
                                  if (title.isNotEmpty)
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        height: 1.302,
                                        color: Color(
                                          0xFF524B6B,
                                        ), // From Figma fill_ZNACG7
                                      ),
                                    ),
                                  if (title.isNotEmpty)
                                    const SizedBox(height: 4),

                                  // Year (positioned at x: 0, y: 50 from Figma)
                                  if (year.isNotEmpty)
                                    Text(
                                      year,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        height: 1.302,
                                        color: Color(
                                          0xFF524B6B,
                                        ), // From Figma fill_ZNACG7
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Edit icon (positioned at x: 291, y: 87 from Figma)
                            GestureDetector(
                              onTap: () => _editAppreciation(appreciation),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/images/appreciation_edit_icon.png',
                                  width: 24,
                                  height: 24,
                                  color: const Color(0xFF2F51A7),
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.edit,
                                      size: 24,
                                      color: Color(0xFF2F51A7),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider line (positioned at x: 20, y: 67 from Figma)
                      if (appreciations.indexOf(appreciation) <
                          appreciations.length - 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Container(
                            width: 295,
                            height: 0.5,
                            color: const Color(
                              0xFFDEE1E7,
                            ), // From Figma stroke_VHHH4W
                          ),
                        ),
                    ],
                  );
                }).toList()
                ..add(const SizedBox(height: 23)), // Bottom padding
        );
      }
    } catch (e) {
      debugPrint('Error building appreciation content: $e');
    }
    return const SizedBox(height: 23);
  }

  String _formatEducationDuration(
    String? startDate,
    String? endDate,
    bool isCurrentEducation,
  ) {
    try {
      if (startDate == null) return 'Duration not specified';

      final start = DateTime.tryParse(startDate);
      if (start == null) return 'Invalid start date';

      final startFormatted = '${_getMonthName(start.month)} ${start.year}';

      if (isCurrentEducation) {
        final duration = _calculateDuration(start, DateTime.now());
        return '$startFormatted - Present • $duration';
      } else if (endDate != null && endDate.isNotEmpty) {
        final end = DateTime.tryParse(endDate);
        if (end != null) {
          final endFormatted = '${_getMonthName(end.month)} ${end.year}';
          final duration = _calculateDuration(start, end);
          return '$startFormatted - $endFormatted • $duration';
        }
      }

      return '$startFormatted - Present';
    } catch (e) {
      return 'Duration not available';
    }
  }

  void _editEducation(Map<String, dynamic> education) {
    debugPrint('Editing education with data: $education');
    // Navigate to education screen with specific education to edit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationScreen(educationToEdit: education),
      ),
    ).then((result) {
      if (result == true) {
        _loadUserData(); // Reload data if changes were made
      }
    });
  }

  Widget _buildNewProfileHeader() {
    String availabilityText = 'Full-time';
    if (_userData['availability'] is String) {
      availabilityText = _userData['availability'];
    } else if (_userData['availability'] is Map) {
      availabilityText = _userData['availability']['type'] ?? 'Full-time';
    }

    return Container(
      width: double.infinity,
      height: 250, // Increased from 220 to fix 26px bottom overflow
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
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/header_background.png'),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {
                // Fallback handled by gradient below
              },
            ),
            gradient: const LinearGradient(
              begin: Alignment(-0.707, -0.707),
              end: Alignment(0.707, 0.707),
              colors: [
                AppColors.profileHeaderGradientStart,
                AppColors.profileHeaderGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 27),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Top row with icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Share icon
                      GestureDetector(
                        onTap: _shareProfile,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/images/header_share_icon.png',
                            width: 24,
                            height: 24,
                            color: AppColors.white,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.share,
                                color: AppColors.white,
                                size: 24,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Settings icon
                      GestureDetector(
                        onTap: () {
                          if (_isEditing) {
                            // Only allow save if not already saving and no uploads in progress
                            if (!_isSaving && !_isAnyUploadInProgress) {
                              setState(() {
                                _isSavingFromSettingsIcon = true;
                              });
                              _saveProfile();
                            } else if (_isAnyUploadInProgress) {
                              _showErrorSnackBar('Please wait for file uploads to complete');
                            }
                          } else {
                            _navigateToSettings();
                          }
                        },
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              // Only show loading spinner when save was triggered from THIS icon
                              (_isEditing && _isSaving && _isSavingFromSettingsIcon)
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Image.asset(
                                    'assets/images/settings_icon.png',
                                    width: 24,
                                    height: 24,
                                    color: AppColors.white,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        _isEditing
                                            ? Icons.save
                                            : Icons.settings,
                                        color: AppColors.white,
                                        size: 24,
                                      );
                                    },
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Profile image
                  GestureDetector(
                    onTap: _isEditing ? _uploadImage : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 62.4,
                          height: 62.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(43),
                            border: Border.all(
                              color: AppColors.white,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(41),
                            child:
                                _isUploadingImage
                                    ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : _selectedImage != null
                                    ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                    : _userData['profileImageUrl'] != null &&
                                        _userData['profileImageUrl']
                                            .toString()
                                            .isNotEmpty
                                    ? ImageUtils.buildSafeNetworkImage(
                                      imageUrl: _userData['profileImageUrl'],
                                      fit: BoxFit.cover,
                                      errorWidget: _buildDefaultAvatar(),
                                      loadingWidget: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                    : _buildDefaultAvatar(),
                          ),
                        ),
                        // Edit indicator when in editing mode
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.lookGigPurple,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 12,
                                color: AppColors.lookGigPurple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // User name
                  Text(
                    _userData['fullName']?.toUpperCase() ?? 'ATUL KUMAR SINGH',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.302,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Availability
                  Text(
                    availabilityText,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.302,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Stats and Edit Profile row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stats on the left
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${_userData['totalEarned'] ?? '0.0'}',
                                  style: const TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    height: 1.362,
                                    color: AppColors.white,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' Earnings',
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    height: 1.362,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 26),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${_userData['weeklyHours'] ?? '0'}',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    height: 1.302,
                                    color: AppColors.white,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' Weekly Hours',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    height: 1.302,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Edit Profile button on the right
                      GestureDetector(
                        onTap: () {
                          print(
                            'Edit profile button tapped! Current _isEditing: $_isEditing',
                          );
                          setState(() {
                            _isEditing = !_isEditing;
                            print('New _isEditing: $_isEditing');
                          });
                        },
                        child: Container(
                          width: 120,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Edit profile',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Image.asset(
                                'assets/images/header_edit_icon.png',
                                width: 16,
                                height: 16,
                                color: AppColors.white,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.edit,
                                    color: AppColors.white,
                                    size: 16,
                                  );
                                },
                              ),
                            ],
                          ),
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

  Widget _buildDefaultAvatar() {
    String initials = 'U';
    if (_userData['fullName'] != null &&
        _userData['fullName'].toString().isNotEmpty) {
      final nameParts = _userData['fullName'].toString().trim().split(' ');
      if (nameParts.length >= 2) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        initials = nameParts[0][0].toUpperCase();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lookGigPurple,
        borderRadius: BorderRadius.circular(41),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
    );
  }

  Widget _buildWorkExperienceSection() {
    // Check if user has work experience data
    final workExp = _userData['workExperience'] as Map<String, dynamic>?;
    final hasExperience = workExp != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 335,
        height: hasExperience ? 173 : 70,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Icon
                  Image.asset(
                    'assets/images/work_experience_icon.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.work,
                        size: 24,
                        color: AppColors.lookGigProfileText,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  // Title
                  const Expanded(
                    child: Text(
                      'Work experience',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.302,
                        color: AppColors.lookGigProfileText,
                      ),
                    ),
                  ),
                  // Add button
                  GestureDetector(
                    onTap: () => _navigateToWorkExperience(),
                    child: Image.asset(
                      'assets/images/add_button_expanded.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.add,
                          size: 24,
                          color: AppColors.lookGigProfileText,
                        );
                      },
                    ),
                  ),
                  if (hasExperience) ...[
                    const SizedBox(width: 20),
                    // Edit button
                    GestureDetector(
                      onTap: () => _showWorkExperienceDialog(),
                      child: Image.asset(
                        'assets/images/edit_button_expanded.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.edit,
                            size: 24,
                            color: AppColors.lookGigProfileText,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Content (placeholder data)
            if (hasExperience) ...[
              Container(
                width: 295,
                height: 0.5,
                color: const Color(0xFFDEE1E7),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manager',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.302,
                          color: AppColors.lookGigProfileText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Amazon Inc',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.302,
                          color: Color(0xFF524B6B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Jan 2015 - Feb 2022',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.362,
                              color: Color(0xFF524B6B),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF524B6B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Text(
                            '5 Years',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.362,
                              color: Color(0xFF524B6B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to refresh profile completion after edits
  void _refreshProfileCompletion() {
    // Profile completion refresh temporarily disabled
  }

  // Navigation methods for each section (will navigate to separate screens later)
  void _navigateToAboutMe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutMeScreen()),
    );

    // Reload user data if changes were made
    if (result == true) {
      _loadUserData();
      _refreshProfileCompletion(); // Update profile completion
    }
  }

  void _navigateToBasicInfo() {
    // TODO: Navigate to Basic Information screen
    _showBasicInfoDialog(); // Temporary - using dialog for now
  }

  void _navigateToWorkExperience() async {
    // This method is for the plus button - always add new work experience
    debugPrint('Navigating to add new work experience');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const WorkExperienceScreen(), // No experienceToEdit = add mode
      ),
    );

    // Reload user data if changes were made
    if (result == true) {
      _loadUserData();
    }
  }

  void _navigateToEducation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EducationScreen()),
    ).then((result) {
      if (result == true) {
        _loadUserData(); // Reload data if changes were made
      }
    });
  }

  void _navigateToSkills() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SkillsScreen()),
    );

    // Reload user data if changes were made
    if (result == true) {
      _loadUserData();
      _refreshProfileCompletion(); // Update profile completion
    }
  }

  void _navigateToLanguage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LanguageScreen()),
    );

    // Reload user data if changes were made
    if (result == true) {
      _loadUserData();
    }
  }

  void _navigateToAppreciation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppreciationScreen()),
    );

    // Reload user data if changes were made
    if (result == true) {
      _loadUserData();
    }
  }

  void _editAppreciation(Map<String, dynamic> appreciation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AppreciationScreen(appreciationToEdit: appreciation),
      ),
    );

    // Reload user data if changes were made
    if (result == true) {
      _loadUserData();
    }
  }

  void _navigateToAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressEditScreen(),
      ),
    );
    
    // Reload user data if address was updated
    if (result == true) {
      _loadUserData();
      _refreshProfileCompletion(); // Update profile completion
    }
  }

  void _navigateToResume() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResumeScreen()),
    );

    if (result == true) {
      // Reload user data if resume was updated
      _loadUserData();
      _refreshProfileCompletion(); // Update profile completion
    }
  }

  void _navigateToMyApplications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyApplicationsScreen()),
    );
  }

  void _navigateToSettings() async {
    // Don't navigate to settings if currently saving
    if (_isSaving) {
      _showErrorSnackBar('Please wait for the save operation to complete');
      return;
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    
    // Reset saving state when returning from settings screen
    // This ensures the settings icon doesn't show a spinner if there was any state issue
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Dialog methods for each section (temporary - will be replaced with separate screens)
  void _showBasicInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Basic Information'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Icons.info_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveProfile();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showWorkExperienceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Work Experience'),
            content: const Text('Work experience management coming soon...'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showEducationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Education'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdown(
                  value: _selectedEducation,
                  options: const [
                    'High School',
                    'Bachelor\'s Degree',
                    'Master\'s Degree',
                    'PhD',
                    'Other',
                  ],
                  label: 'Education Level',
                  icon: Icons.school_rounded,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedEducation = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _collegeController,
                  label: 'College/University',
                  icon: Icons.account_balance_rounded,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveProfile();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showSkillsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Skills'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            onDeleted:
                                _isEditing
                                    ? () {
                                      setState(() {
                                        _skills.remove(skill);
                                      });
                                    }
                                    : null,
                          );
                        }).toList(),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _skillSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Add Skill',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !_skills.contains(value)) {
                          setState(() {
                            _skills.add(value);
                            _skillSearchController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveProfile();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Languages'),
            content: const Text('Language management coming soon...'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAddressDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Address'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _zipCodeController,
                  label: 'Zip Code',
                  icon: Icons.local_post_office_rounded,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveProfile();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Resume'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResumeField(),
                if (_isEditing)
                  ElevatedButton(
                    onPressed: _uploadResume,
                    child: const Text('Upload New Resume'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Helper method to build text fields (preserved from original)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _isEditing ? AppColors.white : AppColors.softGrey,
        ),
      ),
    );
  }

  // Helper method to build dropdowns (preserved from original)
  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: _isEditing ? onChanged : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _isEditing ? AppColors.white : AppColors.softGrey,
        ),
        items:
            options.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
      ),
    );
  }

  Widget _buildResumeField() {
    final hasResume = _userData['resumeUrl'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resume',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.hintText,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isEditing ? _uploadResume : null,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData['resumeFileName'] ?? 'No resume uploaded',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_userData['resumeFileName'] != null && _isEditing)
                          const Text(
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
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  else if (hasResume)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final url = _userData['resumeUrl'];
                            if (url != null) {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.visibility_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          tooltip: 'View Resume',
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required String value,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Initialize controller with current value if empty
    if (controller.text.isEmpty && value.isNotEmpty) {
      controller.text = value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans', // From Figma style_EHE33O
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150A33), // From Figma fill_OU8AHA
          ),
        ),
        const SizedBox(height: 10),
        // Input field
        Container(
          width: 335, // From Figma layout_UDKFE8
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white, // From Figma fill_9W0HJQ
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF99ABC6,
                ).withOpacity(0.18), // From Figma effect_21L0WT
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: 'DM Sans', // From Figma style_K6P654
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.302,
              color: Color(0xFF524B6B), // From Figma fill_FXS4KJ
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150A33),
          ),
        ),
        const SizedBox(height: 10),
        // Date field
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 335,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99ABC6).withOpacity(0.18),
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : 'Select date',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.302,
                      color: Color(0xFF524B6B),
                    ),
                  ),
                ),
                // Calendar icon (positioned at x: 291, y: 34 from Figma)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: const Icon(
                      Icons.calendar_today,
                      size: 24,
                      color: Color(0xFF150B3D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneFieldWithCountryCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone number',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150A33),
          ),
        ),
        const SizedBox(height: 10),
        PhoneInputField(
          phoneController: _phoneController,
          labelText: '',
          hintText: 'Enter phone number',
        ),
      ],
    );
  }

  Widget _buildAvailabilityField() {
    final List<DropdownItem> availabilityOptions = [
      DropdownItem(value: 'Full-time', label: 'Full-time'),
      DropdownItem(value: 'Part-time', label: 'Part-time'),
      DropdownItem(value: 'Contract', label: 'Contract'),
      DropdownItem(value: 'Freelance', label: 'Freelance'),
      DropdownItem(value: 'Internship', label: 'Internship'),
    ];

    return CustomDropdownField(
      labelText: 'Availability',
      hintText: 'Select availability',
      value: _selectedAvailability,
      items: availabilityOptions,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedAvailability = value;
          });
        }
      },
      enableSearch: false,
      modalTitle: 'Select Availability',
    );
  }

  Widget _buildPhoneField({
    required String label,
    required TextEditingController controller,
    required String value,
  }) {
    // Initialize controller with current value if empty
    if (controller.text.isEmpty && value.isNotEmpty) {
      controller.text = value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150A33),
          ),
        ),
        const SizedBox(height: 10),
        // Phone input field
        Container(
          width: 335,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF99ABC6).withOpacity(0.18),
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              // Country code
              const Text(
                '1+',
                style: TextStyle(
                  fontFamily: 'Open Sans', // From Figma style_IR952X
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.362,
                  color: Color(0xFF524B6B),
                ),
              ),
              // Divider line (positioned at x: 81, y: 36 from Figma)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                width: 1,
                height: 20,
                color: const Color(0xFFC4C4C4), // From Figma stroke_UXOBHS
              ),
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.302,
                    color: Color(0xFF524B6B),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    hintText: '619 3456 7890',
                    hintStyle: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.302,
                      color: Color(0xFF524B6B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Gender',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150A33),
          ),
        ),
        const SizedBox(height: 10),
        // Gender options
        Row(
          children: [
            // Male option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Male';
                  });
                },
                child: Container(
                  width: 160, // From Figma layout_3MDX1H
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF99ABC6).withOpacity(0.18),
                        blurRadius: 62,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      // Radio button
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _selectedGender == 'Male'
                                    ? const Color(
                                      0xFF2F51A7,
                                    ) // From Figma stroke_2S3WJQ
                                    : const Color(
                                      0xFF524B6B,
                                    ), // From Figma stroke_R1HDJY
                            width: 1.5,
                          ),
                        ),
                        child:
                            _selectedGender == 'Male'
                                ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(
                                        0xFF2F51A7,
                                      ), // Changed to blue
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      // Male text
                      const Text(
                        'Male',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.302,
                          color: Color(0xFF524B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // Female option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Female';
                  });
                },
                child: Container(
                  width: 160, // From Figma layout_JZDY17
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF99ABC6).withOpacity(0.18),
                        blurRadius: 62,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      // Radio button
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _selectedGender == 'Female'
                                    ? const Color(0xFF2F51A7)
                                    : const Color(0xFF524B6B),
                            width: 1.5,
                          ),
                        ),
                        child:
                            _selectedGender == 'Female'
                                ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(
                                        0xFF2F51A7,
                                      ), // From Figma fill_HMEZ2A
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      // Female text
                      const Text(
                        'Female',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.302,
                          color: Color(0xFF524B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: 213, // From Figma layout_RU7X6N
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF130160), // From Figma fill_QU7AAI
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF99ABC6,
              ).withOpacity(0.18), // From Figma effect_21L0WT
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child:
              _isSaving
                  ? const CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  )
                  : const Text(
                    'SAVE',
                    style: TextStyle(
                      fontFamily: 'DM Sans', // From Figma style_DHN941
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.302,
                      letterSpacing: 0.84,
                      color: AppColors.white, // From Figma fill_9W0HJQ
                    ),
                  ),
        ),
      ),
    );
  }

  String _formatDateOfBirth() {
    if (_dateOfBirth != null) {
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${_dateOfBirth!.day.toString().padLeft(2, '0')} ${months[_dateOfBirth!.month - 1]} ${_dateOfBirth!.year}';
    }
    return _userData['dateOfBirth'] ?? '';
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1992, 8, 6),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }
}
