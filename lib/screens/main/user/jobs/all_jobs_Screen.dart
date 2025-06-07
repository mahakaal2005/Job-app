// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
// import 'package:get_work_app/screens/main/user/jobs/user_all_jobs_services.dart';
// import 'package:get_work_app/screens/main/user/jobs/job_detail.dart';
// import 'package:get_work_app/utils/app_colors.dart';

// class AllJobsScreen extends StatefulWidget {
//   const AllJobsScreen({Key? key}) : super(key: key);

//   @override
//   _AllJobsScreenState createState() => _AllJobsScreenState();
// }

// class _AllJobsScreenState extends State<AllJobsScreen> {
//   final ScrollController _scrollController = ScrollController();
//   List<Job> _jobs = [];
//   bool _isLoading = false;
//   bool _hasMore = true;
//   DocumentSnapshot? _lastDocument;
//   final int _limit = 10;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialJobs();
//     _scrollController.addListener(_scrollListener);
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // In your _AllJobsScreenState class

// Future<void> _loadInitialJobs() async {
//   if (_isLoading) return;
  
//   setState(() => _isLoading = true);
//   try {
//     final querySnapshot = await FirebaseFirestore.instance
//         .collectionGroup('jobPostings')
//         .where('isActive', isEqualTo: true)
//         .orderBy('createdAt', descending: true)
//         .limit(_limit)
//         .get();

//     final jobs = querySnapshot.docs.map((doc) => Job.fromJson(doc.data())).toList();

//     setState(() {
//       _jobs = jobs;
//       _isLoading = false;
//       if (querySnapshot.docs.isNotEmpty) {
//         _lastDocument = querySnapshot.docs.last; // Store the actual DocumentSnapshot
//       }
//       _hasMore = jobs.length == _limit;
//     });
//   } catch (e) {
//     setState(() => _isLoading = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error loading jobs: $e')),
//     );
//   }
// }

// Future<void> _loadMoreJobs() async {
//   if (!_hasMore || _isLoading || _lastDocument == null) return;
  
//   setState(() => _isLoading = true);
//   try {
//     final querySnapshot = await FirebaseFirestore.instance
//         .collectionGroup('jobPostings')
//         .where('isActive', isEqualTo: true)
//         .orderBy('createdAt', descending: true)
//         .startAfterDocument(_lastDocument!)
//         .limit(_limit)
//         .get();

//     final newJobs = querySnapshot.docs.map((doc) => Job.fromJson(doc.data())).toList();

//     setState(() {
//       _jobs.addAll(newJobs);
//       _isLoading = false;
//       if (querySnapshot.docs.isNotEmpty) {
//         _lastDocument = querySnapshot.docs.last; // Update the last document
//       }
//       _hasMore = newJobs.length == _limit;
//     });
//   } catch (e) {
//     setState(() => _isLoading = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error loading more jobs: $e')),
//     );
//   }
// }

//   void _scrollListener() {
//     if (_scrollController.offset >= 
//         _scrollController.position.maxScrollExtent - 200 &&
//         !_scrollController.position.outOfRange) {
//       _loadMoreJobs();
//     }
//   }

//   void _showJobDetails(Job job) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => JobDetailScreen(job: job),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('All Job Listings'),
//         backgroundColor: AppColors.primaryBlue,
//         elevation: 0,
//       ),
//       body: _isLoading && _jobs.isEmpty
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               controller: _scrollController,
//               itemCount: _jobs.length + (_hasMore ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index < _jobs.length) {
//                   return _buildJobCard(_jobs[index]);
//                 } else {
//                   return Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Center(
//                       child: _isLoading 
//                           ? const CircularProgressIndicator()
//                           : const Text('No more jobs available'),
//                     ),
//                   );
//                 }
//               },
//             ),
//     );
//   }

//   Widget _buildJobCard(Job job) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () => _showJobDetails(job),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   if (job.companyLogo.isNotEmpty)
//                     CircleAvatar(
//                       radius: 24,
//                       backgroundImage: NetworkImage(job.companyLogo),
//                     )
//                   else
//                     CircleAvatar(
//                       radius: 24,
//                       backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
//                       child: Text(
//                         job.companyName[0],
//                         style: TextStyle(
//                           color: AppColors.primaryBlue,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           job.title,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           job.companyName,
//                           style: TextStyle(
//                             color: AppColors.secondaryText,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryBlue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       '₹${job.salaryRange}/hr',
//                       style: TextStyle(
//                         color: AppColors.primaryBlue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 job.description.length > 100
//                     ? '${job.description.substring(0, 100)}...'
//                     : job.description,
//                 style: TextStyle(
//                   color: AppColors.secondaryText,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Wrap(
//                 spacing: 8,
//                 children: [
//                   if (job.employmentType.isNotEmpty)
//                     Chip(
//                       label: Text(job.employmentType),
//                       backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: ElevatedButton(
//                   onPressed: () => _showJobDetails(job),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryBlue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                   child: const Text(
//                     'Apply Now',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }