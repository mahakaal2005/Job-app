import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/user/jobs/bookmark_provider.dart';
import 'package:get_work_app/screens/main/user/jobs/job_detail_screen_new.dart';
import 'package:get_work_app/screens/main/user/jobs/user_all_jobs_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/image_utils.dart';
import 'package:get_work_app/utils/number_formatter.dart';
import 'package:get_work_app/services/profile_gating_service.dart';
import 'package:provider/provider.dart';

class BookmarksScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const BookmarksScreen({super.key, this.onNavigateToTab});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Job> _savedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      final allJobs = await AllJobsService.getAllJobs(limit: 100);
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      
      if (mounted) {
        setState(() {
          _savedJobs = allJobs.where((job) => bookmarkProvider.isBookmarked(job.id)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved jobs: $e')),
        );
      }
    }
  }

  void _deleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Bookmarks'),
        content: const Text('Are you sure you want to remove all bookmarked jobs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final canBookmark = await ProfileGatingService.canPerformAction(
                context,
                actionName: 'bookmark jobs',
              );
              if (canBookmark) {
                final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
                for (var job in _savedJobs) {
                  bookmarkProvider.toggleBookmark(job.id);
                }
                if (mounted) {
                  setState(() => _savedJobs.clear());
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Delete All', style: TextStyle(color: Color(0xFFFF9228))),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minute ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour ago';
      } else if (difference.inDays == 1) {
        return '1 day ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return '25 minute ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gigAppPurple))
            : _savedJobs.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildJobsList()),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'Save Job',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
          ),
          if (_savedJobs.isNotEmpty)
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: _deleteAll,
                child: const Text(
                  'Delete all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFFF9228),
                    fontFamily: 'Open Sans',
                    height: 1.362,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            SizedBox(
              width: 223,
              child: Column(
                children: [
                  const Text(
                    'No Savings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF150B3D),
                      fontFamily: 'Open Sans',
                      height: 1.362,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(
                    width: 213,
                    child: Text(
                      'You don\'t have any jobs saved, please find it in search to save jobs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF524B6B),
                        fontFamily: 'Open Sans',
                        height: 1.362,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 54),
                  Image.asset(
                    'assets/images/no_savings_illustration.png',
                    width: 220,
                    height: 208,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 220,
                        height: 208,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            Container(
              width: 213,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF130160),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF99ABC6).withOpacity(0.18),
                    blurRadius: 62,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(0);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigate to home to find jobs')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF130160),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'FIND A JOB',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                    letterSpacing: 0.84,
                    height: 1.302,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _savedJobs.length,
      itemBuilder: (context, index) {
        return _buildJobCard(_savedJobs[index]);
      },
    );
  }

  Widget _buildJobCard(Job job) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isBookmarked(job.id);
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailScreenNew(
                  job: job,
                  isBookmarked: isBookmarked,
                  onBookmarkToggled: (jobId) async {
                    final canBookmark = await ProfileGatingService.canPerformAction(
                      context,
                      actionName: 'bookmark this job',
                    );
                    if (canBookmark) {
                      bookmarkProvider.toggleBookmark(jobId);
                      if (mounted) {
                        setState(() {
                          _savedJobs.removeWhere((j) => j.id == jobId);
                        });
                      }
                    }
                  },
                ),
              ),
            );
          },
          child: Container(
            width: 335,
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: job.companyLogo.isNotEmpty
                            ? ImageUtils.buildSafeNetworkImage(
                                imageUrl: job.companyLogo,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorWidget: _buildCompanyLogoFallback(job.companyName),
                              )
                            : _buildCompanyLogoFallback(job.companyName),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF150A33),
                              fontFamily: 'DM Sans',
                              height: 1.302,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                flex: 2,
                                child: Text(
                                  job.companyName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF524B6B),
                                    fontFamily: 'DM Sans',
                                    height: 1.302,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 2,
                                height: 2,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF524B6B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                flex: 2,
                                child: Text(
                                  job.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF524B6B),
                                    fontFamily: 'DM Sans',
                                    height: 1.302,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 2,
                                height: 2,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF524B6B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                flex: 1,
                                child: Text(
                                  _getTimeAgo(job.createdAt.toIso8601String()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF524B6B),
                                    fontFamily: 'DM Sans',
                                    height: 1.302,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showOptionsMenu(context, job, bookmarkProvider),
                      child: Image.asset(
                        'assets/images/options_menu_icon.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Color(0xFFC4C4C4),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildTag(job.employmentType),
                    _buildTag(job.experienceLevel),
                    if (job.workFrom != null && job.workFrom!.isNotEmpty)
                      _buildTag(job.workFrom!),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTimeAgo(job.createdAt.toIso8601String()),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFAAA6B9),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                    _buildFormattedSalary(job.salaryRange, job.employmentType),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFCBC9D4).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: Color(0xFF524B6B),
          fontFamily: 'DM Sans',
          height: 1.302,
        ),
      ),
    );
  }

  Widget _buildCompanyLogoFallback(String companyName) {
    return Container(
      color: AppColors.gigAppPurple.withOpacity(0.1),
      child: Center(
        child: Text(
          companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
          style: const TextStyle(
            color: AppColors.gigAppPurple,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedSalary(String salaryRange, String employmentType) {
    if (salaryRange.isEmpty) {
      return RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: '\$0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
            TextSpan(
              text: '/Mo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFAAA6B9),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
          ],
        ),
      );
    }

    try {
      // Check if salary already has a period indicator (e.g., "40/hour", "50/month")
      final hasPeriod = salaryRange.contains('/');
      String period = '';
      String numberPart = salaryRange;
      
      if (hasPeriod) {
        // Extract the period from the salary string
        final parts = salaryRange.split('/');
        numberPart = parts[0];
        if (parts.length > 1) {
          // Normalize the period format
          final periodText = parts[1].toLowerCase().trim();
          if (periodText.contains('hour') || periodText == 'hr') {
            period = '/hr';
          } else if (periodText.contains('month') || periodText == 'mo') {
            period = '/Mo';
          } else if (periodText.contains('year') || periodText == 'yr') {
            period = '/yr';
          } else if (periodText.contains('project')) {
            period = '/project';
          } else {
            period = '/$periodText';
          }
        }
      }
      
      // Remove currency symbols and commas from number part
      String cleaned = numberPart.replaceAll(RegExp(r'[₹$,\s]'), '');
      
      // Extract numbers (handle ranges like "10-16" or "50000-80000")
      final numbers = RegExp(r'\d+').allMatches(cleaned);
      if (numbers.isEmpty) {
        return Text(
          salaryRange,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF150B3D),
            fontFamily: 'DM Sans',
            height: 1.302,
          ),
        );
      }
      
      // Get first number (min salary)
      int minSalary = int.parse(numbers.first.group(0)!);
      
      // Format the amount with commas
      String formattedAmount = NumberFormatter.formatSalaryAmount(minSalary);
      
      // If no period was in the original data, determine it from employment type
      if (period.isEmpty) {
        switch (employmentType.toLowerCase()) {
          case 'full-time':
          case 'full time':
            period = '/Mo';
            break;
          case 'part-time':
          case 'part time':
            period = '/hr';
            break;
          case 'freelance':
          case 'contract':
            period = '/project';
            break;
          default:
            period = '/Mo';
        }
      }
      
      // Always use $ symbol
      String currency = '\$';
      
      // Return styled RichText with bold amount and gray period
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$currency$formattedAmount',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
            TextSpan(
              text: period,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFAAA6B9),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error formatting salary: $e');
      return RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: '\$0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
            TextSpan(
              text: '/Mo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFAAA6B9),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showOptionsMenu(BuildContext context, Job job, BookmarkProvider bookmarkProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 299,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 173,
                      top: 30,
                      child: Container(
                        width: 30,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B5858),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 35,
                      top: 80,
                      child: _buildMenuOption(
                        iconPath: 'assets/images/popup_send_message_icon.png',
                        text: 'Send message',
                        width: 134,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message feature coming soon')),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 35,
                      top: 129,
                      child: _buildMenuOption(
                        iconPath: 'assets/images/header_share_icon.png',
                        text: 'Shared',
                        width: 85,
                        iconColor: const Color(0xFF150B3D),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share feature coming soon')),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 35,
                      top: 178,
                      child: _buildMenuOption(
                        iconPath: 'assets/images/popup_delete_icon.png',
                        text: 'Delete',
                        width: 81,
                        onTap: () async {
                          final canBookmark = await ProfileGatingService.canPerformAction(
                            context,
                            actionName: 'bookmark this job',
                          );
                          if (canBookmark) {
                            bookmarkProvider.toggleBookmark(job.id);
                            if (mounted) {
                              setState(() {
                                _savedJobs.removeWhere((j) => j.id == job.id);
                              });
                            }
                          }
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Job removed from bookmarks'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 214,
                      child: Container(
                        width: 335,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF130160),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailScreenNew(
                                  job: job,
                                  isBookmarked: bookmarkProvider.isBookmarked(job.id),
                                  onBookmarkToggled: (jobId) async {
                                    final canBookmark = await ProfileGatingService.canPerformAction(
                                      context,
                                      actionName: 'bookmark this job',
                                    );
                                    if (canBookmark) {
                                      bookmarkProvider.toggleBookmark(jobId);
                                      if (mounted) {
                                        setState(() {
                                          _savedJobs.removeWhere((j) => j.id == jobId);
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF130160),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(width: 15),
                              Image.asset(
                                'assets/images/popup_apply_icon.png',
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.work_outline,
                                    size: 24,
                                    color: Colors.white,
                                  );
                                },
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  fontFamily: 'DM Sans',
                                  height: 1.302,
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
            ),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required String iconPath,
    required String text,
    required double width,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 24,
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: iconColor,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 24,
                  height: 24,
                  color: Colors.grey[300],
                );
              },
            ),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
