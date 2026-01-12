import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/error_handler.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/cd_servi.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:get_work_app/widgets/image_viewer.dart';

class CompanyLogoEditScreen extends StatefulWidget {
  final Map<String, dynamic> companyInfo;

  const CompanyLogoEditScreen({super.key, required this.companyInfo});

  @override
  State<CompanyLogoEditScreen> createState() => _CompanyLogoEditScreenState();
}

class _CompanyLogoEditScreenState extends State<CompanyLogoEditScreen> {
  String? _logoUrl;
  File? _selectedImage;
  bool _isUploading = false;
  bool _isPickingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.companyInfo['companyLogo'];
  }

  Future<void> _pickImageFromGallery() async {
    print('🎯 [LOGO_GALLERY] Pick from gallery called');
    
    if (_isPickingImage) {
      print('⚠️ [LOGO_GALLERY] Already picking, ignoring');
      return;
    }

    try {
      setState(() {
        _isPickingImage = true;
      });

      print('📸 [LOGO_GALLERY] Opening gallery picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      print('📊 [LOGO_GALLERY] Picker returned: ${image != null ? image.path : 'null (cancelled)'}');

      if (image != null) {
        final file = File(image.path);
        
        // Check if file exists
        if (!await file.exists()) {
          print('❌ [LOGO_GALLERY] File does not exist: ${image.path}');
          CustomToast.show(
            context,
            message: 'Unable to access selected file',
            isSuccess: false,
          );
          return;
        }
        
        // Check file size
        final fileSize = await file.length();
        print('📊 [LOGO_GALLERY] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        if (fileSize > 5 * 1024 * 1024) {
          CustomToast.show(
            context,
            message: 'Image must be less than 5MB',
            isSuccess: false,
          );
          return;
        }

        setState(() {
          _selectedImage = file;
        });
        
        print('✅ [LOGO_GALLERY] Image selected successfully');
        CustomToast.show(
          context,
          message: 'Logo selected',
          isSuccess: true,
        );
      } else {
        print('ℹ️ [LOGO_GALLERY] User cancelled selection');
      }
    } on PlatformException catch (e) {
      print('❌ [LOGO_GALLERY] Platform exception: ${e.code} - ${e.message}');
      
      if (e.code == 'already_active') {
        return; // Silently ignore
      } else if (e.code == 'photo_access_denied') {
        CustomToast.show(
          context,
          message: 'Please grant photo access in settings',
          isSuccess: false,
        );
      } else {
        CustomToast.show(
          context,
          message: 'Failed to select image',
          isSuccess: false,
        );
      }
    } catch (e) {
      print('❌ [LOGO_GALLERY] Error: $e');
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    print('🎯 [LOGO_CAMERA] Pick from camera called');
    
    if (_isPickingImage) {
      print('⚠️ [LOGO_CAMERA] Already picking, ignoring');
      return;
    }

    try {
      setState(() {
        _isPickingImage = true;
      });

      print('📸 [LOGO_CAMERA] Opening camera...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      print('📊 [LOGO_CAMERA] Camera returned: ${image != null ? image.path : 'null (cancelled)'}');

      if (image != null) {
        final file = File(image.path);
        
        if (!await file.exists()) {
          print('❌ [LOGO_CAMERA] File does not exist');
          CustomToast.show(
            context,
            message: 'Unable to access photo',
            isSuccess: false,
          );
          return;
        }

        setState(() {
          _selectedImage = file;
        });
        
        print('✅ [LOGO_CAMERA] Photo captured successfully');
        CustomToast.show(
          context,
          message: 'Photo captured',
          isSuccess: true,
        );
      }
    } on PlatformException catch (e) {
      print('❌ [LOGO_CAMERA] Platform exception: ${e.code} - ${e.message}');
      
      if (e.code == 'camera_access_denied') {
        CustomToast.show(
          context,
          message: 'Please grant camera access in settings',
          isSuccess: false,
        );
      } else {
        CustomToast.show(
          context,
          message: 'Failed to capture photo',
          isSuccess: false,
        );
      }
    } catch (e) {
      print('❌ [LOGO_CAMERA] Error: $e');
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<void> _uploadLogo() async {
    print('🚀 [LOGO_UPLOAD] Upload started');
    
    if (_selectedImage == null) {
      print('❌ [LOGO_UPLOAD] No image selected');
      CustomToast.show(
        context,
        message: 'Please select an image first',
        isSuccess: false,
      );
      return;
    }

    print('📁 [LOGO_UPLOAD] Image path: ${_selectedImage!.path}');
    print('📁 [LOGO_UPLOAD] File exists: ${await _selectedImage!.exists()}');

    setState(() => _isUploading = true);

    try {
      print('☁️ [LOGO_UPLOAD] Uploading to Cloudinary...');
      final String? uploadedUrl = await CloudinaryService.uploadImage(_selectedImage!);

      print('📊 [LOGO_UPLOAD] Upload result: ${uploadedUrl ?? 'null'}');

      if (uploadedUrl != null) {
        print('✅ [LOGO_UPLOAD] Upload successful, saving to Firestore...');
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('👤 [LOGO_UPLOAD] User ID: ${user.uid}');
          
          // Update in the employers collection, not users
          await FirebaseFirestore.instance
              .collection('employers')
              .doc(user.uid)
              .update({
            'companyInfo.companyLogo': uploadedUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('✅ [LOGO_UPLOAD] Firestore updated successfully');

          // Update profile completion status
          AuthService.updateProfileCompletionStatus();

          if (mounted) {
            CustomToast.show(
              context,
              message: 'Logo uploaded successfully!',
              isSuccess: true,
            );
            
            // Wait a moment for toast to show
            await Future.delayed(const Duration(milliseconds: 500));
            
            Navigator.pop(context, true);
          }
        }
      } else {
        print('❌ [LOGO_UPLOAD] Upload returned null');
        CustomToast.show(
          context,
          message: 'Failed to upload logo',
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      print('❌ [LOGO_UPLOAD] Error: $e');
      print('📍 [LOGO_UPLOAD] Stack trace: $stackTrace');
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _removeLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Logo'),
        content: const Text('Are you sure you want to remove the company logo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isUploading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('companyInfo')
              .doc('details')
              .set({
            'companyLogo': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        ErrorHandler.showErrorSnackBar(context, e);
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    CustomToast.show(
      context,
      message: message,
      isSuccess: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gigAppLightGray,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildLogoPreview(),
                  const SizedBox(height: 40),
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Choose from Gallery',
                    onTap: _pickImageFromGallery,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    onTap: _pickImageFromCamera,
                  ),
                  if (_logoUrl != null || _selectedImage != null) ...[
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Remove Logo',
                      onTap: _removeLogo,
                      isDestructive: true,
                    ),
                  ],
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 32),
                    _buildUploadButton(),
                  ],
                ],
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
                AppColors.gigAppProfileGradientStart,
                AppColors.gigAppProfileGradientEnd,
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
                          'Company Logo',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload or change logo',
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

  Widget _buildLogoPreview() {
    final bool hasImage = _selectedImage != null || (_logoUrl != null && _logoUrl!.isNotEmpty);
    
    return GestureDetector(
      onTap: hasImage ? () {
        // Open full screen image viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewer(
              imageFile: _selectedImage,
              imageUrl: _logoUrl,
              title: 'Company Logo',
            ),
          ),
        );
      } : null,
      child: Stack(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.profileCardShadow,
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : _logoUrl != null && _logoUrl!.isNotEmpty
                      ? Image.network(
                          _logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
            ),
          ),
          // Show zoom icon overlay when image exists
          if (hasImage)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.gigAppLightGray,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 60, color: AppColors.gigAppDescriptionText),
            SizedBox(height: 8),
            Text(
              'No Logo',
              style: TextStyle(
                color: AppColors.gigAppDescriptionText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDestructive ? AppColors.error : const Color(0xFF2F51A7)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : const Color(0xFF2F51A7),
            size: 24,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : AppColors.gigAppProfileText,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive ? AppColors.error : AppColors.gigAppDescriptionText,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _uploadLogo,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gigAppPurple,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isUploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Upload Logo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
