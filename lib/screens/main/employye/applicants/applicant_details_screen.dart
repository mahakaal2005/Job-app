import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:get_work_app/screens/main/employye/applicants/chat_detail_screen.dart'
    as chat;
import 'package:get_work_app/services/chat_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
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
  bool _isLoading = true;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Debug print to check the data
    print('Applicant Data: ${widget.applicant}');
    print('Resume URL: ${widget.applicant['resumeUrl']}');
    print('Resume Preview URL: ${widget.applicant['resumePreviewUrl']}');
  }

  Future<void> _loadUserData() async {
    try {
      final userData =
          await FirebaseFirestore.instance
              .collection('users_specific')
              .doc(widget.applicant['applicantId'])
              .get();

      if (mounted) {
        setState(() {
          _resumePreviewUrl = userData.data()?['resumePreviewUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryAccent,
        elevation: 0,
        title: Text(
          'Applicant Details',
          style: TextStyle(
            color: AppColors.textOnAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textOnAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.background.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        widget.applicant['applicantProfileImg'] != null &&
                                widget
                                    .applicant['applicantProfileImg']
                                    .isNotEmpty
                            ? NetworkImage(
                              widget.applicant['applicantProfileImg'],
                            )
                            : null,
                    child:
                        widget.applicant['applicantProfileImg'] == null ||
                                widget.applicant['applicantProfileImg'].isEmpty
                            ? Text(
                              widget.applicant['applicantName'][0]
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAccent,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.applicant['applicantName'] ?? 'Anonymous',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applied for ${widget.jobTitle}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w500,
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            currentStatus,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentStatus.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(currentStatus),
                            fontWeight: FontWeight.w600,
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
            _buildSection('Contact Information', Icons.contact_mail_outlined, [
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
            ]),

            const SizedBox(height: 20),

            // Application Details
            _buildSection('Application Details', Icons.description_outlined, [
              _buildInfoRow(
                'Experience',
                widget.applicant['yearsOfExperience'] ?? 'N/A',
                Icons.work_outline,
              ),
              _buildInfoRow(
                'Applied On',
                _formatDate(DateTime.parse(widget.applicant['appliedAt'])),
                Icons.calendar_today_outlined,
              ),
            ]),

            const SizedBox(height: 20),

            // Skills
            if (widget.applicant['applicantSkills'] != null &&
                (widget.applicant['applicantSkills'] as List).isNotEmpty)
              _buildSection('Skills', Icons.psychology_outlined, [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (widget.applicant['applicantSkills'] as List)
                          .map(
                            (skill) => Chip(
                              label: Text(
                                skill,
                                style: TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: AppColors.primaryAccent
                                  .withValues(alpha: 0.1),
                            ),
                          )
                          .toList(),
                ),
              ]),

            const SizedBox(height: 20),

            // Why Join
            if (widget.applicant['whyJoin'] != null &&
                widget.applicant['whyJoin'].isNotEmpty)
              _buildSection('Why They Want to Join', Icons.lightbulb_outline, [
                Text(
                  widget.applicant['whyJoin'],
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ]),

            const SizedBox(height: 20),

            // Resume Preview
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_resumePreviewUrl != null)
              _buildSection('Resume', Icons.description_outlined, [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    print('Opening resume preview dialog');
                    print('Preview URL: $_resumePreviewUrl');
                    showDialog(
                      context: context,
                      builder:
                          (context) => Dialog(
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.network(
                                _resumePreviewUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading preview: $error');
                                  print('Stack trace: $stackTrace');
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppColors.primaryAccent,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load resume preview',
                                          style: TextStyle(
                                            color: AppColors.primaryAccent,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _resumePreviewUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: AppColors.primaryAccent,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading preview: $error');
                          print('Stack trace: $stackTrace');
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.primaryAccent,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load resume preview',
                                  style: TextStyle(
                                    color: AppColors.primaryAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ])
            else if (widget.applicant['resumeUrl'] != null)
              _buildSection('Resume', Icons.description_outlined, [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.primaryAccent.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Resume preview not available',
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

            const SizedBox(height: 20),

            // Status Action Buttons
            if (widget.applicant['status']?.toLowerCase() != 'accepted' &&
                widget.applicant['status']?.toLowerCase() != 'rejected')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('accepted'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: AppColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('rejected'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: AppColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Contact Buttons
            Row(
              children: [
                if (widget.applicant['applicantPhone'] != null &&
                    widget.applicant['applicantPhone'].isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _makePhoneCall(
                            widget.applicant['applicantPhone'],
                          ),
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (widget.applicant['applicantPhone'] != null &&
                    widget.applicant['applicantPhone'].isNotEmpty)
                  const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _messageApplicant(),
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: AppColors.textOnAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (widget.applicant['applicantEmail'] != null &&
                    widget.applicant['applicantEmail'].isNotEmpty)
                  const SizedBox(width: 8),
                if (widget.applicant['applicantEmail'] != null &&
                    widget.applicant['applicantEmail'].isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _sendEmail(widget.applicant['applicantEmail']),
                      icon: const Icon(Icons.email),
                      label: const Text('Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.1),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryAccent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
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
      default:
        return Colors.orange;
    }
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
