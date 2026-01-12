import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final appliedAt = DateTime.parse(application['appliedAt']);
    final status = application['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.gigAppLightGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    _buildStatusCard(status, appliedAt),

                    const SizedBox(height: 20),

                    // Job Information
                    _buildSection('Job Information', Icons.work_outline, [
                      _buildInfoRow(
                        'Position',
                        application['jobTitle'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Company',
                        application['companyName'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Applied On',
                        DateFormat('MMMM dd, yyyy').format(appliedAt),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Application Details
                    if (application['cvFileName'] != null)
                      _buildSection(
                        'Submitted Documents',
                        Icons.description_outlined,
                        [
                          _buildDocumentRow(
                            application['cvFileName'],
                            application['cvFileSize'] ?? 'Unknown size',
                            application['resumeUrl'],
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Additional Information
                    if (application['additionalInfo'] != null &&
                        application['additionalInfo'].toString().isNotEmpty)
                      _buildSection(
                        'Additional Information',
                        Icons.info_outline,
                        [
                          Text(
                            application['additionalInfo'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF524B6B),
                              fontFamily: 'DM Sans',
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF150B3D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Application Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, DateTime appliedAt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 48,
              color: _getStatusColor(status),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getStatusTitle(status),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _getStatusColor(status),
              fontFamily: 'DM Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusMessage(status),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF524B6B),
              fontFamily: 'DM Sans',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
                  color: const Color(0xFF2F51A7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2F51A7), size: 20),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D0140),
                fontFamily: 'DM Sans',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF524B6B),
                fontFamily: 'DM Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(
    String fileName,
    String fileSize,
    String? resumeUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F51A7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2F51A7).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F51A7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description,
                  color: Color(0xFF2F51A7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
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
                      fileSize,
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
          if (resumeUrl != null && resumeUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final uri = Uri.parse(resumeUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } catch (e) {
                    print('Error opening resume: $e');
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text(
                  'VIEW RESUME',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DM Sans',
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F51A7),
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'shortlisted':
        return const Color(0xFF2F51A7);
      default:
        return const Color(0xFF2F51A7);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'shortlisted':
        return Icons.star;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Application Accepted';
      case 'rejected':
        return 'Application Rejected';
      case 'shortlisted':
        return 'Application Shortlisted';
      default:
        return 'Application Pending';
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Congratulations! Your application has been accepted.';
      case 'rejected':
        return 'Unfortunately, your application was not selected.';
      case 'shortlisted':
        return 'Great! You\'ve been shortlisted for this position.';
      default:
        return 'Your application is under review.';
    }
  }
}
