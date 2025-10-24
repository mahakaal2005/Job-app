import 'package:flutter/material.dart';

/// Simplified ProfileGatingService - no profile gating, always allows access
class ProfileGatingService {
  /// Always returns true - no profile gating
  static Future<bool> checkProfileCompletion(BuildContext context, {bool showDialog = true}) async {
    return true;
  }

  /// Always returns true - no profile gating
  static Future<bool> isProfileComplete() async {
    return true;
  }

  /// Always returns true - no profile gating
  static Future<bool> checkAndNavigateIfIncomplete(BuildContext context, {bool showDialog = true}) async {
    return true;
  }

  /// Always returns true - no profile gating
  static Future<bool> checkProfileCompletionForJobApplication(BuildContext context, {bool showDialog = true}) async {
    return true;
  }

  /// Always returns true - no profile gating
  static Future<bool> checkProfileCompletionForBookmark(BuildContext context, {bool showDialog = true}) async {
    return true;
  }

  /// Always returns true - no profile gating
  static Future<bool> checkProfileCompletionForJobPosting(BuildContext context, {bool showDialog = true}) async {
    return true;
  }

  /// Always returns true - no profile gating
  static Future<bool> canPerformAction(BuildContext context, {String? actionName, bool showDialog = true}) async {
    return true;
  }
}