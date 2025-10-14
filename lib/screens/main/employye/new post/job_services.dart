import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/employye/new post/job_new_model.dart';
import 'package:get_work_app/services/auth_services.dart';

class JobService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> createJob(Job job) async {
    try {
      final userData = await AuthService.getUserData();
      final companyInfo = await AuthService.getEmployeeCompanyInfo();

      final companyName = companyInfo?['companyName'] ?? 'Unknown Company';
      final docRef =
          _firestore
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .doc();

      final jobWithId = job.copyWith(
        id: docRef.id,
        companyName: companyName,
        companyLogo: companyInfo?['companyLogo'] ?? '',
        employerId: userData?['uid'] ?? '',
      );

      await docRef.set(jobWithId.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }
  }

  static Future<List<Job>> getCompanyJobs() async {
    try {
      final companyInfo = await AuthService.getEmployeeCompanyInfo();
      final companyName = companyInfo?['companyName'] ?? 'Unknown Company';

      final querySnapshot =
          await _firestore
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        return Job.fromJson(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  static Future<void> updateJob(Job job) async {
    try {
      final companyInfo = await AuthService.getEmployeeCompanyInfo();
      final companyName = companyInfo?['companyName'] ?? 'Unknown Company';

      await _firestore
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(job.id)
          .update(job.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update job: $e');
    }
  }

  static Future<void> deleteJob(String jobId) async {
    try {
      final companyInfo = await AuthService.getEmployeeCompanyInfo();
      final companyName = companyInfo?['companyName'] ?? 'Unknown Company';

      await _firestore
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }

  static Future<void> toggleJobStatus(String jobId, bool newStatus) async {
    try {
      final companyInfo = await AuthService.getEmployeeCompanyInfo();
      final companyName = companyInfo?['companyName'] ?? 'Unknown Company';

      await _firestore
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .update({
            'isActive': newStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to toggle job status: $e');
    }
  }
}
