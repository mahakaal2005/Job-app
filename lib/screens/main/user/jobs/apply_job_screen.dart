import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/user/jobs/apply_success_screen.dart';
import 'package:get_work_app/utils/app_colors.dart';

class ApplyJobScreen extends StatefulWidget {
  final Job job;

  const ApplyJobScreen({super.key, required this.job});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  String? _uploadedFileName;
  String? _uploadedFileSize;
  String? _uploadedFileDate;
  final TextEditingController _informationController = TextEditingController();

  @override
  void dispose() {
    _informationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'documents',
        extensions: ['pdf', 'doc', 'docx'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        final int fileSize = await file.length();
        setState(() {
          _uploadedFileName = file.name;
          _uploadedFileSize = '${(fileSize / 1024).toStringAsFixed(0)} Kb';
          _uploadedFileDate =
              '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  void _removeFile() {
    setState(() {
      _uploadedFileName = null;
      _uploadedFileSize = null;
      _uploadedFileDate = null;
    });
  }

  void _applyNow() {
    if (_uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your CV/Resume first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to success screen with job and file details
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ApplySuccessScreen(
          job: widget.job,
          uploadedFileName: _uploadedFileName!,
          uploadedFileSize: _uploadedFileSize!,
          uploadedFileDate: _uploadedFileDate!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            _buildHeader(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Title and description
                    const Text(
                      'Upload CV',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.302,
                        color: Color(0xFF150B3D),
                      ),
                    ),
                    const SizedBox(height: 11),
                    const Text(
                      'Add your CV/Resume to apply for a job',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: Color(0xFF524B6B),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Upload area or uploaded file
                    _uploadedFileName == null
                        ? _buildUploadArea()
                        : _buildUploadedFile(),

                    const SizedBox(height: 30),

                    // Information section
                    _buildInformationSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Apply Now button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            child: Container(
              height: 114,
              color: const Color(0xFFF2F2F2),
            ),
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
                child: widget.job.companyLogo.isNotEmpty
                    ? Image.network(
                        widget.job.companyLogo,
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
                widget.job.title,
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
                widget.job.companyName,
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
                widget.job.location,
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
              onTap: () => Navigator.pop(context),
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

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFF9D97B5),
          strokeWidth: 0.5,
          dashWidth: 3,
          dashSpace: 3,
          borderRadius: 15,
        ),
        child: Container(
          width: 335,
          height: 75,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              // Icon positioned at x:94, y:26
              Positioned(
                left: 94,
                top: 26,
                child: Image.asset(
                  'assets/images/upload_cv_icon.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.upload_file_outlined,
                      color: Color(0xFF524B6B),
                      size: 24,
                    );
                  },
                ),
              ),
              // Text positioned at x:133, y:30
              Positioned(
                left: 133,
                top: 30,
                child: const SizedBox(
                  width: 108,
                  height: 16,
                  child: Text(
                    'Upload CV/Resume',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.302,
                      color: Color(0xFF150B3D),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedFile() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: const Color(0xFF9D97B5),
        strokeWidth: 0.5,
        dashWidth: 3,
        dashSpace: 3,
        borderRadius: 20,
      ),
      child: Container(
        width: 335,
        height: 118,
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
                  _uploadedFileName ?? '',
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
                  _uploadedFileSize ?? '',
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
                  _uploadedFileDate ?? '',
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

            // Remove icon and text - positioned at x:21, y:79
            Positioned(
              left: 21,
              top: 79,
              child: GestureDetector(
                onTap: _removeFile,
                child: SizedBox(
                  width: 100,
                  height: 24,
                  child: Row(
                    children: [
                      // Remove icon
                      Image.asset(
                        'assets/images/remove_file_icon.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.close,
                            size: 24,
                            color: Color(0xFFFC4646),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      // Remove text - positioned at x:34 (relative to parent), y:4
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Remove file',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.3618,
                            color: Color(0xFFFC4646),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationSection() {
    return SizedBox(
      width: 335,
      height: 266,
      child: Stack(
        children: [
          // "Information" title - positioned at x:0, y:0
          const Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 79,
              height: 18,
              child: Text(
                'Information',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.302,
                  color: Color(0xFF150B3D),
                ),
              ),
            ),
          ),

          // White container with text field - positioned at x:0, y:34
          Positioned(
            left: 0,
            top: 34,
            child: Container(
              width: 335,
              height: 232,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF99ABC6).withOpacity(0.18),
                    blurRadius: 62,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // TextField positioned at x:20, y:20 (relative to container, which is at y:54 from parent)
                  Positioned(
                    left: 20,
                    top: 20,
                    right: 20,
                    bottom: 20,
                    child: TextField(
                      controller: _informationController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText:
                            'Explain why you are the right person for this job',
                        hintStyle: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.302,
                          color: Color(0xFFAAA6B9),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: Color(0xFF150B3D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 26),
      child: GestureDetector(
        onTap: _applyNow,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 317,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.lookGigPurple,
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
            'APPLY NOW',
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
    );
  }
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(borderRadius),
          ),
        );

    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double length = draw ? dashWidth : dashSpace;
        if (distance + length > metric.length) {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, metric.length),
              Offset.zero,
            );
          }
          break;
        } else {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, distance + length),
              Offset.zero,
            );
          }
          distance += length;
          draw = !draw;
        }
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


