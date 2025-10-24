import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:get_work_app/screens/main/employer/applicants/chat_detail_screen.dart'
    as chat;
import 'package:get_work_app/services/chat_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> applicant;
  final String jobTitle;

  const ApplicantDetailsScreen({
    super.key,
    required this.applicant,
    required this.jobTitle,
  });

  @override
  State<ApplicantDetailsScreen> createState() => _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  String? _resumePreviewUrl;
  String? _resumeUrl;
  bool _isLoading = true;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Debug print to check the data
    print('Applicant Data: ${widget.applicant}');
    print('Resume URL: ${widget.applicant['resumeUrl']}');
    print('Resume Preview URL: ${widget.applicant['resumePreviewUrl']}');
    // Defer initialization to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      print('🔍 [RESUME PREVIEW] Loading resume data...');
      print('   Applicant ID: ${widget.applicant['applicantId']}');
      print('   Applicant Data Keys: ${widget.applicant.keys.toList()}');

      // First check if resume URL exists in applicant data
      String? resumeUrl = widget.applicant['resumeUrl'];
      String? resumePreviewUrl = widget.applicant['resumePreviewUrl'];

      print('   Resume URL from applicant data: ${resumeUrl ?? 'Not found'}');
      print(
        '   Resume Preview URL from applicant data: ${resumePreviewUrl ?? 'Not found'}',
      );

      // If not found in applicant data, check users_specific collection
      if ((resumeUrl == null || resumeUrl.isEmpty) &&
          (resumePreviewUrl == null || resumePreviewUrl.isEmpty)) {
        print('   Checking users_specific collection...');
        final userData =
            await FirebaseFirestore.instance
                .collection('users_specific')
                .doc(widget.applicant['applicantId'])
                .get();

        if (userData.exists) {
          final data = userData.data();
          resumeUrl = data?['resumeUrl'];
          resumePreviewUrl = data?['resumePreviewUrl'];
          print(
            '   Resume URL from users_specific: ${resumeUrl ?? 'Not found'}',
          );
          print(
            '   Resume Preview URL from users_specific: ${resumePreviewUrl ?? 'Not found'}',
          );
        } else {
          print('   ⚠️ User document not found in users_specific');
        }
      }

      if (mounted) {
        setState(() {
          _resumePreviewUrl = resumePreviewUrl;
          _resumeUrl = resumeUrl;
          _isLoading = false;
        });

        print('📊 [RESUME PREVIEW] Final state:');
        print('   Preview URL: ${_resumePreviewUrl ?? 'NULL'}');
        print('   Resume URL: ${_resumeUrl ?? 'NULL'}');
        print('   CV File Name: ${widget.applicant['cvFileName'] ?? 'NULL'}');

        if (_resumePreviewUrl != null && _resumePreviewUrl!.isNotEmpty) {
          print('✅ [RESUME PREVIEW] Resume preview URL loaded successfully');
        } else if (_resumeUrl != null && _resumeUrl!.isNotEmpty) {
          print('⚠️ [RESUME PREVIEW] Resume URL exists but no preview');
        } else {
          print('⚠️ [RESUME PREVIEW] No resume URLs available');
        }
      }
    } catch (e, stackTrace) {
      print('❌ [RESUME PREVIEW] Error loading user data: $e');
      print('Stack trace: $stackTrace');
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
          _buildCustomHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card - Full Width
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF99ABC6).withOpacity(0.18),
                          blurRadius: 62,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Image
                        ImageUtils.buildSafeCircleAvatar(
                          radius: 50,
                          imagePath: widget.applicant['applicantProfileImg'],
                          child:
                              widget.applicant['applicantProfileImg'] == null ||
                                      widget
                                          .applicant['applicantProfileImg']
                                          .isEmpty
                                  ? Text(
                                    widget.applicant['applicantName'][0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lookGigPurple,
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.applicant['applicantName'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D0140),
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Applied for ${widget.jobTitle}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.lookGigPurple,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer<ApplicantStatusProvider>(
                          builder: (context, provider, child) {
                            final currentStatus =
                                provider.getStatus(
                                  widget.applicant['companyName'],
                                  widget.applicant['jobId'],
                                  widget.applicant['id'],
                                ) ??
                                'pending';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  currentStatus,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(currentStatus),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contact Information
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSection(
                      'Contact Information',
                      Icons.contact_mail_outlined,
                      [
                        _buildInfoRow(
                          'Email',
                          widget.applicant['applicantEmail'] ?? 'N/A',
                          Icons.email_outlined,
                        ),
                        _buildInfoRow(
                          'Phone',
                          widget.applicant['applicantPhone'] ?? 'N/A',
                          Icons.phone_outlined,
                        ),
                        _buildInfoRow(
                          'Address',
                          widget.applicant['applicantAddress'] ?? 'N/A',
                          Icons.location_on_outlined,
                        ),
                        _buildInfoRow(
                          'Gender',
                          widget.applicant['applicantGender'] ?? 'N/A',
                          Icons.person_outline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Application Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSection(
                      'Application Details',
                      Icons.description_outlined,
                      [
                        _buildInfoRow(
                          'Experience',
                          widget.applicant['yearsOfExperience'] ?? 'N/A',
                          Icons.work_outline,
                        ),
                        _buildInfoRow(
                          'Applied On',
                          _formatDate(
                            DateTime.parse(widget.applicant['appliedAt']),
                          ),
                          Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Skills
                  if (widget.applicant['applicantSkills'] != null &&
                      (widget.applicant['applicantSkills'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child:
                          _buildSection('Skills', Icons.psychology_outlined, [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  (widget.applicant['applicantSkills'] as List)
                                      .map(
                                        (skill) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFFF9228,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            skill,
                                            style: const TextStyle(
                                              color: Color(0xFFFF9228),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'DM Sans',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ]),
                    ),

                  const SizedBox(height: 20),

                  // Why Join
                  if (widget.applicant['whyJoin'] != null &&
                      widget.applicant['whyJoin'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSection(
                        'Why They Want to Join',
                        Icons.lightbulb_outline,
                        [
                          Text(
                            widget.applicant['whyJoin'],
                            style: const TextStyle(
                              color: Color(0xFF524B6B),
                              fontSize: 14,
                              height: 1.5,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Resume Preview
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF9228),
                      ),
                    )
                  else if (_resumePreviewUrl != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSection('Resume', Icons.description_outlined, [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Preview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            // Open the actual PDF document
                            if (_resumeUrl != null && _resumeUrl!.isNotEmpty) {
                              print('📄 Opening PDF document: $_resumeUrl');
                              try {
                                final uri = Uri.parse(_resumeUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  print('✅ PDF opened successfully');
                                } else {
                                  print('❌ Cannot launch URL: $_resumeUrl');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not open resume PDF',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print('❌ Error opening PDF: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error opening PDF: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            } else {
                              print('⚠️ No PDF URL available');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Resume PDF not available'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.mutedText.withOpacity(0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  // Preview Image
                                  Image.network(
                                    _resumePreviewUrl!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
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
                                          color: const Color(0xFFFF9228),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading preview: $error');
                                      print('Stack trace: $stackTrace');
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: AppColors.error,
                                              size: 32,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Failed to load resume preview',
                                              style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  // Tap Indicator Overlay
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.black.withOpacity(0.4),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.open_in_new,
                                            color: AppColors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Tap to view full document',
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'DM Sans',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSection('Resume', Icons.description_outlined, [
                        // Show CV file info if available
                        if (widget.applicant['cvFileName'] != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9228).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF9228).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFF9228,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.description,
                                        color: Color(0xFFFF9228),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.applicant['cvFileName'] ??
                                                'Resume.pdf',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D0140),
                                              fontFamily: 'DM Sans',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${widget.applicant['cvFileSize'] ?? 'Unknown size'} • ${widget.applicant['cvFileDate'] ?? 'Unknown date'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF524B6B),
                                              fontFamily: 'DM Sans',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Show button to view PDF if URL exists
                                if (_resumeUrl != null &&
                                    _resumeUrl!.isNotEmpty)
                                  Column(
                                    children: [
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF99ABC6,
                                              ).withOpacity(0.18),
                                              blurRadius: 62,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              final uri = Uri.parse(
                                                _resumeUrl!,
                                              );
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode:
                                                      LaunchMode
                                                          .externalApplication,
                                                );
                                              } else {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Could not open resume',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              print('Error opening resume: $e');
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.open_in_new,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'VIEW RESUME PDF',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'DM Sans',
                                              letterSpacing: 0.84,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFFF9228,
                                            ),
                                            foregroundColor: AppColors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: const Color(0xFFFF9228),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Resume file uploaded. Preview not available.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF524B6B),
                                              fontFamily: 'DM Sans',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.error.withOpacity(0.8),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No resume information available',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ]),
                    ),

                  const SizedBox(height: 20),

                  // Status Action Buttons
                  if (widget.applicant['status']?.toLowerCase() != 'accepted' &&
                      widget.applicant['status']?.toLowerCase() != 'rejected')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF99ABC6,
                                    ).withOpacity(0.18),
                                    blurRadius: 62,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus('accepted'),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                ),
                                label: const Text(
                                  'ACCEPT',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DM Sans',
                                    letterSpacing: 0.84,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9228),
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF99ABC6,
                                    ).withOpacity(0.18),
                                    blurRadius: 62,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus('rejected'),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 20,
                                ),
                                label: const Text(
                                  'REJECT',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DM Sans',
                                    letterSpacing: 0.84,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.lookGigPurple,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Contact Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        if (widget.applicant['applicantPhone'] != null &&
                            widget.applicant['applicantPhone'].isNotEmpty)
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF99ABC6,
                                    ).withOpacity(0.18),
                                    blurRadius: 62,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _makePhoneCall(
                                      widget.applicant['applicantPhone'],
                                    ),
                                icon: const Icon(Icons.phone, size: 20),
                                label: const Text(
                                  'CALL',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DM Sans',
                                    letterSpacing: 0.84,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.lookGigPurple,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        if (widget.applicant['applicantPhone'] != null &&
                            widget.applicant['applicantPhone'].isNotEmpty)
                          const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF99ABC6,
                                  ).withOpacity(0.18),
                                  blurRadius: 62,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _messageApplicant(),
                              icon: const Icon(Icons.message, size: 20),
                              label: const Text(
                                'MESSAGE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'DM Sans',
                                  letterSpacing: 0.84,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lookGigPurple,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        if (widget.applicant['applicantEmail'] != null &&
                            widget.applicant['applicantEmail'].isNotEmpty)
                          const SizedBox(width: 12),
                        if (widget.applicant['applicantEmail'] != null &&
                            widget.applicant['applicantEmail'].isNotEmpty)
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF99ABC6,
                                    ).withOpacity(0.18),
                                    blurRadius: 62,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _sendEmail(
                                      widget.applicant['applicantEmail'],
                                    ),
                                icon: const Icon(Icons.email, size: 20),
                                label: const Text(
                                  'EMAIL',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DM Sans',
                                    letterSpacing: 0.84,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.lookGigPurple,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print('Could not launch phone call: $e');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters({
        'subject': 'Regarding your job application for ${widget.jobTitle}',
      }),
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print('Could not launch email: $e');
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF99ABC6).withOpacity(0.18),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9228).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFFF9228), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9228).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF9228), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF524B6B),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0D0140),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithCustomIcon(
    String label,
    String value,
    String iconPath,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9228).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: 18,
              height: 18,
              child: Image.asset(
                iconPath,
                width: 18,
                height: 18,
                color: const Color(0xFFFF9228),
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFFFF9228),
                    size: 18,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF524B6B),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0D0140),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'shortlisted':
        return const Color(0xFFFF9228);
      default:
        return const Color(0xFFFF9228); // Orange for pending
    }
  }

  Widget _buildCustomHeader(BuildContext context) {
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
                          'Applicant Details',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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

  void _messageApplicant() {
    final chatId = _chatService.getChatId(
      FirebaseAuth.instance.currentUser!.uid,
      widget.applicant['applicantId'],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => chat.ChatDetailScreen(
              chatId: chatId,
              otherUserId: widget.applicant['applicantId'],
              otherUserName: widget.applicant['applicantName'],
            ),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      // Use the ApplicantStatusProvider to update the status
      await context.read<ApplicantStatusProvider>().updateStatus(
        companyName: widget.applicant['companyName'],
        jobId: widget.applicant['jobId'],
        applicantId: widget.applicant['id'],
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.toLowerCase()}'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context, status);
      }
    } catch (e) {
      print('Error updating status: $e');
      if (mounted) {
        Navigator.pop(context, status);
      }
    }
  }
}
