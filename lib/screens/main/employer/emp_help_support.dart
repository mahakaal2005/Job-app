import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class EmpHelpSupportScreen extends StatelessWidget {
  const EmpHelpSupportScreen({super.key});

  // Support contact information
  static const String supportEmail = 'support@lookgig.com';
  static const String supportPhone = '+1-555-123-4567';

  // Launch email app with pre-filled support email
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Support Request - Gig Work App',
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          message: 'Could not open email app',
          isSuccess: false,
        );
      }
    }
  }

  // Launch phone app with support number
  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);

    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          message: 'Could not open phone app',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: Column(
        children: [_buildHeader(context), Expanded(child: _buildBody(context))],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                          'Help & Support',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'We\'re here to help',
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

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Contact Information Section
          _buildSection(
            title: 'Contact Information',
            children: [
              _buildContactCard(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: supportEmail,
                onTap: () => _launchEmail(context),
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                context: context,
                icon: Icons.phone_outlined,
                title: 'Phone Support',
                subtitle: supportPhone,
                onTap: () => _launchPhone(context),
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
          const SizedBox(height: 40),
        ],
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
            color: AppColors.lookGigProfileText,
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9228).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF9228), size: 24),
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
                      color: AppColors.lookGigProfileText,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lookGigDescriptionText,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.lookGigDescriptionText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
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
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
          ),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9228).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Color(0xFFFF9228),
              size: 20,
            ),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.lookGigProfileText,
              fontFamily: 'DM Sans',
            ),
          ),
          iconColor: const Color(0xFFFF9228),
          collapsedIconColor: AppColors.lookGigDescriptionText,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lookGigDescriptionText,
                  height: 1.5,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
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
            color: AppColors.lookGigProfileText,
            fontFamily: 'DM Sans',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isClosed
                    ? AppColors.error.withOpacity(0.1)
                    : const Color(0xFFFF9228).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isClosed ? AppColors.error : const Color(0xFFFF9228),
              fontFamily: 'DM Sans',
            ),
          ),
        ),
      ],
    );
  }
}
