import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/utils/app_colors.dart';

class ApplySuccessScreen extends StatelessWidget {
  final Job job;
  final String uploadedFileName;
  final String uploadedFileSize;
  final String uploadedFileDate;

  const ApplySuccessScreen({
    super.key,
    required this.job,
    required this.uploadedFileName,
    required this.uploadedFileSize,
    required this.uploadedFileDate,
  });

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(job.createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header with job info
            _buildHeader(context),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Uploaded file card
                    _buildUploadedFileCard(),

                    const SizedBox(height: 64),

                    // Success illustration
                    Image.asset(
                      'assets/images/success_illustration.png',
                      width: 152,
                      height: 152,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.check_circle,
                          size: 152,
                          color: Colors.green,
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Success title
                    const Text(
                      'Successful',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.302,
                        color: Color(0xFF3A3452),
                        shadows: [
                          Shadow(
                            color: Color(0x2E99ABC6),
                            blurRadius: 62,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Success message
                    const Text(
                      'Congratulations, your application has been sent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: Color(0xFF524B6B),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: SizedBox(
          width: screenWidth.clamp(0, 375),
          height: 215,
          child: Stack(
            children: [
              // Gray background - positioned at y:101 (38 + 63) with height 114
              Positioned(
                left: 0,
                right: 0,
                top: 101,
                child: Container(height: 114, color: const Color(0xFFF2F2F2)),
              ),

              // Company logo - centered horizontally
              Positioned(
                left: 0,
                right: 0,
                top: 38,
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAFECFE),
                      borderRadius: BorderRadius.circular(42),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(42),
                      child:
                          job.companyLogo.isNotEmpty
                              ? Image.network(
                                job.companyLogo,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/job_detail_company_logo.png',
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                              : Image.asset(
                                'assets/images/job_detail_company_logo.png',
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                ),
              ),

              // Job title - centered
              Positioned(
                left: 0,
                right: 0,
                top: 136,
                child: Center(
                  child: Text(
                    job.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.302,
                      color: Color(0xFF0D0140),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Company name, location, and time - full width with smart spacing
              Positioned(
                left: 0,
                right: 0,
                top: 173,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Company Name
                    Flexible(
                      child: Text(
                        job.companyName,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          height: 1.302,
                          color: Color(0xFF0D0140),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // First bullet point
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D0140),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Location
                    Flexible(
                      child: Text(
                        job.location,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          height: 1.302,
                          color: Color(0xFF0D0140),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Second bullet point
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D0140),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Time
                    Flexible(
                      child: Text(
                        _getTimeAgo(),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          height: 1.302,
                          color: Color(0xFF0D0140),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Options menu - positioned at right
              Positioned(
                right: 22,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    // Options menu
                  },
                  child: Image.asset(
                    'assets/images/job_detail_options_icon.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.more_vert,
                        size: 24,
                        color: Color(0xFF0D0140),
                      );
                    },
                  ),
                ),
              ),

              // Back button - positioned at left
              Positioned(
                left: 22,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    'assets/images/job_detail_back_icon.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Color(0xFF0D0140),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedFileCard() {
    return Center(
      child: Container(
        width: 335,
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFF3F13E4).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // PDF icon - positioned at x:15, y:15
            Positioned(
              left: 15,
              top: 15,
              child: Image.asset(
                'assets/images/pdf_icon.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF464B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Filename - positioned at x:74, y:19
            Positioned(
              left: 74,
              top: 19,
              child: SizedBox(
                width: 192,
                height: 16,
                child: Text(
                  uploadedFileName,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.3618,
                    color: Color(0xFF150B3D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // File size - positioned at x:74, y:40
            Positioned(
              left: 74,
              top: 40,
              child: SizedBox(
                width: 39,
                height: 16,
                child: Text(
                  uploadedFileSize,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.302,
                    color: Color(0xFFAAA6B9),
                  ),
                ),
              ),
            ),

            // Bullet point - positioned at x:118, y:49
            Positioned(
              left: 118,
              top: 49,
              child: Container(
                width: 2,
                height: 2,
                decoration: const BoxDecoration(
                  color: Color(0xFFAAA6B9),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Date - positioned at x:125, y:40
            Positioned(
              left: 125,
              top: 40,
              child: SizedBox(
                width: 130,
                height: 16,
                child: Text(
                  uploadedFileDate,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.302,
                    color: Color(0xFFAAA6B9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth * 0.7).clamp(259.0, 335.0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Find a similar job button
          Center(
            child: GestureDetector(
              onTap: () {
                // Navigate back to home and show similar jobs
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Container(
                width: buttonWidth,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CDFE),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF99ABC6).withOpacity(0.18),
                      blurRadius: 62,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'FIND A SIMILAR JOB',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.302,
                    letterSpacing: 0.84,
                    color: Color(0xFF130160),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Back to home button
          Center(
            child: GestureDetector(
              onTap: () {
                // Navigate back to home
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Container(
                width: buttonWidth,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.lookGigPurple,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFACC8D3).withOpacity(0.15),
                      blurRadius: 159,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.302,
                    letterSpacing: 0.84,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
