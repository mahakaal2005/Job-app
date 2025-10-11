import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_work_app/screens/main/employye/applicants/applicant_details_screen.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/provider/all_applicants_provider.dart';
import 'package:intl/intl.dart';
import 'package:get_work_app/provider/applicant_status_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String companyName;
  final String jobTitle;

  const AllApplicantsScreen({
    super.key,
    required this.jobId,
    required this.companyName,
    required this.jobTitle,
  });

  @override
  State<AllApplicantsScreen> createState() => _AllApplicantsScreenState();
}

class _AllApplicantsScreenState extends State<AllApplicantsScreen> {
  @override
  void initState() {
    super.initState();
    // Load applicants when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load statuses for all jobs if viewing all applicants
      if (widget.jobId.isEmpty) {
        final jobsSnapshot =
            await FirebaseFirestore.instance
                .collection('jobs')
                .doc(widget.companyName)
                .collection('jobPostings')
                .get();

        for (var job in jobsSnapshot.docs) {
          await context.read<ApplicantStatusProvider>().loadJobStatuses(
            widget.companyName,
            job.id,
          );
        }
      } else {
        // Load statuses for specific job
        await context.read<ApplicantStatusProvider>().loadJobStatuses(
          widget.companyName,
          widget.jobId,
        );
      }

      // Then load applicants
      await context.read<AllApplicantsProvider>().loadApplicants(
        widget.companyName,
        jobId: widget.jobId.isEmpty ? null : widget.jobId,
        jobTitle: widget.jobTitle,
      );
    });
  }

  @override
  void dispose() {
    // Clear status cache when leaving the screen
    if (widget.jobId.isNotEmpty) {
      context.read<ApplicantStatusProvider>().clearJobCache(
        widget.companyName,
        widget.jobId,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          widget.jobId.isEmpty
              ? 'All Applicants'
              : 'Applicants for ${widget.jobTitle}',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Status Filter Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildFilterButton('All', 'all')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterButton('Pending', 'pending')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterButton('Accepted', 'accepted')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterButton('Rejected', 'rejected')),
              ],
            ),
          ),
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    context.read<AllApplicantsProvider>().updateSearchQuery(
                      value,
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Search applicants...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.mutedText.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.mutedText.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Job Filter (only show if viewing all applicants)
                      if (widget.jobId.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.mutedText.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Consumer<AllApplicantsProvider>(
                            builder: (context, provider, child) {
                              return DropdownButton<String>(
                                value:
                                    provider.jobTitles.contains('all')
                                        ? 'all'
                                        : provider.jobTitles.first,
                                underline: const SizedBox(),
                                items:
                                    provider.jobTitles.map((job) {
                                      return DropdownMenuItem(
                                        value: job,
                                        child: Text(
                                          job == 'all' ? 'All Jobs' : job,
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.updateJobFilter(value);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Sort Options
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.mutedText.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Consumer<AllApplicantsProvider>(
                          builder: (context, provider, child) {
                            return Row(
                              children: [
                                DropdownButton<String>(
                                  value: provider.sortBy,
                                  underline: const SizedBox(),
                                  items:
                                      ['date', 'name', 'status'].map((sort) {
                                        return DropdownMenuItem(
                                          value: sort,
                                          child: Text(
                                            'Sort by ${sort.substring(0, 1).toUpperCase()}${sort.substring(1)}',
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      provider.updateSorting(value);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    provider.isSortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    provider.updateSorting(provider.sortBy);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Applicants List
          Expanded(
            child: Consumer<AllApplicantsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        provider.error,
                        style: TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final applicants = provider.applicants;

                if (applicants.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No applicants found',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applicants.length,
                  itemBuilder: (context, index) {
                    final applicant = applicants[index];
                    final appliedAt = DateTime.parse(applicant['appliedAt']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              applicant['applicantProfileImg'] != null &&
                                      applicant['applicantProfileImg']
                                          .isNotEmpty
                                  ? NetworkImage(
                                    applicant['applicantProfileImg'],
                                  )
                                  : null,
                          child:
                              applicant['applicantProfileImg'] == null ||
                                      applicant['applicantProfileImg'].isEmpty
                                  ? Text(
                                    applicant['applicantName'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                        title: Text(
                          applicant['applicantName'] ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Applied for ${applicant['jobTitle']}',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Applied on ${DateFormat('MMM dd, yyyy').format(appliedAt)}',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Consumer<ApplicantStatusProvider>(
                          builder: (context, provider, child) {
                            final currentStatus =
                                provider.getStatus(
                                  widget.companyName,
                                  applicant['jobId'],
                                  applicant['id'],
                                ) ??
                                applicant['status'] ??
                                'pending';

                            return GestureDetector(
                              onTap: () => _showApplicantDetails(applicant),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    currentStatus,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusColor(
                                      currentStatus,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  currentStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(currentStatus),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        onTap: () => _showApplicantDetails(applicant),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicantDetails(Map<String, dynamic> applicant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ApplicantDetailsScreen(
              applicant: applicant,
              jobTitle: applicant['jobTitle'],
            ),
      ),
    );

    if (result != null && result is String) {
      try {
        // Update status in both providers
        await context.read<ApplicantStatusProvider>().updateStatus(
          companyName: widget.companyName,
          jobId: applicant['jobId'],
          applicantId: applicant['id'],
          status: result,
        );

        await context.read<AllApplicantsProvider>().updateApplicantStatus(
          companyName: widget.companyName,
          jobId: applicant['jobId'],
          applicantId: applicant['id'],
          status: result,
        );
      } catch (e) {
        print('Error updating applicant status: $e');
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'shortlisted':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildFilterButton(String label, String status) {
    return Consumer<AllApplicantsProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.selectedStatus == status;
        return ElevatedButton(
          onPressed: () {
            provider.updateStatusFilter(status);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? AppColors.primaryBlue : Colors.grey[200],
            foregroundColor:
                isSelected ? AppColors.whiteText : AppColors.primaryText,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String? status) {
    return Consumer<ApplicantStatusProvider>(
      builder: (context, provider, child) {
        final currentStatus = provider.getStatus(
          widget.companyName,
          widget.jobId,
          status ?? 'pending',
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(currentStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            currentStatus.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(currentStatus),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
