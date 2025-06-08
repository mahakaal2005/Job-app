import 'package:flutter/material.dart';

class BookmarkProvider with ChangeNotifier {
  final Set<String> _bookmarkedJobs = {};

  Set<String> get bookmarkedJobs => _bookmarkedJobs;

  bool isBookmarked(String jobId) {
    return _bookmarkedJobs.contains(jobId);
  }

  void toggleBookmark(String jobId) {
    if (_bookmarkedJobs.contains(jobId)) {
      _bookmarkedJobs.remove(jobId);
    } else {
      _bookmarkedJobs.add(jobId);
    }
    notifyListeners();
  }

  void setBookmarks(Set<String> bookmarks) {
    _bookmarkedJobs.clear();
    _bookmarkedJobs.addAll(bookmarks);
    notifyListeners();
  }
}