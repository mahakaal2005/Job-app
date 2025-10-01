import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class EmpHelpSupportScreen extends StatelessWidget {
  const EmpHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How can we help you?',
                      style: TextStyle(
                        color: AppColors.textOnAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our support team is here to assist you with any questions or concerns.',
                      style: TextStyle(
                        color: AppColors.textOnAccent,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSection(
                title: 'Contact Information',
                children: [
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'support@getwork.com',
                    onTap: () {
                      // Handle email tap
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone Support',
                    subtitle: '+1 (555) 123-4567',
                    onTap: () {
                      // Handle phone tap
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSection(
                title: 'Frequently Asked Questions',
                children: [
                  _buildFAQItem(
                    question: 'How do I post a new job?',
                    answer:
                        'To post a new job, go to the dashboard and click on the "Create Job" card. Fill in the required details and submit the form.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    question: 'How do I manage applications?',
                    answer:
                        'You can view and manage all applications from the "All Applicants" section in your dashboard.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    question: 'How do I update my company profile?',
                    answer:
                        'Go to your profile section and click on the edit button to update your company information.',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Support Hours Section
              _buildSection(
                title: 'Support Hours',
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSupportHourRow(
                          day: 'Monday - Friday',
                          hours: '9:00 AM - 6:00 PM',
                        ),
                        const Divider(height: 24),
                        _buildSupportHourRow(
                          day: 'Saturday',
                          hours: '10:00 AM - 4:00 PM',
                        ),
                        const Divider(height: 24),
                        _buildSupportHourRow(
                          day: 'Sunday',
                          hours: 'Closed',
                          isClosed: true,
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
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
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

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportHourRow({
    required String day,
    required String hours,
    bool isClosed = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          hours,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isClosed ? AppColors.primaryAccent : AppColors.primaryAccent,
          ),
        ),
      ],
    );
  }
}
