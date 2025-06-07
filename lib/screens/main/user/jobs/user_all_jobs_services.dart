import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';

class AllJobsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Job>> getAllJobs({
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collectionGroup('jobPostings')
          .where(
            'isActive',
            isEqualTo: true,
          ) 
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        return Job.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }
}
