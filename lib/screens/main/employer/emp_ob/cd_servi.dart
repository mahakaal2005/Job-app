import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'package:cloudinary/cloudinary.dart';

class CloudinaryService {
  static final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String _apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static final String _apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  static final String _uploadPreset =
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';

  // Initialize Cloudinary SDK instance (lazy initialization)
  static Cloudinary? _cloudinary;
  
  static Cloudinary _getCloudinaryInstance() {
    if (_cloudinary == null) {
      _cloudinary = Cloudinary.signedConfig(
        apiKey: _apiKey,
        apiSecret: _apiSecret,
        cloudName: _cloudName,
      );
      print('🔧 [CLOUDINARY] SDK instance initialized');
    }
    return _cloudinary!;
  }

  /// Upload an image to Cloudinary
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('$_baseUrl/$_cloudName/image/upload');

      var request = http.MultipartRequest('POST', url);

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add upload parameters
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'company_images';
      request.fields['resource_type'] = 'image';

      // Generate timestamp and signature for authenticated upload
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = _apiKey;

      // Create signature
      final signature = _generateSignature({
        'folder': 'company_images',
        'timestamp': timestamp.toString(),
        'upload_preset': _uploadPreset,
      });
      request.fields['signature'] = signature;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String?;
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        print('Response: $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Upload a document (PDF, DOC, etc.) to Cloudinary
  /// Uses Cloudinary SDK for proper authentication and file handling
  static Future<String?> uploadDocument(File documentFile) async {
    try {
      print('🔧 [CLOUDINARY] Validating configuration...');
      
      if (_cloudName.isEmpty || _apiKey.isEmpty || _apiSecret.isEmpty) {
        print('❌ [CLOUDINARY] Configuration missing:');
        print('   Cloud Name: ${_cloudName.isEmpty ? 'MISSING' : 'OK'}');
        print('   API Key: ${_apiKey.isEmpty ? 'MISSING' : 'OK'}');
        print('   API Secret: ${_apiSecret.isEmpty ? 'MISSING' : 'OK'}');
        throw Exception('Cloudinary not configured. Check .env file.');
      }

      print('✅ [CLOUDINARY] Configuration validated');
      print('   Cloud Name: $_cloudName');
      print('   API Key: ${_apiKey.substring(0, 6)}...');

      // Get Cloudinary SDK instance (lazy initialization)
      final cloudinary = _getCloudinaryInstance();

      // Validate file exists and is accessible
      if (!await documentFile.exists()) {
        print('❌ [CLOUDINARY] File does not exist: ${documentFile.path}');
        throw Exception('File not found: ${documentFile.path}');
      }

      final fileSize = await documentFile.length();
      final fileName = documentFile.path.split('/').last;
      final fileExtension = fileName.contains('.') 
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '';
      
      print('📁 [CLOUDINARY] File validation:');
      print('   Path: ${documentFile.path}');
      print('   Name: $fileName');
      print('   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('   Extension: $fileExtension');
      print('   Exists: ${await documentFile.exists()}');

      // Generate unique public_id with timestamp and filename (with extension)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'resumes/${timestamp}_$fileName';
      
      print('📤 [CLOUDINARY] Starting upload using SDK...');
      print('   Public ID: $publicId');
      print('   Resource Type: raw');

      // Use Cloudinary SDK for upload (same as MediaUploadService)
      final response = await cloudinary.upload(
        file: documentFile.path,
        fileBytes: documentFile.readAsBytesSync(),
        resourceType: CloudinaryResourceType.raw, // Use 'raw' for documents
        folder: null,
        publicId: publicId,
        progressCallback: (count, total) {
          // Log progress at 25%, 50%, 75%, 100%
          final percentage = (count / total * 100).toInt();
          if (percentage % 25 == 0 || count == total) {
            print('   📊 Upload Progress: $percentage%');
          }
        },
      );

      if (response.isSuccessful) {
        String finalUrl = response.secureUrl ?? '';
        
        print('✅ [CLOUDINARY] Upload successful!');
        print('📊 [CLOUDINARY] Response data:');
        print('   secure_url: $finalUrl');
        print('   public_id: ${response.publicId}');
        print('   format: ${response.format}');
        print('   bytes: ${response.bytes}');
        print('   resource_type: ${response.resourceType}');

        // Ensure URL has the file extension (same logic as MediaUploadService)
        if (!finalUrl.endsWith(fileExtension) && fileExtension.isNotEmpty) {
          print('🔧 [CLOUDINARY] Reconstructing URL to include extension...');
          finalUrl = 'https://res.cloudinary.com/$_cloudName/raw/upload/$publicId';
          print('   New URL: $finalUrl');
        }

        print('🎉 [CLOUDINARY] Final upload result:');
        print('   URL: $finalUrl');
        print('   Public ID: ${response.publicId}');
        
        return finalUrl;
      } else {
        print('❌ [CLOUDINARY] Upload failed');
        print('   Error: ${response.error}');
        print('   Is Successful: ${response.isSuccessful}');
        
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ [CLOUDINARY] Exception during upload: $e');
      print('   Exception type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      
      // Provide more specific error information
      if (e.toString().contains('SocketException')) {
        print('   Network error: Check internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        print('   Timeout error: Request took too long');
      } else if (e.toString().contains('FormatException')) {
        print('   Format error: Invalid response format');
      } else if (e.toString().contains('FileSystemException')) {
        print('   File system error: Cannot access file');
      } else if (e.toString().contains('CloudinaryException')) {
        print('   Cloudinary service error: ${e.toString()}');
      }
      
      return null;
    }
  }

  /// Upload multiple files at once
  static Future<List<String?>> uploadMultipleFiles(List<File> files) async {
    List<String?> urls = [];

    for (File file in files) {
      String? url;
      if (_isImageFile(file)) {
        url = await uploadImage(file);
      } else {
        url = await uploadDocument(file);
      }
      urls.add(url);
    }

    return urls;
  }

  /// Delete a file from Cloudinary
  static Future<bool> deleteFile(String publicId) async {
    try {
      final url = Uri.parse('$_baseUrl/$_cloudName/image/destroy');

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create signature for deletion
      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'public_id': publicId,
          'timestamp': timestamp.toString(),
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      } else {
        print('Cloudinary delete failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting file from Cloudinary: $e');
      return false;
    }
  }

  /// Generate Cloudinary signature for authenticated requests
  static String _generateSignature(Map<String, String> params) {
    // Sort parameters alphabetically
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Create parameter string
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Add API secret
    final stringToSign = '$paramString$_apiSecret';

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  /// Check if file is an image based on extension
  static bool _isImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  /// Get optimized image URL with transformations
  static String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (originalUrl.isEmpty) return originalUrl;

    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      // Find the upload segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return originalUrl;

      // Build transformation string
      List<String> transformations = [];

      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('q_$quality');
      transformations.add('f_$format');

      if (transformations.isNotEmpty) {
        pathSegments.insert(uploadIndex + 1, transformations.join(','));
      }

      return uri.replace(pathSegments: pathSegments).toString();
    } catch (e) {
      print('Error optimizing image URL: $e');
      return originalUrl;
    }
  }

  /// Get thumbnail URL for images
  static String getThumbnailUrl(String originalUrl, {int size = 150}) {
    return getOptimizedImageUrl(
      originalUrl,
      width: size,
      height: size,
      quality: '80',
    );
  }

  /// Validate Cloudinary configuration
  static bool isConfigured() {
    return _cloudName.isNotEmpty &&
        _apiKey.isNotEmpty &&
        _apiSecret.isNotEmpty &&
        _uploadPreset.isNotEmpty;
  }

  /// Get file info from Cloudinary
  static Future<Map<String, dynamic>?> getFileInfo(String publicId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/$_cloudName/resources/image/upload/$publicId',
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      });

      final response = await http.get(
        url.replace(
          queryParameters: {
            'api_key': _apiKey,
            'timestamp': timestamp.toString(),
            'signature': signature,
          },
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to get file info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  /// Extract public ID from Cloudinary URL
  static String? extractPublicId(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;

      // Find the upload segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return null;

      // Get everything after upload (excluding transformations)
      final relevantSegments = pathSegments.skip(uploadIndex + 1).toList();

      // Remove transformations if present (they contain commas or start with specific prefixes)
      final cleanSegments =
          relevantSegments.where((segment) {
            return !segment.contains(',') &&
                !segment.startsWith('w_') &&
                !segment.startsWith('h_') &&
                !segment.startsWith('q_') &&
                !segment.startsWith('f_');
          }).toList();

      if (cleanSegments.isEmpty) return null;

      // Join remaining segments and remove file extension
      final publicIdWithExtension = cleanSegments.join('/');
      final lastDotIndex = publicIdWithExtension.lastIndexOf('.');

      if (lastDotIndex != -1) {
        return publicIdWithExtension.substring(0, lastDotIndex);
      }

      return publicIdWithExtension;
    } catch (e) {
      print('Error extracting public ID: $e');
      return null;
    }
  }
}
