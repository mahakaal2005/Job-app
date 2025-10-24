import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MediaUploadService {
  // Helper function to format file size
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
  late final Cloudinary _cloudinary;

  MediaUploadService() {
    _cloudinary = Cloudinary.signedConfig(
      apiKey: dotenv.env['CLOUDINARY_API_KEY'] ?? '',
      apiSecret: dotenv.env['CLOUDINARY_API_SECRET'] ?? '',
      cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '',
    );
  }

  // Upload image to Cloudinary
  Future<Map<String, dynamic>> uploadImage(String filePath) async {
    try {
      final response = await _cloudinary.upload(
        file: filePath,
        fileBytes: File(filePath).readAsBytesSync(),
        resourceType: CloudinaryResourceType.image,
        folder: 'chat_images',
        progressCallback: (count, total) {
          print('Uploading image: ${(count / total * 100).toStringAsFixed(2)}%');
        },
      );

      if (response.isSuccessful) {
        return {
          'url': response.secureUrl,
          'publicId': response.publicId,
          'format': response.format,
          'width': response.width,
          'height': response.height,
          'size': response.bytes,
        };
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Upload document to Cloudinary
  Future<Map<String, dynamic>> uploadDocument(String filePath, String fileName) async {
    try {
      print('📤 [UPLOAD] Starting document upload: $fileName');
      
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist at path: $filePath');
      }
      
      final fileSize = await file.length();
      
      // Extract file extension from fileName
      final fileExtension = fileName.contains('.') 
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '';
      
      if (fileExtension.isEmpty) {
        print('⚠️ [WARNING] No file extension found in fileName!');
      }
      
      // Generate unique public_id with timestamp and original filename (with extension)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'chat_documents/${timestamp}_$fileName';
      
      print('   Public ID: $publicId');
      print('   Size: ${formatFileSize(fileSize)}');
      
      final response = await _cloudinary.upload(
        file: filePath,
        fileBytes: File(filePath).readAsBytesSync(),
        resourceType: CloudinaryResourceType.raw, // Use 'raw' for all documents
        folder: null,
        publicId: publicId,
        progressCallback: (count, total) {
          // Only log at 25%, 50%, 75%, 100%
          final percentage = (count / total * 100).toInt();
          if (percentage % 25 == 0 || count == total) {
            print('   Progress: $percentage%');
          }
        },
      );

      if (response.isSuccessful) {
        String finalUrl = response.secureUrl ?? '';
        
        // Ensure URL has the file extension
        if (!finalUrl.endsWith(fileExtension) && fileExtension.isNotEmpty) {
          final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
          finalUrl = 'https://res.cloudinary.com/$cloudName/raw/upload/$publicId';
          print('   ✅ URL reconstructed with extension');
        }
        
        print('✅ [SUCCESS] Document uploaded: $finalUrl');
        
        return {
          'url': finalUrl,
          'publicId': response.publicId ?? publicId,
          'format': response.format ?? fileExtension.replaceAll('.', ''),
          'size': response.bytes ?? fileSize,
          'fileName': fileName,
        };
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      print('❌ [ERROR] Upload failed: $e');
      throw Exception('Error uploading document: $e');
    }
  }

  // Delete file from Cloudinary
  Future<bool> deleteFile(String publicId, CloudinaryResourceType resourceType) async {
    try {
      final response = await _cloudinary.destroy(
        publicId,
        resourceType: resourceType,
      );
      return response.isSuccessful;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}
