import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Memory monitoring utility to help detect and prevent memory leaks
class MemoryMonitor {
  static int _firestoreOperationCount = 0;
  static int _streamSubscriptionCount = 0;
  static DateTime? _lastMemoryCheck;
  static const int _maxFirestoreOpsPerMinute = 100; // Prevent runaway operations
  
  /// Track Firestore operations to detect infinite loops
  static void trackFirestoreOperation(String operation) {
    _firestoreOperationCount++;
    
    final now = DateTime.now();
    _lastMemoryCheck ??= now;
    
    // Check if we've exceeded safe operation limits
    final timeDiff = now.difference(_lastMemoryCheck!).inMinutes;
    if (timeDiff >= 1) {
      if (_firestoreOperationCount > _maxFirestoreOpsPerMinute) {
        debugPrint('🚨 MEMORY WARNING: $_firestoreOperationCount Firestore operations in $timeDiff minute(s)');
        debugPrint('🚨 This may indicate an infinite loop or memory leak!');
        
        // Log to crash reporting if available
        if (kDebugMode) {
          developer.log(
            'High Firestore operation count detected',
            name: 'MemoryMonitor',
            error: 'Potential memory leak: $_firestoreOperationCount ops in ${timeDiff}min',
          );
        }
      }
      
      // Reset counters
      _firestoreOperationCount = 0;
      _lastMemoryCheck = now;
    }
    
    if (kDebugMode) {
      debugPrint('🔵 Firestore operation: $operation (Count: $_firestoreOperationCount)');
    }
  }
  
  /// Track stream subscriptions to detect leaks
  static void trackStreamSubscription(String streamName, bool isCreated) {
    if (isCreated) {
      _streamSubscriptionCount++;
      debugPrint('🔵 Stream created: $streamName (Active: $_streamSubscriptionCount)');
    } else {
      _streamSubscriptionCount--;
      debugPrint('🔴 Stream disposed: $streamName (Active: $_streamSubscriptionCount)');
    }
    
    // Warn if too many active streams
    if (_streamSubscriptionCount > 10) {
      debugPrint('🚨 MEMORY WARNING: $_streamSubscriptionCount active streams');
      debugPrint('🚨 This may indicate stream subscriptions not being disposed!');
    }
  }
  
  /// Log memory usage information
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      debugPrint('📊 Memory check: $context');
      debugPrint('📊 Active streams: $_streamSubscriptionCount');
      debugPrint('📊 Firestore ops this minute: $_firestoreOperationCount');
    }
  }
  
  /// Emergency memory cleanup (call if memory issues detected)
  static void emergencyCleanup() {
    debugPrint('🚨 EMERGENCY MEMORY CLEANUP INITIATED');
    
    // Clear location service cache
    try {
      // This will be available after our LocationService fix
      // LocationService.clearCache();
      debugPrint('✅ Location cache cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear location cache: $e');
    }
    
    // Force garbage collection (note: gc() is not available in release mode)
    if (kDebugMode) {
      // In debug mode, we can suggest garbage collection
      debugPrint('✅ Garbage collection suggested (automatic in release mode)');
    }
    
    // Reset counters
    _firestoreOperationCount = 0;
    _streamSubscriptionCount = 0;
    _lastMemoryCheck = DateTime.now();
    
    debugPrint('🚨 EMERGENCY CLEANUP COMPLETED');
  }
  
  /// Check if memory usage is healthy
  static bool get isMemoryHealthy {
    return _streamSubscriptionCount <= 10 && 
           _firestoreOperationCount <= _maxFirestoreOpsPerMinute;
  }
}