import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/user/jobs/user_job_detail.dart';
import 'package:get_work_app/screens/main/user/jobs/user_all_jobs_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:get_work_app/screens/main/user/jobs/bookmark_provider.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  List<Job> _savedJobs = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    try {
      setState(() => _isLoading = true);
      
      final allJobs = await AllJobsService.getAllJobs(limit: 100);
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      
      setState(() {
        _savedJobs = allJobs.where((job) => bookmarkProvider.isBookmarked(job.id)).toList();
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved jobs: $e')),
      );
    }
  }

  Future<void> _refreshJobs() async {
    setState(() => _isRefreshing = true);
    await _loadSavedJobs();
  }

  String _formatSalary(String salary) {
    final num = int.tryParse(salary) ?? 0;
    if (num >= 10000000) {
      return '₹${(num / 10000000).toStringAsFixed(1)}Cr';
    } else if (num >= 100000) {
      return '₹${(num / 100000).toStringAsFixed(1)}L';
    } else if (num >= 1000) {
      return '₹${(num / 1000).toStringAsFixed(0)}K';
    }
    return '₹$num';
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildJobCard(Job job) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isBookmarked(job.id);
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailScreen(
                    job: job,
                    isBookmarked: isBookmarked,
                    onBookmarkToggled: (jobId) => bookmarkProvider.toggleBookmark(jobId),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGrey, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: job.companyLogo.isNotEmpty
                              ? Image.network(
                                  job.companyLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildCompanyLogoFallback(job.companyName);
                                  },
                                )
                              : _buildCompanyLogoFallback(job.companyName),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.companyName,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          bookmarkProvider.toggleBookmark(job.id);
                          if (isBookmarked) {
                            setState(() {
                              _savedJobs.removeWhere((j) => j.id == job.id);
                            });
                          }
                        },
                        icon: Icon(
                          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: AppColors.primaryBlue,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    job.description.length > 100
                        ? '${job.description.substring(0, 100)}...'
                        : job.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(job.createdAt.toIso8601String()),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatSalary(job.salaryRange),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/year',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailScreen(
                                job: job,
                                isBookmarked: isBookmarked,
                                onBookmarkToggled: (jobId) => bookmarkProvider.toggleBookmark(jobId),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyLogoFallback(String companyName) {
    return Container(
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Center(
        child: Text(
          companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshJobs,
            icon: _isRefreshing
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          : _savedJobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        size: 60,
                        color: AppColors.primaryBlue.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved jobs yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bookmark jobs to see them here',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.hintText,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshJobs,
                  color: AppColors.primaryBlue,
                  child: ListView.builder(
                    itemCount: _savedJobs.length,
                    itemBuilder: (context, index) {
                      return _buildJobCard(_savedJobs[index]);
                    },
                  ),
                ),
    );
  }
}