import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/user/jobs/job_application_form.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:intl/intl.dart';

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
  bool _isScrolled = false;
  late bool _isBookmarked;
  String _companyDescription = '';
  bool _hasAlreadyApplied = false;
  bool _isCheckingApplication = true;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 100 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    _animationController.forward();
    _fetchCompanyDescription();
    _checkIfAlreadyApplied();
  }

  Future<void> _fetchCompanyDescription() async {
    try {
      final companyDoc =
          await FirebaseFirestore.instance
              .collection('employers')
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
      print('Error checking application status: $e');
      if (mounted) {
        setState(() => _isCheckingApplication = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          _buildFloatingHeader(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(children: [_buildApplyButton()]),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.elegantBlue),
          child: Stack(
            children: [
              // Animated background pattern
              Positioned.fill(
                child: CustomPaint(painter: BackgroundPatternPainter()),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                  color: AppColors.glassWhite,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.whiteText.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  widget.job.companyName,
                                  style: const TextStyle(
                                    color: AppColors.whiteText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.job.title,
                                style: const TextStyle(
                                  color: AppColors.whiteText,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildQuickInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: const SizedBox.shrink(), // Remove default leading
    );
  }

  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: _isScrolled ? AppColors.primaryGradient : null,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildBackButton(),
                if (_isScrolled) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.job.title,
                          style: const TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.job.companyName,
                          style: TextStyle(
                            color: AppColors.whiteText.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                _buildHeaderActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.whiteText.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.whiteText,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          onPressed: () {
            setState(() => _isBookmarked = !_isBookmarked);
            widget.onBookmarkToggled(widget.job.id);
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(icon: Icons.share_outlined, onPressed: () {}),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.whiteText.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.whiteText, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEnhancedCompanyLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
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
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.whiteText.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildQuickInfoItem(Icons.location_on, widget.job.location),
          const SizedBox(width: 20),
          _buildQuickInfoItem(
            Icons.access_time,
            _formatDate(widget.job.createdAt),
          ),
          const SizedBox(width: 20),
          _buildQuickInfoItem(Icons.work_outline, widget.job.employmentType),
        ],
      ),
    );
  }

  Widget _buildQuickInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppColors.whiteText, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.whiteText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.neonBlue, Color.fromARGB(255, 51, 101, 171)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.attach_money,
              color: AppColors.whiteText,
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
                    color: AppColors.whiteText.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.job.salaryRange}/month',
                  style: const TextStyle(
                    color: AppColors.whiteText,
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
      iconColor: AppColors.primaryBlue,
      child: Text(
        widget.job.description,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.mutedText,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return _buildModernCard(
      title: "Requirements",
      icon: Icons.checklist_outlined,
      iconColor: AppColors.error,
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
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.whiteText,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              requirement,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.mutedText,
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
      iconColor: AppColors.royalBlue,
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
            AppColors.royalBlue.withOpacity(0.1),
            AppColors.primaryBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.royalBlue.withOpacity(0.3)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: AppColors.royalBlue,
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
      iconColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.job.companyName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _companyDescription,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.mutedText,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
          child,
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    if (_isCheckingApplication) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          strokeWidth: 2,
        ),
      );
    }

    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _hasAlreadyApplied ? null : AppColors.primaryGradient,
          color: _hasAlreadyApplied ? AppColors.success.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow:
              _hasAlreadyApplied
                  ? null
                  : [
                    BoxShadow(
                      color: AppColors.blueShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        child: ElevatedButton(
          onPressed: _showApplyDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _hasAlreadyApplied ? Colors.transparent : Colors.transparent,
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
                  color: AppColors.success,
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
                      _hasAlreadyApplied
                          ? AppColors.success
                          : AppColors.whiteText,
                ),
              ),
            ],
          ),
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

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.whiteText.withOpacity(0.1)
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
