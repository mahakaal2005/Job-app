import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/user/jobs/job_application_form.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/glass_card.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  final bool isBookmarked;
  final Function(String) onBookmarkToggled;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.isBookmarked,
    required this.onBookmarkToggled,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late bool _isBookmarked;
  String _companyDescription = '';
  bool _hasAlreadyApplied = false;
  bool _isCheckingApplication = true;
  double _scrollProgress = 0.0; // 0.0 = full header, 1.0 = compact app bar

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _fetchCompanyDescription();
    _checkIfAlreadyApplied();
  }

  void _onScroll() {
    // Transition happens between 0 and 150 pixels of scroll
    const double transitionStart = 0.0;
    const double transitionEnd = 150.0;
    
    final double offset = _scrollController.offset;
    final double progress = ((offset - transitionStart) / (transitionEnd - transitionStart)).clamp(0.0, 1.0);
    
    if (_scrollProgress != progress) {
      setState(() {
        _scrollProgress = progress;
      });
    }
  }

  Future<void> _fetchCompanyDescription() async {
    try {
      final companyDoc =
          await FirebaseFirestore.instance
              .collection('employees')
              .doc(widget.job.employerId)
              .get();

      if (companyDoc.exists) {
        final companyInfo =
            companyDoc.data()?['companyInfo'] as Map<String, dynamic>?;
        setState(() {
          _companyDescription =
              companyInfo?['companyDescription'] ??
              'No company description available.';
        });
      } else {
        setState(() {
          _companyDescription = 'No company description available.';
        });
      }
    } catch (e) {
      setState(() {
        _companyDescription = 'Failed to load company description.';
      });
    }
  }

  Future<void> _checkIfAlreadyApplied() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isCheckingApplication = false);
        return;
      }

      final applicationSnapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(widget.job.companyName)
              .collection('jobPostings')
              .doc(widget.job.id)
              .collection('applicants')
              .where('applicantId', isEqualTo: user.uid)
              .get();

      if (mounted) {
        setState(() {
          _hasAlreadyApplied = applicationSnapshot.docs.isNotEmpty;
          _isCheckingApplication = false;
        });
      }
    } catch (e) {
      // Error checking application status - handled silently
      if (mounted) {
        setState(() => _isCheckingApplication = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        // Synchronized gradient - same as user home screen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF5A5A5A), // Light gray (matches header bottom)
              const Color(0xFF505050), // Slightly darker gray
              const Color(0xFF454545), // Medium gray
              const Color(0xFF3A3A3A), // Darker gray
              const Color(0xFF303030), // Even darker gray
              const Color(0xFF252525), // Deep gray
              const Color(0xFF1A1A1A), // Very deep gray
              const Color(0xFF151515), // Dark gray-black
              const Color(0xFF101010), // Very dark gray
              const Color(0xFF0A0A0A), // Almost black gray
              const Color(0xFF050505), // Nearly black
              AppColors.background, // Pure black at bottom
            ],
            stops: const [
              0.0,
              0.08,
              0.16,
              0.24,
              0.32,
              0.4,
              0.5,
              0.6,
              0.7,
              0.8,
              0.9,
              1.0,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Scrollable content with top padding for fixed header
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Add padding at top for fixed header space
                  SizedBox(height: _getJobHeaderHeight() - 8),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
            // Fixed header that stays on top - like home screen
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFixedJobHeader(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: _buildApplyButton(),
      ),
    );
  }

  double _getJobHeaderHeight() {
    // FIXED height - never changes to keep content position stable
    const double fullHeaderHeight = 280.0;
    return MediaQuery.of(context).padding.top + fullHeaderHeight;
  }

  Widget _buildFixedJobHeader() {
    // Calculate actual header height (shrinks from 280 to 93)
    const double fullHeaderHeight = 280.0;
    const double compactHeaderHeight = 93.0;
    final double currentHeaderHeight = fullHeaderHeight - ((fullHeaderHeight - compactHeaderHeight) * _scrollProgress);
    
    // Border radius: 28px → 16px (maintain rounded look)
    final double borderRadius = 28.0 - (12.0 * _scrollProgress);
    
    // Margin: 4px → 2px (subtle change)
    final double horizontalMargin = 4.0 - (2.0 * _scrollProgress);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A1A1A),
            const Color(0xFF3A2525),
            const Color(0xFF4A3535),
            const Color(0xFF4A4A4A),
            const Color(0xFF5A5A5A),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: currentHeaderHeight,
            child: Stack(
              children: [
                // Full header content (fades out)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 1.0 - _scrollProgress,
                    child: IgnorePointer(
                      ignoring: _scrollProgress > 0.5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildProperBackButton(),
                                const Spacer(),
                                _buildProperHeaderActions(),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildJobHeaderContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Compact app bar (fades in)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _scrollProgress,
                    child: IgnorePointer(
                      ignoring: _scrollProgress < 0.5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(
                          children: [
                            _buildProperBackButton(),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  widget.job.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            _buildProperHeaderActions(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Old SliverAppBar method removed - now using fixed header like home screen

  // Old floating header removed - now using fixed header like home screen

  Widget _buildProperBackButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryAccent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.primaryAccent,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildProperHeaderActions() {
    return Row(
      children: [
        _buildProperActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          isSelected: _isBookmarked,
          onPressed: () {
            setState(() => _isBookmarked = !_isBookmarked);
            widget.onBookmarkToggled(widget.job.id);
          },
        ),
        const SizedBox(width: 12),
        _buildProperActionButton(
          icon: Icons.share_outlined,
          onPressed: () {
            // Add share functionality here
          },
        ),
      ],
    );
  }

  Widget _buildProperActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isSelected = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryAccent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon, 
          color: AppColors.primaryAccent, 
          size: 22
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildJobHeaderContent() {
    return Row(
      children: [
        _buildEnhancedCompanyLogo(),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.job.companyName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.job.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildJobInfoChip(
                    Icons.location_on_outlined,
                    widget.job.location,
                  ),
                  const SizedBox(width: 12),
                  _buildJobInfoChip(
                    Icons.access_time,
                    widget.job.employmentType,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCompanyLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textOnAccent,
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child:
          widget.job.companyLogo.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.network(
                  widget.job.companyLogo,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => _buildLogoFallback(),
                ),
              )
              : _buildLogoFallback(),
    );
  }

  Widget _buildLogoFallback() {
    return Center(
      child: Text(
        widget.job.companyName[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }

  // Removed unused _buildQuickInfo methods

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildSalaryCard(),
        const SizedBox(height: 20),
        _buildDescriptionCard(),
        const SizedBox(height: 20),
        _buildRequirementsCard(),
        const SizedBox(height: 20),
        _buildSkillsCard(),
        const SizedBox(height: 20),
        _buildCompanyInfoCard(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSalaryCard() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      elevation: 20, // Dramatic floating effect like home screen
      borderRadius: 24.0,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.attach_money,
              color: AppColors.primaryAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salary Range',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.job.salaryRange}/month',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildModernCard(
      title: "Job Description",
      icon: Icons.description_outlined,
      iconColor: AppColors.primaryAccent,
      child: Text(
        widget.job.description,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return _buildModernCard(
      title: "Requirements",
      icon: Icons.checklist_outlined,
      iconColor: AppColors.primaryAccent,
      child: Column(
        children:
            widget.job.requirements
                .map((req) => _buildRequirementItem(req))
                .toList(),
      ),
    );
  }

  Widget _buildRequirementItem(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.primaryAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.textOnAccent,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              requirement,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return _buildModernCard(
      title: "Skills Required",
      icon: Icons.code_outlined,
      iconColor: AppColors.primaryAccent,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            widget.job.requiredSkills
                .map((skill) => _buildModernSkillChip(skill))
                .toList(),
      ),
    );
  }

  Widget _buildModernSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.1),
            AppColors.primaryAccent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard() {
    return _buildModernCard(
      title: "About Company",
      icon: Icons.business_outlined,
      iconColor: AppColors.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.job.companyName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _companyDescription,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      elevation: 20, // Dramatic floating effect like home screen
      borderRadius: 24.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.3),
                width: 1,
              ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    if (_isCheckingApplication) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color:
            _hasAlreadyApplied
                ? AppColors.primaryAccent.withValues(alpha: 0.2)
                : AppColors.primaryAccent,
        borderRadius: BorderRadius.circular(28),
        boxShadow:
            _hasAlreadyApplied
                ? null
                : [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
      ),
      child: ElevatedButton(
        onPressed: _hasAlreadyApplied ? null : _showApplyDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasAlreadyApplied) ...[
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primaryAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _hasAlreadyApplied ? 'Applied' : 'Apply Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    _hasAlreadyApplied ? AppColors.primaryAccent : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to apply for jobs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasAlreadyApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already applied for this position'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobApplicationForm(job: widget.job),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.textOnAccent.withValues(alpha: 0.1)
          ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 10; j++) {
        canvas.drawCircle(Offset(i * 30.0, j * 30.0), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}