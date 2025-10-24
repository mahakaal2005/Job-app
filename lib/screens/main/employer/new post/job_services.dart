import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/services/auth_services.dart';

class JobService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> createJob(Job job) async {
    try {
      print('🔍 [JOB_SERVICE] createJob() called');
      final userData = await AuthService.getUserData();
      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();

      // SECURITY FIX: Prevent job creation without valid company info
      if (companyInfo == null || companyInfo['companyName'] == null || companyInfo['companyName'].toString().trim().isEmpty) {
        print('❌ [JOB_SERVICE] Cannot create job - no company info available');
        throw Exception('Company profile must be completed before creating jobs. Please complete your onboarding first.');
      }

      final companyName = companyInfo['companyName'].toString().trim();
      print('🔍 [JOB_SERVICE] Creating job for company: $companyName');
      
      final docRef =
          _firestore
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .doc();

      final jobWithId = job.copyWith(
        id: docRef.id,
        companyName: companyName,
        companyLogo: companyInfo['companyLogo'] ?? '',
        employerId: userData?['uid'] ?? '',
      );

      await docRef.set(jobWithId.toJson());
      print('✅ [JOB_SERVICE] Job created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ [JOB_SERVICE] Error creating job: $e');
      throw Exception('Failed to create job: $e');
    }
  }

  static Future<List<Job>> getCompanyJobs() async {
    try {
      print('🔍 [JOB_SERVICE] getCompanyJobs() called');
      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();
      print('📊 [JOB_SERVICE] Company info: ${companyInfo != null ? "EXISTS" : "NULL"}');
      
      // SECURITY FIX: Return empty list if no company info (user skipped onboarding)
      // This prevents data leakage between employers
      if (companyInfo == null || companyInfo['companyName'] == null || companyInfo['companyName'].toString().trim().isEmpty) {
        print('⚠️ [JOB_SERVICE] No company info available - returning empty job list');
        return [];
      }

      final companyName = companyInfo['companyName'].toString().trim();
      print('🔍 [JOB_SERVICE] Fetching jobs for company: $companyName');

      final querySnapshot =
          await _firestore
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .orderBy('createdAt', descending: true)
              .get();

      final jobs = querySnapshot.docs.map((doc) {
        return Job.fromJson(doc.data());
      }).toList();
      
      print('✅ [JOB_SERVICE] Found ${jobs.length} jobs for company: $companyName');
      return jobs;
    } catch (e) {
      print('❌ [JOB_SERVICE] Error fetching jobs: $e');
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  static Future<void> updateJob(Job job) async {
    try {
      print('🔍 [JOB_SERVICE] updateJob() called for job ID: ${job.id}');
      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();

      // SECURITY FIX: Prevent job updates without valid company info
      if (companyInfo == null || companyInfo['companyName'] == null || companyInfo['companyName'].toString().trim().isEmpty) {
        print('❌ [JOB_SERVICE] Cannot update job - no company info available');
        throw Exception('Company profile must be completed before updating jobs. Please complete your onboarding first.');
      }

      final companyName = companyInfo['companyName'].toString().trim();
      print('🔍 [JOB_SERVICE] Updating job for company: $companyName');

      await _firestore
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(job.id)
          .update(job.copyWith(updatedAt: DateTime.now()).toJson());
          
      print('✅ [JOB_SERVICE] Job updated successfully');
    } catch (e) {
      print('❌ [JOB_SERVICE] Error updating job: $e');
      throw Exception('Failed to update job: $e');
    }
  }

  static Future<void> deleteJob(String jobId) async {
    try {
      print('🔍 [JOB_SERVICE] deleteJob() called for job ID: $jobId');
      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();

      // SECURITY FIX: Prevent job deletion without valid company info
      if (companyInfo == null || companyInfo['companyName'] == null || companyInfo['companyName'].toString().trim().isEmpty) {
        print('❌ [JOB_SERVICE] Cannot delete job - no company info available');
        throw Exception('Company profile must be completed before deleting jobs. Please complete your onboarding first.');
      }

      final companyName = companyInfo['companyName'].toString().trim();
      print('🔍 [JOB_SERVICE] Deleting job for company: $companyName');

      await _firestore
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .delete();
          
      print('✅ [JOB_SERVICE] Job deleted successfully');
    } catch (e) {
      print('❌ [JOB_SERVICE] Error deleting job: $e');
      throw Exception('Failed to delete job: $e');
    }
  }

  static Future<void> toggleJobStatus(String jobId, bool newStatus) async {
    try {
      print('🔍 [JOB_SERVICE] toggleJobStatus() called for job ID: $jobId, status: $newStatus');
      final companyInfo = await AuthService.getEMPLOYERCompanyInfo();

      // SECURITY FIX: Prevent job status changes without valid company info
      if (companyInfo == null || companyInfo['companyName'] == null || companyInfo['companyName'].toString().trim().isEmpty) {
        print('❌ [JOB_SERVICE] Cannot toggle job status - no company info available');
        throw Exception('Company profile must be completed before modifying jobs. Please complete your onboarding first.');
      }

      final companyName = companyInfo['companyName'].toString().trim();
      print('🔍 [JOB_SERVICE] Toggling job status for company: $companyName');

      await _firestore
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .update({
            'isActive': newStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          
      print('✅ [JOB_SERVICE] Job status toggled successfully');
    } catch (e) {
      print('❌ [JOB_SERVICE] Error toggling job status: $e');
      throw Exception('Failed to toggle job status: $e');
    }
  }
}
