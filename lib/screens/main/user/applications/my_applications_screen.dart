import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/screens/main/user/applications/application_detail_screen.dart';
import 'package:intl/intl.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _selectedFilter = 'all'; // all, pending, accepted, rejected
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      print('📋 [MY APPLICATIONS] Loading applications for user: ${currentUser.uid}');

      final snapshot = await FirebaseFirestore.instance
          .collection('users_specific')
          .doc(currentUser.uid)
          .collection('applications')
          .orderBy('appliedAt', descending: true)
          .get();

      final applications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print('✅ [MY APPLICATIONS] Loaded ${applications.length} applications');

      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [MY APPLICATIONS] Error loading applications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_selectedFilter == 'all') return _applications;
    return _applications.where((app) => 
      app['status']?.toLowerCase() == _selectedFilter
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lookGigLightGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterButtons(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF9228),
                      ),
                    )
                  : _filteredApplications.isEmpty
                      ? _buildEmptyState()
                      : _buildApplicationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Check if we can pop (if we're in a navigation stack)
    final canPop = Navigator.canPop(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
      child: Row(
        children: [
          if (canPop)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF150B3D),
                size: 24,
              ),
            ),
          if (canPop) const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'My Applications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
                height: 1.302,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (canPop) const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
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
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedFilter = filter);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFFF9228) : Colors.grey[200],
        foregroundColor: isSelected ? AppColors.white : AppColors.primaryText,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          fontFamily: 'DM Sans',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == 'all'
                  ? 'No Applications Yet'
                  : 'No ${_selectedFilter.substring(0, 1).toUpperCase()}${_selectedFilter.substring(1)} Applications',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF150B3D),
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFilter == 'all'
                  ? 'Start applying to jobs to see your applications here'
                  : 'You don\'t have any $_selectedFilter applications',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF524B6B),
                fontFamily: 'DM Sans',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredApplications.length,
      itemBuilder: (context, index) {
        return _buildApplicationCard(_filteredApplications[index]);
      },
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final appliedAt = DateTime.parse(application['appliedAt']);
    final status = application['status'] ?? 'pending';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicationDetailScreen(
              application: application,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withOpacity(0.18),
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application['jobTitle'] ?? 'Job Title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D0140),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application['companyName'] ?? 'Company',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lookGigPurple,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Applied on ${DateFormat('MMM dd, yyyy').format(appliedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],
            ),
            if (application['cvFileName'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application['cvFileName'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'DM Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'shortlisted':
        return const Color(0xFFFF9228);
      default:
        return const Color(0xFFFF9228);
    }
  }
}
