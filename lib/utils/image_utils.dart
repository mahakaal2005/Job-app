import 'dart:io';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Creates an appropriate ImageProvider based on the image path/URL
  /// Handles both network URLs (http/https) and local file paths
  /// Returns null if the path is null or empty
  static ImageProvider? getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      debugPrint('ImageUtils: Empty or null image path provided');
      return null;
    }

    debugPrint('ImageUtils: Processing image path: $imagePath');

    try {
      // Check if it's a network URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        debugPrint('ImageUtils: Using NetworkImage for URL: $imagePath');
        return NetworkImage(imagePath);
      } 
      // Check if it's a local file path
      else if (imagePath.startsWith('/') || imagePath.contains('cache') || imagePath.contains('files')) {
        debugPrint('ImageUtils: Using FileImage for local path: $imagePath');
        final file = File(imagePath);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          debugPrint('ImageUtils: Local file does not exist: $imagePath');
          return null;
        }
      }
      // Fallback: assume it's a network URL if it doesn't look like a local path
      else {
        debugPrint('ImageUtils: Fallback to NetworkImage for: $imagePath');
        return NetworkImage(imagePath);
      }
    } catch (e) {
      debugPrint('ImageUtils: Error processing image path: $imagePath, Error: $e');
      return null;
    }
  }

  /// Creates a safe CircleAvatar with proper error handling
  static Widget buildSafeCircleAvatar({
    required double radius,
    String? imagePath,
    Color? backgroundColor,
    Widget? child,
    VoidCallback? onBackgroundImageError,
  }) {
    final imageProvider = getImageProvider(imagePath);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null 
          ? (onBackgroundImageError != null 
              ? (exception, stackTrace) {
                  debugPrint('CircleAvatar image error: $exception');
                  debugPrint('Image path was: $imagePath');
                  onBackgroundImageError();
                }
              : (exception, stackTrace) {
                  debugPrint('CircleAvatar image error: $exception');
                  debugPrint('Image path was: $imagePath');
                })
          : null, // Don't set error handler if no image
      child: child,
    );
  }
}