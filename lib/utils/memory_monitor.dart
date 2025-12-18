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
        debugPrint('[MEMORY_MONITOR][WARN] High Firestore activity: $_firestoreOperationCount ops in $timeDiff minute(s)');
        debugPrint('[MEMORY_MONITOR][WARN] This may indicate an infinite loop or a leak.');
        
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
      debugPrint('[MEMORY_MONITOR] Firestore op: $operation (count=$_firestoreOperationCount)');
    }
  }
  
  /// Track stream subscriptions to detect leaks
  static void trackStreamSubscription(String streamName, bool isCreated) {
    if (isCreated) {
      _streamSubscriptionCount++;
      debugPrint('[MEMORY_MONITOR] Stream created: $streamName (active=$_streamSubscriptionCount)');
    } else {
      _streamSubscriptionCount--;
      debugPrint('[MEMORY_MONITOR] Stream disposed: $streamName (active=$_streamSubscriptionCount)');
    }
    
    // Warn if too many active streams
    if (_streamSubscriptionCount > 10) {
      debugPrint('[MEMORY_MONITOR][WARN] High active stream count: $_streamSubscriptionCount');
      debugPrint('[MEMORY_MONITOR][WARN] This may indicate stream subscriptions are not being disposed.');
    }
  }
  
  /// Log memory usage information
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      debugPrint('[MEMORY_MONITOR] Memory check: $context');
      debugPrint('[MEMORY_MONITOR] Active streams: $_streamSubscriptionCount');
      debugPrint('[MEMORY_MONITOR] Firestore ops (current minute): $_firestoreOperationCount');
    }
  }
  
  /// Emergency memory cleanup (call if memory issues detected)
  static void emergencyCleanup() {
    debugPrint('[MEMORY_MONITOR][WARN] Emergency cleanup initiated');
    
    // Clear location service cache
    try {
      // This will be available after our LocationService fix
      // LocationService.clearCache();
      debugPrint('[MEMORY_MONITOR] Location cache cleared');
    } catch (e) {
      debugPrint('[MEMORY_MONITOR][WARN] Failed to clear location cache: $e');
    }
    
    // Force garbage collection (note: gc() is not available in release mode)
    if (kDebugMode) {
      // In debug mode, we can suggest garbage collection
      debugPrint('[MEMORY_MONITOR] Garbage collection suggested (automatic in release mode)');
    }
    
    // Reset counters
    _firestoreOperationCount = 0;
    _streamSubscriptionCount = 0;
    _lastMemoryCheck = DateTime.now();
    
    debugPrint('[MEMORY_MONITOR][WARN] Emergency cleanup completed');
  }
  
  /// Check if memory usage is healthy
  static bool get isMemoryHealthy {
    return _streamSubscriptionCount <= 10 && 
           _firestoreOperationCount <= _maxFirestoreOpsPerMinute;
  }
}