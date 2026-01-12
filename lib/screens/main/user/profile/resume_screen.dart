import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/services/pdf_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingResume = false;
  Map<String, dynamic> _userData = {};
  File? _selectedResume;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

        if (doc.exists && doc.data() != null) {
          setState(() {
            _userData = doc.data()!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _userData = {};
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading resume data: $e');
    }
  }

  Future<void> _uploadResume() async {
    try {
      final typeGroup = XTypeGroup(label: 'PDFs', extensions: ['pdf']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        setState(() {
          _selectedResume = File(file.path);
          _isUploadingResume = true;
        });

        // Use PDFService to handle the upload and preview generation
        final uploadResult = await PDFService.uploadResumePDF(_selectedResume!);

        if (uploadResult['pdfUrl'] == null) {
          throw Exception('Failed to upload resume');
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final role = await AuthService.getUserRole();
          final collectionName =
              role == 'employer' ? 'employers' : 'users_specific';

          // Update Firestore with available data
          final updateData = {
            'resumeUrl': uploadResult['pdfUrl'],
            'resumeFileName': file.name,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Only add preview URL if it was successfully generated
          if (uploadResult['previewUrl'] != null) {
            updateData['resumePreviewUrl'] = uploadResult['previewUrl'];
          }

          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid)
              .update(updateData);

          // Update profile completion status
          AuthService.updateProfileCompletionStatus();

          setState(() {
            _userData['resumeUrl'] = uploadResult['pdfUrl'];
            _userData['resumeFileName'] = file.name;
            if (uploadResult['previewUrl'] != null) {
              _userData['resumePreviewUrl'] = uploadResult['previewUrl'];
            }
          });

          _showSuccessSnackBar(
            uploadResult['previewUrl'] != null
                ? 'Resume updated successfully!'
                : 'Resume uploaded successfully (preview generation failed)',
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading resume: $e');
    } finally {
      setState(() {
        _isUploadingResume = false;
        _selectedResume = null;
      });
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_BXQ825
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gigAppPurple),
        ),
      );
    }

    final hasResume = _userData['resumeUrl'] != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_BXQ825
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button (positioned at x: 20, y: 30 from Figma)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/images/about_me_back_icon.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF524B6B),
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF524B6B),
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    64,
                    20,
                    0,
                  ), // y: 94 from Figma
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width.clamp(0, 375),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (positioned at x: 0, y: 0 from Figma)
                        const Text(
                          'Add Resume',
                          style: TextStyle(
                            fontFamily: 'Open Sans', // From Figma style_VR3ZQ9
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.362,
                            color: Color(0xFF150A33), // From Figma fill_PYV02H
                          ),
                        ),

                        const SizedBox(height: 52), // Gap to upload section
                        // Upload section or resume display
                        hasResume ? _buildResumeDisplay() : _buildUploadSection(),

                        const SizedBox(height: 15), // Gap to description
                        // Description text
                        const Text(
                          'Upload files in PDF format up to 5 MB. Just upload it once and you can use it in your next application.',
                          style: TextStyle(
                            fontFamily: 'Open Sans', // From Figma style_0FJQYN
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            height: 1.362,
                            color: Color(0xFFAAA6B9), // From Figma fill_2VH8BQ
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Save button (positioned at x: 81, y: 672 from Figma)
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                child: GestureDetector(
                  onTap: _isSaving ? null : () => Navigator.pop(context, true),
                  child: Container(
                    width: MediaQuery.of(context).size.width.clamp(213, 335),
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF130160), // From Figma fill_8UHQ79
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF99ABC6).withOpacity(0.18),
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
                                  fontFamily:
                                      'DM Sans', // From Figma style_FYLOY7
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.302,
                                  letterSpacing: 0.84,
                                  color:
                                      AppColors.white, // From Figma fill_3YB7JO
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return GestureDetector(
      onTap: _isUploadingResume ? null : _uploadResume,
      child: Container(
        width: double.infinity,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF9D97B5), // From Figma stroke_C7FANN
            width: 0.5,
            style: BorderStyle.solid,
          ),
        ),
        child:
            _isUploadingResume
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gigAppPurple,
                    strokeWidth: 2,
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Upload icon (positioned at x: 94, y: 26 from Figma)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/images/upload_icon.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF3B4657),
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.upload_file,
                            size: 24,
                            color: Color(0xFF3B4657),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Upload text (positioned at x: 133, y: 30 from Figma)
                    const Text(
                      'Upload CV/Resume',
                      style: TextStyle(
                        fontFamily: 'Open Sans', // From Figma style_95DIGA
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.362,
                        color: Color(0xFF150A33), // From Figma fill_PYV02H
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _openResume() async {
    final resumeUrl = _userData['resumeUrl'];
    if (resumeUrl == null) return;

    try {
      final uri = Uri.parse(resumeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open resume');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening resume: $e');
    }
  }

  Widget _buildResumeDisplay() {
    final fileName = _userData['resumeFileName'] ?? 'Resume.pdf';
    final fileSize = _getFileSize();
    final uploadDate = _getUploadDate();

    return GestureDetector(
      onTap: _openResume,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(
            0xFF3F13E4,
          ).withOpacity(0.05), // From Figma fill_R1A134
          borderRadius: BorderRadius.circular(20), // From Figma borderRadius
          border: Border.all(
            color: const Color(0xFF9D97B5), // From Figma stroke_UFLR1V
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resume file info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF icon
                  Image.asset(
                    'assets/images/pdf_icon_expanded.png',
                    width: 44,
                    height: 44,
                  ),
                  const SizedBox(width: 15),
                  // File details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File name
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.302,
                            color: Color(0xFF150B3D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // File size and date
                        Text(
                          '$fileSize • $uploadDate',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.302,
                            color: Color(0xFF8983A3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tap to open hint
                        const Text(
                          'Tap to open',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            height: 1.302,
                            color: Color(0xFF130160),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Remove file section
              GestureDetector(
                onTap: _isSaving ? null : _removeResume,
                child: Row(
                  children: [
                    // Delete icon
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/images/language_delete_icon.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFFFC4646),
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.delete_outline,
                            size: 24,
                            color: Color(0xFFFC4646),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Remove text
                    const Text(
                      'Remove file',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: Color(0xFFFC4646),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFileSize() {
    // For now, return a default size. In a real app, you'd calculate this from the file
    return '867 Kb';
  }

  String _getUploadDate() {
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
}
