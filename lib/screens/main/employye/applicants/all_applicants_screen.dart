import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/employye/applicants/applicant_details_screen.dart';
import 'package:get_work_app/utils/app_colors.dart';

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
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      final applicantsSnapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(widget.companyName)
              .collection('jobPostings')
              .doc(widget.jobId)
              .collection('applicants')
              .orderBy('appliedAt', descending: true)
              .get();

      final List<Map<String, dynamic>> applicants = [];
      for (var doc in applicantsSnapshot.docs) {
        final data = doc.data();
        applicants.add(data);
      }

      setState(() {
        _applicants = applicants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load applicants: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'All Applicants',
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error,
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : _applicants.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No applicants yet',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _applicants.length,
                itemBuilder: (context, index) {
                  final applicant = _applicants[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            applicant['applicantProfileImg'] != null &&
                                    applicant['applicantProfileImg'].isNotEmpty
                                ? NetworkImage(applicant['applicantProfileImg'])
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
                            'Experience: ${applicant['yearsOfExperience']}',
                            style: TextStyle(color: AppColors.secondaryText),
                          ),
                          Text(
                            'Status: ${applicant['status'] ?? 'Pending'}',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () => _showApplicantDetails(applicant),
                      ),
                      onTap: () => _showApplicantDetails(applicant),
                    ),
                  );
                },
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
              jobTitle: widget.jobTitle,
            ),
      ),
    );

    if (result != null && result is String) {
      // Update applicant status in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.companyName)
            .collection('jobPostings')
            .doc(widget.jobId)
            .collection('applicants')
            .doc(applicant['id'])
            .update({'status': result});

        // Refresh applicants list
        _loadApplicants();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
