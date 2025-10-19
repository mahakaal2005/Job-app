import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MediaUploadService {
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
      final response = await _cloudinary.upload(
        file: filePath,
        fileBytes: File(filePath).readAsBytesSync(),
        resourceType: CloudinaryResourceType.raw,
        folder: 'chat_documents',
        fileName: fileName,
        progressCallback: (count, total) {
          print('Uploading document: ${(count / total * 100).toStringAsFixed(2)}%');
        },
      );

      if (response.isSuccessful) {
        return {
          'url': response.secureUrl,
          'publicId': response.publicId,
          'format': response.format,
          'size': response.bytes,
        };
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
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
