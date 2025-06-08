// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class BookmarkService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Add or remove a bookmark
//   Future<void> toggleBookmark(String userId, String jobId) async {
//     try {
//       final userDoc = _firestore.collection('users').doc(userId);
//       final doc = await userDoc.get();

//       if (doc.exists) {
//         final bookmarks = List<String>.from(doc.data()?['bookmarks'] ?? []);
        
//         if (bookmarks.contains(jobId)) {
//           // Remove bookmark
//           await userDoc.update({
//             'bookmarks': FieldValue.arrayRemove([jobId])
//           });
//         } else {
//           // Add bookmark
//           await userDoc.update({
//             'bookmarks': FieldValue.arrayUnion([jobId])
//           });
//         }
//       }
//     } catch (e) {
//       throw Exception('Failed to toggle bookmark: $e');
//     }
//   }

//   // Get all bookmarked job IDs for a user
//   Future<Set<String>> getUserBookmarks(String userId) async {
//     try {
//       final doc = await _firestore.collection('users').doc(userId).get();
//       if (doc.exists) {
//         final bookmarks = List<String>.from(doc.data()?['bookmarks'] ?? []);
//         return bookmarks.toSet();
//       }
//       return <String>{};
//     } catch (e) {
//       throw Exception('Failed to get bookmarks: $e');
//     }
//   }

//   // Get bookmarked jobs details
//   Future<List<Map<String, dynamic>>> getBookmarkedJobsDetails(String userId) async {
//     try {
//       final bookmarks = await getUserBookmarks(userId);
//       if (bookmarks.isEmpty) return [];

//       final jobs = await _firestore
//           .collection('jobPostings')
//           .where(FieldPath.documentId, whereIn: bookmarks.toList())
//           .get();

//       return jobs.docs.map((doc) => doc.data()).toList();
//     } catch (e) {
//       throw Exception('Failed to get bookmarked jobs: $e');
//     }
//   }

//   // Check if a job is bookmarked
//   Future<bool> isJobBookmarked(String userId, String jobId) async {
//     try {
//       final bookmarks = await getUserBookmarks(userId);
//       return bookmarks.contains(jobId);
//     } catch (e) {
//       throw Exception('Failed to check bookmark status: $e');
//     }
//   }

//   // Get current user's bookmarks (using auth)
//   Future<Set<String>> getCurrentUserBookmarks() async {
//     final user = _auth.currentUser;
//     if (user == null) return <String>{};
//     return await getUserBookmarks(user.uid);
//   }

//   // Toggle bookmark for current user
//   Future<void> toggleBookmarkForCurrentUser(String jobId) async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception('User not logged in');
//     return await toggleBookmark(user.uid, jobId);
//   }
// }