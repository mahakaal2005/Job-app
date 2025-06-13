import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_work_app/screens/main/employye/applicants/applicant_details_screen.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/provider/all_applicants_provider.dart';
import 'package:intl/intl.dart';

class AllApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String companyName;
  final String jobTitle;

  const AllApplicantsScreen({
    Key? key,
    required this.jobId,
    required this.companyName,
    required this.jobTitle,
  }) : super(key: key);

  @override
  State<AllApplicantsScreen> createState() => _AllApplicantsScreenState();
}

class _AllApplicantsScreenState extends State<AllApplicantsScreen> {
  @override
  void initState() {
    super.initState();
    // Load applicants when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllApplicantsProvider>().loadApplicants(
        widget.companyName,
        jobId: widget.jobId.isEmpty ? null : widget.jobId,
        jobTitle: widget.jobTitle,
      );
    });
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
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              applicant['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (applicant['status'] ?? 'Pending').toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(applicant['status']),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
      // Update applicant status using the provider
      await context.read<AllApplicantsProvider>().updateApplicantStatus(
        companyName: widget.companyName,
        jobId: applicant['jobId'],
        applicantId: applicant['id'],
        status: result,
      );
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
}
