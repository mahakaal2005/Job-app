import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/image_utils.dart';
import 'package:get_work_app/screens/main/user/jobs/apply_job_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/user/applications/application_detail_screen.dart';
import 'package:get_work_app/services/profile_gating_service.dart';
import 'package:get_work_app/widgets/job_location_map.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _hasApplied = false;
  bool _isCheckingApplication = true;
  
  // Read more functionality
  bool _isDescriptionExpanded = false;
  bool _isTextTruncated = false;
  
  Map<String, dynamic>? _applicationData;
  String? _companyHeadOffice;
  String? _companySize;
  String? _companyIndustry;
  String? _establishedYear;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    _checkIfApplied();
    _fetchCompanyDetails();
  }

  Future<void> _checkIfApplied() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isCheckingApplication = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users_specific')
          .doc(currentUser.uid)
          .collection('applications')
          .doc(widget.job.id)
          .get();

      if (mounted) {
        setState(() {
          _hasApplied = doc.exists;
          _applicationData = doc.data();
          _isCheckingApplication = false;
        });
      }
    } catch (e) {
      print('Error checking application: $e');
      if (mounted) {
        setState(() => _isCheckingApplication = false);
      }
    }
  }

  Future<void> _toggleBookmark() async {
    // Check profile completion before allowing bookmark
    final canBookmark = await ProfileGatingService.canPerformAction(
      context,
      actionName: 'bookmark this job',
    );
    
    if (canBookmark) {
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      widget.onBookmarkToggled(widget.job.id);
    }
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

  Future<void> _fetchCompanyDetails() async {
    try {
      // Fetch company information from employer's profile
      final employerDoc = await FirebaseFirestore.instance
          .collection('employers')
          .doc(widget.job.employerId)
          .get();

      if (employerDoc.exists && mounted) {
        final employerData = employerDoc.data();
        final companyInfo = employerData?['companyInfo'] as Map<String, dynamic>?;
        
        // Try to get company address from different possible locations
        String? headOffice = companyInfo?['companyAddress'] ?? 
                            employerData?['companyAddress'] ?? 
                            companyInfo?['address'] ??
                            employerData?['address'];

        // Get company size
        String? companySize = companyInfo?['companySize'] ?? 
                             employerData?['companySize'];

        // Get company industry
        String? industry = companyInfo?['industry'] ?? 
                          employerData?['industry'];

        // Get established year
        String? establishedYear = companyInfo?['establishedYear'] ?? 
                                 employerData?['establishedYear'];

        setState(() {
          _companyHeadOffice = headOffice;
          _companySize = companySize;
          _companyIndustry = industry;
          _establishedYear = establishedYear;
        });
      }
    } catch (e) {
      print('Error fetching company details: $e');
      // Don't set state on error, keep company details as null
    }
  }

  String _getCompanySize() {
    if (_companySize != null && _companySize!.isNotEmpty) {
      // Convert "1-10 EMPLOYERs" to "1-10 employees"
      return _companySize!.replaceAll('EMPLOYERs', 'employees').replaceAll('EMPLOYER', 'employee');
    }
    return 'Not specified';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gigAppLightGray,
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

  Future<void> _launchURL(String url) async {
    try {
      // Ensure URL has proper protocol
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }
      
      final Uri uri = Uri.parse(formattedUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Show error message if URL can't be launched
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open website'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message if there's an exception
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening website'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _checkIfTextOverflows(String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 5,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }

  void _toggleDescriptionExpansion() {
    setState(() {
      _isDescriptionExpanded = !_isDescriptionExpanded;
    });
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
                      ? ImageUtils.buildSafeNetworkImage(
                          imageUrl: widget.job.companyLogo,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorWidget: Image.asset(
                            'assets/images/job_detail_company_logo.png',
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
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

            // Company name, location, and time - full width with smart spacing
            Positioned(
              left: 0,
              right: 0,
              top: 173,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Company Name
                  Flexible(
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
                      widget.job.location.isNotEmpty ? widget.job.location : 'Remote',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 38 - 11) / 2; // (screen width - horizontal padding - gap) / 2
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // 5% padding
      child: Row(
        children: [
          // Description tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionTab = true;
                  // Reset description expansion when switching to description tab
                  _isDescriptionExpanded = false;
                });
              },
              child: AnimatedScale(
                scale: _isDescriptionTab ? 1.02 : 0.98,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // Selected: Dark purple, Unselected: Light purple
                    color: _isDescriptionTab 
                        ? AppColors.gigAppPurple      // Active: Dark purple #130160
                        : const Color(0xFFD6CDFE),     // Inactive: Light purple
                    borderRadius: BorderRadius.circular(6),
                    // Enhanced shadow when active for depth
                    boxShadow: _isDescriptionTab
                        ? [
                            BoxShadow(
                              color: AppColors.gigAppPurple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: _isDescriptionTab ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      height: 1.302,
                      // White text when active, dark purple when inactive
                      color: _isDescriptionTab ? Colors.white : AppColors.gigAppPurple,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: screenWidth * 0.03), // 3% gap
          
          // Company tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionTab = false;
                });
              },
              child: AnimatedScale(
                scale: !_isDescriptionTab ? 1.02 : 0.98,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // Selected: Dark purple, Unselected: Light purple
                    color: !_isDescriptionTab 
                        ? AppColors.gigAppPurple      // Active: Dark purple #130160
                        : const Color(0xFFD6CDFE),     // Inactive: Light purple
                    borderRadius: BorderRadius.circular(6),
                    // Enhanced shadow when active for depth
                    boxShadow: !_isDescriptionTab
                        ? [
                            BoxShadow(
                              color: AppColors.gigAppPurple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Company',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: !_isDescriptionTab ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      height: 1.302,
                      // White text when active, dark purple when inactive
                      color: !_isDescriptionTab ? Colors.white : AppColors.gigAppPurple,
                    ),
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
    const textStyle = TextStyle(
      fontFamily: 'Open Sans',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.3618,
      color: Color(0xFF524B6B),
    );

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
        LayoutBuilder(
          builder: (context, constraints) {
            // Check if text overflows - do this synchronously to avoid setState during build
            final isOverflowing = _checkIfTextOverflows(
              widget.job.description,
              textStyle,
              constraints.maxWidth,
            );
            
            // Update truncation state if needed (only on first build)
            if (_isTextTruncated != isOverflowing && !_isDescriptionExpanded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isTextTruncated = isOverflowing;
                  });
                }
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.description,
                  maxLines: _isDescriptionExpanded ? null : 5,
                  overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: textStyle,
                ),
                if (_isTextTruncated || _isDescriptionExpanded) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _toggleDescriptionExpansion,
                    child: Container(
                      width: _isDescriptionExpanded ? 85 : 91,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7551FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isDescriptionExpanded ? 'Read less' : 'Read more',
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.3618,
                          color: Color(0xFF0D0140),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
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
    final locationText = widget.job.location.isNotEmpty ? widget.job.location : 'Remote';
    
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
          locationText,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF524B6B),
          ),
        ),
        const SizedBox(height: 17),
        // Interactive map
        JobLocationMap(
          locationText: locationText,
          height: 151,
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
        _buildDetailItem('Industry', _companyIndustry ?? 'Not specified'),
        const SizedBox(height: 20),
        
        // Company size
        _buildDetailItem('Company size', _getCompanySize()),
        const SizedBox(height: 20),
        
        // Head office
        _buildDetailItem('Head office', _companyHeadOffice ?? 'Not specified'),
        const SizedBox(height: 20),
        
        // Type
        _buildDetailItem('Type', 'Multinational company'),
        const SizedBox(height: 20),
        
        // Since
        _buildDetailItem('Since', _establishedYear ?? 'Not specified'),
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
        isLink
            ? GestureDetector(
                onTap: () => _launchURL(value),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.3618,
                    color: Color(0xFF7551FF),
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.3618,
                  color: Color(0xFF524B6B),
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
    if (_isCheckingApplication) {
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
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9228)),
        ),
      );
    }

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
                            color: const Color(0xFF2F51A7),
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
            
            // Apply Now or View Application button
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => setState(() {}),
                onTapUp: (_) => setState(() {}),
                onTapCancel: () => setState(() {}),
                onTap: () async {
                  if (_hasApplied && _applicationData != null) {
                    // Navigate to Application Detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplicationDetailScreen(
                          application: _applicationData!,
                        ),
                      ),
                    );
                  } else {
                    // Check profile completion before allowing application
                    final canApply = await ProfileGatingService.canPerformAction(
                      context,
                      actionName: 'apply for this job',
                    );
                    
                    if (canApply && mounted) {
                      // Navigate to Apply Job screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplyJobScreen(job: widget.job),
                        ),
                      ).then((_) {
                        // Refresh application status after returning
                        _checkIfApplied();
                      });
                    }
                  }
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
                          color: _hasApplied 
                              ? const Color(0xFF2F51A7) 
                              : AppColors.gigAppPurple,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_hasApplied)
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            if (_hasApplied) const SizedBox(width: 8),
                            Text(
                              _hasApplied ? 'VIEW APPLICATION' : 'APPLY NOW',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.302,
                                letterSpacing: 0.84,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 15),
            
            // Spacer to balance the save button on the left
            const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }
}
