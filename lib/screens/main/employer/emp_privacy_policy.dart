import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class EmpPrivacyPolicyScreen extends StatelessWidget {
  const EmpPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSection(
                    title: 'Information We Collect',
                    content:
                        'We collect information you provide directly to us, including your name, email address, company information, and any other information you choose to provide when using our services.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'How We Use Your Information',
                    content:
                        'We use the information we collect to provide, maintain, and improve our services, to communicate with you, to monitor and analyze trends, and to personalize your experience.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Information Sharing',
                    content:
                        'We do not share your personal information with third parties except as described in this policy. We may share information with service providers who perform services on our behalf.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Data Security',
                    content:
                        'We take reasonable measures to help protect your personal information from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Your Rights',
                    content:
                        'You have the right to access, update, or delete your personal information at any time. You can do this through your account settings or by contacting us directly.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Cookies and Tracking',
                    content:
                        'We use cookies and similar tracking technologies to collect information about your browsing activities and to personalize your experience on our platform.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Children\'s Privacy',
                    content:
                        'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Changes to This Policy',
                    content:
                        'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Contact Us',
                    content:
                        'If you have any questions about this Privacy Policy, please contact us at support@getwork.com or call us at +1 (555) 123-4567.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9228).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF9228).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF9228),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9228),
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                          'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your privacy matters to us',
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

  Widget _buildSection({required String title, required String content}) {
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
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9228).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFFFF9228),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lookGigDescriptionText,
                  height: 1.6,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
