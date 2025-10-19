import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkProvider with ChangeNotifier {
  final Set<String> _bookmarkedJobs = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _currentUserId;
  String? _userCollection; // Cache the collection name (users_specific or employers)
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;

  BookmarkProvider() {
    _initializeAuthListener();
  }

  Set<String> get bookmarkedJobs => _bookmarkedJobs;
  bool get isInitialized => _isInitialized;

  /// Initialize auth state listener to automatically sync bookmarks on login/logout
  void _initializeAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _currentUserId = user.uid;
        _loadUserBookmarks(user.uid);
      } else {
        _clearBookmarks();
      }
    });
  }

  /// Load bookmarks from Firestore for the given user
  Future<void> _loadUserBookmarks(String userId) async {
    try {
      debugPrint('📚 BookmarkProvider: Loading bookmarks for user $userId');
      
      // Determine which collection the user is in
      final collection = await _getUserCollection(userId);
      if (collection == null) {
        debugPrint('⚠️ BookmarkProvider: User document not found in any collection');
        _isInitialized = true;
        notifyListeners();
        return;
      }
      
      // Cache the collection name for future operations
      _userCollection = collection;
      
      // Load bookmarks from Firestore
      final doc = await _firestore.collection(collection).doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final bookmarks = List<String>.from(data?['bookmarks'] ?? []);
        
        _bookmarkedJobs.clear();
        _bookmarkedJobs.addAll(bookmarks);
        
        debugPrint('✅ BookmarkProvider: Loaded ${bookmarks.length} bookmarks from $collection');
      } else {
        debugPrint('⚠️ BookmarkProvider: User document exists but has no data');
        _bookmarkedJobs.clear();
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ BookmarkProvider: Error loading bookmarks: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Determine which Firestore collection the user belongs to
  /// Returns 'users_specific' or 'employers', or null if not found
  Future<String?> _getUserCollection(String userId) async {
    try {
      // Try users_specific first (most common)
      final userDoc = await _firestore.collection('users_specific').doc(userId).get();
      if (userDoc.exists) {
        return 'users_specific';
      }
      
      // Try employers collection
      final employerDoc = await _firestore.collection('employers').doc(userId).get();
      if (employerDoc.exists) {
        return 'employers';
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ BookmarkProvider: Error determining user collection: $e');
      return null;
    }
  }

  /// Check if a job is bookmarked
  bool isBookmarked(String jobId) {
    return _bookmarkedJobs.contains(jobId);
  }

  /// Toggle bookmark status for a job (add if not bookmarked, remove if bookmarked)
  /// Uses optimistic UI update - updates local state immediately, then syncs to Firebase
  Future<void> toggleBookmark(String jobId) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ BookmarkProvider: Cannot toggle bookmark - user not authenticated');
      return;
    }

    // Optimistic update - update UI immediately
    final wasBookmarked = _bookmarkedJobs.contains(jobId);
    if (wasBookmarked) {
      _bookmarkedJobs.remove(jobId);
      debugPrint('🔖 BookmarkProvider: Removed bookmark for job $jobId (optimistic)');
    } else {
      _bookmarkedJobs.add(jobId);
      debugPrint('🔖 BookmarkProvider: Added bookmark for job $jobId (optimistic)');
    }
    notifyListeners();

    // Sync to Firebase in background
    _syncBookmarkToFirebase(jobId, wasBookmarked);
  }

  /// Sync bookmark change to Firebase Firestore
  Future<void> _syncBookmarkToFirebase(String jobId, bool wasBookmarked) async {
    if (_currentUserId == null || _userCollection == null) {
      debugPrint('⚠️ BookmarkProvider: Cannot sync - missing userId or collection');
      return;
    }

    try {
      final userDoc = _firestore.collection(_userCollection!).doc(_currentUserId);
      
      if (wasBookmarked) {
        // Remove from bookmarks array
        await userDoc.update({
          'bookmarks': FieldValue.arrayRemove([jobId])
        });
        debugPrint('✅ BookmarkProvider: Removed bookmark from Firebase');
      } else {
        // Add to bookmarks array (creates field if doesn't exist)
        await userDoc.update({
          'bookmarks': FieldValue.arrayUnion([jobId])
        }).catchError((error) async {
          // If update fails (field doesn't exist), create it
          if (error.toString().contains('NOT_FOUND')) {
            await userDoc.set({
              'bookmarks': [jobId]
            }, SetOptions(merge: true));
            debugPrint('✅ BookmarkProvider: Created bookmarks field and added bookmark');
          } else {
            throw error;
          }
        });
        debugPrint('✅ BookmarkProvider: Added bookmark to Firebase');
      }
    } catch (e) {
      debugPrint('❌ BookmarkProvider: Error syncing bookmark to Firebase: $e');
      // Note: We keep the optimistic update even if Firebase sync fails
      // Firebase offline persistence will retry when connection is restored
    }
  }

  /// Set bookmarks (used for bulk operations)
  void setBookmarks(Set<String> bookmarks) {
    _bookmarkedJobs.clear();
    _bookmarkedJobs.addAll(bookmarks);
    notifyListeners();
  }

  /// Clear all bookmarks (called on logout)
  void _clearBookmarks() {
    debugPrint('🧹 BookmarkProvider: Clearing bookmarks (user logged out)');
    _bookmarkedJobs.clear();
    _currentUserId = null;
    _userCollection = null;
    _isInitialized = false;
    notifyListeners();
  }

  /// Manually refresh bookmarks from Firebase (useful for debugging or force refresh)
  Future<void> refreshBookmarks() async {
    if (_currentUserId != null) {
      await _loadUserBookmarks(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}