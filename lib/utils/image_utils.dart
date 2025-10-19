import 'dart:io';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Creates an appropriate ImageProvider based on the image path/URL
  /// Handles both network URLs (http/https) and local file paths
  /// Returns null if the path is null or empty
  static ImageProvider? getImageProvider(String? imagePath, {bool silent = false}) {
    if (imagePath == null || imagePath.isEmpty) {
      // Only log if not silent mode
      if (!silent) {
        debugPrint('ImageUtils: Empty or null image path provided');
      }
      return null;
    }

    try {
      // Check if it's a network URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return NetworkImage(imagePath);
      } 
      // Check if it's a local file path
      else if (imagePath.startsWith('/') || imagePath.contains('cache') || imagePath.contains('files')) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          if (!silent) {
            debugPrint('ImageUtils: Local file does not exist: $imagePath');
          }
          return null;
        }
      }
      // Fallback: assume it's a network URL if it doesn't look like a local path
      else {
        return NetworkImage(imagePath);
      }
    } catch (e) {
      if (!silent) {
        debugPrint('ImageUtils: Error processing image path: $e');
      }
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
    bool silent = true,
  }) {
    final imageProvider = getImageProvider(imagePath, silent: silent);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null 
          ? (exception, stackTrace) {
              // Silently handle error - don't spam console
              if (onBackgroundImageError != null) {
                onBackgroundImageError();
              }
            }
          : null,
      child: child,
    );
  }

  /// Creates a safe Image.network widget with proper error handling
  static Widget buildSafeNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? _buildDefaultErrorWidget(width, height);
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return loadingWidget ?? 
          Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) {
        // Silently handle error - don't spam console
        return errorWidget ?? _buildDefaultErrorWidget(width, height);
      },
    );
  }

  static Widget _buildDefaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: (width != null && height != null) ? (width < height ? width : height) * 0.5 : 24,
        color: Colors.grey[600],
      ),
    );
  }
}