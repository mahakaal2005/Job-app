import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> applicant;
  final String jobTitle;

  const ApplicantDetailsScreen({
    Key? key,
    required this.applicant,
    required this.jobTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Applicant Details',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
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
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
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
                        applicant['applicantProfileImg'] != null &&
                                applicant['applicantProfileImg'].isNotEmpty
                            ? NetworkImage(applicant['applicantProfileImg'])
                            : null,
                    child:
                        applicant['applicantProfileImg'] == null ||
                                applicant['applicantProfileImg'].isEmpty
                            ? Text(
                              applicant['applicantName'][0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    applicant['applicantName'] ?? 'Anonymous',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applied for $jobTitle',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        applicant['status'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      applicant['status']?.toUpperCase() ?? 'PENDING',
                      style: TextStyle(
                        color: _getStatusColor(applicant['status']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contact Information
            _buildSection('Contact Information', Icons.contact_mail_outlined, [
              _buildInfoRow(
                'Email',
                applicant['applicantEmail'] ?? 'N/A',
                Icons.email_outlined,
              ),
              _buildInfoRow(
                'Phone',
                applicant['applicantPhone'] ?? 'N/A',
                Icons.phone_outlined,
              ),
              _buildInfoRow(
                'Address',
                applicant['applicantAddress'] ?? 'N/A',
                Icons.location_on_outlined,
              ),
              _buildInfoRow(
                'Gender',
                applicant['applicantGender'] ?? 'N/A',
                Icons.person_outline,
              ),
            ]),

            const SizedBox(height: 20),

            // Application Details
            _buildSection('Application Details', Icons.description_outlined, [
              _buildInfoRow(
                'Experience',
                applicant['yearsOfExperience'] ?? 'N/A',
                Icons.work_outline,
              ),
              _buildInfoRow(
                'Applied On',
                _formatDate(DateTime.parse(applicant['appliedAt'])),
                Icons.calendar_today_outlined,
              ),
            ]),

            const SizedBox(height: 20),

            // Skills
            if (applicant['applicantSkills'] != null &&
                (applicant['applicantSkills'] as List).isNotEmpty)
              _buildSection('Skills', Icons.psychology_outlined, [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (applicant['applicantSkills'] as List)
                          .map(
                            (skill) => Chip(
                              label: Text(
                                skill,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: AppColors.primaryBlue
                                  .withOpacity(0.1),
                            ),
                          )
                          .toList(),
                ),
              ]),

            const SizedBox(height: 20),

            // Why Join
            if (applicant['whyJoin'] != null && applicant['whyJoin'].isNotEmpty)
              _buildSection('Why They Want to Join', Icons.lightbulb_outline, [
                Text(
                  applicant['whyJoin'],
                  style: TextStyle(color: AppColors.secondaryText, height: 1.5),
                ),
              ]),

            const SizedBox(height: 20),

            // Contact Buttons
            Row(
              children: [
                if (applicant['applicantPhone'] != null &&
                    applicant['applicantPhone'].isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _makePhoneCall(applicant['applicantPhone']),
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.whiteText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (applicant['applicantPhone'] != null &&
                    applicant['applicantPhone'].isNotEmpty)
                  const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _messageApplicant(),
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.whiteText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (applicant['applicantEmail'] != null &&
                    applicant['applicantEmail'].isNotEmpty)
                  const SizedBox(width: 8),
                if (applicant['applicantEmail'] != null &&
                    applicant['applicantEmail'].isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendEmail(applicant['applicantEmail']),
                      icon: const Icon(Icons.email),
                      label: const Text('Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.whiteText,
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
        'subject': 'Regarding your job application for $jobTitle',
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mutedText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.1),
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
                  color: AppColors.royalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.royalBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
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
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 16),
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
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
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
      default:
        return Colors.orange;
    }
  }

  void _messageApplicant() {
    // TODO: Implement messaging functionality
    print('Message button clicked');
  }
}
