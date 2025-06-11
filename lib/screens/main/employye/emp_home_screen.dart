import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/employye/applicants/applicant_details_screen.dart';

class _RecentApplicantsCard extends StatelessWidget {
  final String companyName;

  const _RecentApplicantsCard({required this.companyName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .snapshots(),
      builder: (context, jobsSnapshot) {
        if (jobsSnapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (jobsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!jobsSnapshot.hasData || jobsSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No jobs posted yet'));
        }

        // Get all job IDs and titles
        final jobs =
            jobsSnapshot.data!.docs
                .map((doc) => {'id': doc.id, 'title': doc['title'] as String})
                .toList();

        // Create a stream for each job's applicants
        return FutureBuilder<List<List<Map<String, dynamic>>>>(
          future: Future.wait(
            jobs.map(
              (job) => FirebaseFirestore.instance
                  .collection('jobs')
                  .doc(companyName)
                  .collection('jobPostings')
                  .doc(job['id'])
                  .collection('applicants')
                  .orderBy('appliedAt', descending: true)
                  .limit(5)
                  .get()
                  .then(
                    (snapshot) =>
                        snapshot.docs.map((doc) {
                          final data = doc.data();
                          return {
                            ...data,
                            'jobTitle': job['title'],
                            'jobId': job['id'],
                          };
                        }).toList(),
                  ),
            ),
          ),
          builder: (context, applicantsSnapshot) {
            if (applicantsSnapshot.hasError) {
              return const Center(child: Text('Error loading applicants'));
            }

            if (applicantsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!applicantsSnapshot.hasData) {
              return const Center(child: Text('No applicants yet'));
            }

            // Combine all applicants from different jobs
            final allApplicants =
                applicantsSnapshot.data!.expand((x) => x).toList();

            // Sort all applicants by appliedAt
            allApplicants.sort((a, b) {
              final aDate = DateTime.parse(a['appliedAt'] as String);
              final bDate = DateTime.parse(b['appliedAt'] as String);
              return bDate.compareTo(aDate);
            });

            // Take only the 5 most recent
            final recentApplicants = allApplicants.take(5).toList();

            if (recentApplicants.isEmpty) {
              return const Center(child: Text('No applicants yet'));
            }

            return Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Recent Applicants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentApplicants.length,
                    itemBuilder: (context, index) {
                      final applicant = recentApplicants[index];
                      final appliedAt = DateTime.parse(applicant['appliedAt']);
                      final timeAgo = _getTimeAgo(appliedAt);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              applicant['applicantPhotoUrl'] != null
                                  ? NetworkImage(applicant['applicantPhotoUrl'])
                                  : null,
                          child:
                              applicant['applicantPhotoUrl'] == null
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(
                          applicant['applicantName'] ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Applied for: ${applicant['jobTitle']}'),
                            Text(
                              'Applied $timeAgo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ApplicantDetailsScreen(
                                    applicant: applicant,
                                    jobTitle: applicant['jobTitle'],
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
