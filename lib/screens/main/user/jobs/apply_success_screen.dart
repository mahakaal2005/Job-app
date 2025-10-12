import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
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
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: 375,
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

            // Company logo - positioned at x:145, y:38 (job info group starts at y:38)
            Positioned(
              left: 145,
              top: 38,
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

            // Job title - positioned at x:130, y:136 (38 + 98)
            Positioned(
              left: 130,
              top: 136,
              child: SizedBox(
                width: 116,
                height: 21,
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

            // Company name - positioned at x:29, y:173 (38 + 135)
            Positioned(
              left: 29,
              top: 173,
              child: SizedBox(
                width: 53,
                height: 21,
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
                ),
              ),
            ),

            // First bullet point - positioned at x:104, y:182 (38 + 144)
            Positioned(
              left: 104,
              top: 182,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0140),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Location - positioned at x:143, y:173 (38 + 135)
            Positioned(
              left: 143,
              top: 173,
              child: SizedBox(
                width: 70,
                height: 21,
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
                ),
              ),
            ),

            // Second bullet point - positioned at x:245, y:182 (38 + 144)
            Positioned(
              left: 245,
              top: 182,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0140),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Time ago - positioned at x:276, y:173 (38 + 135)
            Positioned(
              left: 276,
              top: 173,
              child: const SizedBox(
                width: 68,
                height: 21,
                child: Text(
                  '1 day ago',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.302,
                    color: Color(0xFF0D0140),
                  ),
                ),
              ),
            ),

            // Options menu - positioned at x:331, y:0
            Positioned(
              left: 331,
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

            // Back button - positioned at x:22, y:0
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
    );
  }

  Widget _buildUploadedFileCard() {
    return Container(
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
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Find a similar job button
          GestureDetector(
            onTap: () {
              // Navigate back to home and show similar jobs
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              width: 259,
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

          const SizedBox(height: 20),

          // Back to home button
          GestureDetector(
            onTap: () {
              // Navigate back to home
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              width: 259,
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
        ],
      ),
    );
  }
}



