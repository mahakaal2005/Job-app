import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/new post/job_new_model.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/screens/main/user/jobs/apply_job_screen.dart';

class JobDetailScreenNew extends StatefulWidget {
  final Job job;
  final bool isBookmarked;
  final Function(String) onBookmarkToggled;

  const JobDetailScreenNew({
    super.key,
    required this.job,
    required this.isBookmarked,
    required this.onBookmarkToggled,
  });

  @override
  State<JobDetailScreenNew> createState() => _JobDetailScreenNewState();
}

class _JobDetailScreenNewState extends State<JobDetailScreenNew> {
  bool _isDescriptionTab = false; // false = Company tab, true = Description tab
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    widget.onBookmarkToggled(widget.job.id);
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(widget.job.createdAt);
    
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
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                children: [
                  // Header section with company logo and job info
                  _buildHeader(),
                  
                  // Tab buttons (Description / Company)
                  _buildTabButtons(),
                  
                  // Content based on selected tab
                  if (_isDescriptionTab)
                    _buildDescriptionContent()
                  else
                    _buildCompanyContent(),
                  
                  // Bottom spacing
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Fixed bottom bar - always at the bottom
          _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
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
              child: SizedBox(
                width: 68,
                height: 21,
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

  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Row(
        children: [
          // Description tab
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionTab = true;
              });
            },
            child: AnimatedScale(
              scale: _isDescriptionTab ? 1.0 : 0.98,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 162,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lookGigPurple, // Always dark purple #130160
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _isDescriptionTab
                      ? [
                          BoxShadow(
                            color: const Color(0xFF99ABC6).withOpacity(0.18),
                            blurRadius: 62,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null, // Elevated when active
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.302,
                    color: Colors.white, // Always white text
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 11),
          
          // Company tab
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionTab = false;
              });
            },
            child: AnimatedScale(
              scale: !_isDescriptionTab ? 1.0 : 0.98,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 162,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CDFE), // Always light purple
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: !_isDescriptionTab
                      ? [
                          BoxShadow(
                            color: const Color(0xFF99ABC6).withOpacity(0.18),
                            blurRadius: 62,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null, // Elevated when active
                ),
                alignment: Alignment.center,
                child: Text(
                  'Company',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.302,
                    color: AppColors.lookGigPurple, // Always dark purple text
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Job Description Section
          _buildJobDescriptionSection(),
          
          const SizedBox(height: 25),
          
          // Requirements Section
          _buildRequirementsSection(),
          
          const SizedBox(height: 25),
          
          // Location Section
          _buildLocationSection(),
          
          const SizedBox(height: 25),
          
          // Informations Section
          _buildInformationsSection(),
          
          const SizedBox(height: 30),
          
          // Facilities and Others Section (at the bottom)
          _buildFacilitiesSection(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildJobDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Description',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          widget.job.description,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.3618,
            color: Color(0xFF524B6B),
          ),
        ),
        const SizedBox(height: 10),
        // Read more button
        Container(
          width: 91,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF7551FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Read more',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.3618,
              color: Color(0xFF0D0140),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsSection() {
    if (widget.job.requirements.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.3618,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 15),
        ...widget.job.requirements.map((requirement) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 6, right: 11),
                decoration: const BoxDecoration(
                  color: Color(0xFF524B6B),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  requirement,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.3618,
                    color: Color(0xFF524B6B),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFacilitiesSection() {
    if (widget.job.benefits.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Facilities and Others',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 15),
        ...widget.job.benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 11),
                decoration: const BoxDecoration(
                  color: Color(0xFF524B6B),
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                benefit,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.302,
                  color: Color(0xFF524B6B),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          widget.job.location,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF524B6B),
          ),
        ),
        const SizedBox(height: 17),
        // Map placeholder
        Container(
          width: double.infinity,
          height: 151,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.location_on,
              size: 48,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInformationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 15),
        _buildInfoItem('Position', widget.job.title),
        _buildDivider(),
        _buildInfoItem('Qualification', 'Bachelor\'s Degree'),
        _buildDivider(),
        _buildInfoItem('Experience', widget.job.experienceLevel),
        _buildDivider(),
        _buildInfoItem('Job Type', widget.job.employmentType),
        _buildDivider(),
        _buildInfoItem('Specialization', widget.job.requiredSkills.isNotEmpty 
            ? widget.job.requiredSkills.first 
            : 'Design'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.302,
              color: Color(0xFF150B3D),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.302,
              color: Color(0xFF524B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: const Color(0xFFDEE1E7),
    );
  }

  Widget _buildCompanyContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // About Company
          _buildAboutCompany(),
          
          const SizedBox(height: 20),
          
          // Company Details
          _buildCompanyDetails(),
          
          const SizedBox(height: 20),
          
          // Company Gallery
          _buildCompanyGallery(),
        ],
      ),
    );
  }

  Widget _buildAboutCompany() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About Company',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          widget.job.description,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF524B6B),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Website
        _buildDetailItem(
          'Website',
          'https://www.${widget.job.companyName.toLowerCase()}.com',
          isLink: true,
        ),
        const SizedBox(height: 20),
        
        // Industry
        _buildDetailItem('Industry', 'Internet product'),
        const SizedBox(height: 20),
        
        // Employee size
        _buildDetailItem('Employee size', '132,121 Employees'),
        const SizedBox(height: 20),
        
        // Head office
        _buildDetailItem('Head office', widget.job.location),
        const SizedBox(height: 20),
        
        // Type
        _buildDetailItem('Type', 'Multinational company'),
        const SizedBox(height: 20),
        
        // Since
        _buildDetailItem('Since', '1998'),
        const SizedBox(height: 20),
        
        // Specialization
        _buildDetailItem(
          'Specialization',
          widget.job.requiredSkills.isNotEmpty 
              ? widget.job.requiredSkills.join(', ')
              : 'Search technology, Web computing, Software and Online advertising',
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isLink = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.3618,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.3618,
            color: isLink ? const Color(0xFF7551FF) : const Color(0xFF524B6B),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Gallery',
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.3618,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            // Large image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/company_gallery_1.png',
                width: 223,
                height: 118,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 223,
                    height: 118,
                    color: Colors.grey[300],
                  );
                },
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Two small images stacked
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/company_gallery_2.png',
                    width: 102,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 102,
                        height: 54,
                        color: Colors.grey[300],
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/company_gallery_3.png',
                        width: 102,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 102,
                            height: 54,
                            color: Colors.grey[300],
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 102,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C3648).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+5 pictures',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.3618,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFACC8D3).withOpacity(0.2),
            blurRadius: 83,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Save button
            GestureDetector(
              onTapDown: (_) => setState(() {}),
              onTapUp: (_) => setState(() {}),
              onTapCancel: () => setState(() {}),
              onTap: _toggleBookmark,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.0),
                duration: const Duration(milliseconds: 100),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFACC8D3).withOpacity(0.4),
                            blurRadius: 72,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                            key: ValueKey(_isBookmarked),
                            color: const Color(0xFFFCA34D), // Orange color from Figma
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 15),
            
            // Apply Now button
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => setState(() {}),
                onTapUp: (_) => setState(() {}),
                onTapCancel: () => setState(() {}),
                onTap: () {
                  // Navigate to Apply Job screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplyJobScreen(job: widget.job),
                    ),
                  );
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 100),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
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
}
