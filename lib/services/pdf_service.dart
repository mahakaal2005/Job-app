import 'dart:io';
import 'dart:typed_data';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/emp_ob/cd_servi.dart';
import 'package:image/image.dart' as img;

class PDFService {
  /// Converts the first page of a PDF file to a PNG image
  /// Returns the path to the generated PNG file
  static Future<String?> convertFirstPageToPng(File pdfFile) async {
    try {
      // Verify file exists and is PDF
      if (!pdfFile.existsSync() ||
          !pdfFile.path.toLowerCase().endsWith('.pdf')) {
        print('Invalid PDF file: ${pdfFile.path}');
        return null;
      }

      // Load the PDF document
      final doc = await PdfDocument.openFile(pdfFile.path);
      if (doc.pages.isEmpty) {
        print('PDF has no pages');
        return null;
      }

      // Get the first page
      final page = doc.pages[0]; // Pages are 0-indexed in pdfrx

      // Calculate dimensions for a reasonable preview size
      // Target width of 800px while maintaining aspect ratio
      final targetWidth = 800;
      final scale = targetWidth / page.width;
      final targetHeight = (page.height * scale).toInt();

      // Render the page as an image
      final pageImage = await page.render(
        width: targetWidth,
        height: targetHeight,
        backgroundColor: Colors.white,
      );

      // Get the image data
      final bytes = pageImage?.pixels;
      if (bytes == null) {
        print('Failed to render PDF page to image');
        return null;
      }

      // Create a temporary file for the PNG
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/resume_preview_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Convert and compress the image
      try {
        // Convert RGBA to RGB and encode as PNG
        final image = img.Image.fromBytes(
          width: targetWidth,
          height: targetHeight,
          bytes: bytes.buffer,
          numChannels: 4,
        );

        // Convert to RGB format
        final rgbImage = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
        );

        // Encode as PNG with compression
        final compressedBytes = img.encodePng(
          rgbImage,
          level: 7, // Compression level 0-9
        );

        // Write the compressed image
        await tempFile.writeAsBytes(compressedBytes);

        print('PNG file size: ${await tempFile.length()} bytes');
      } catch (e) {
        print('Error compressing image: $e');
        // If compression fails, try direct bytes to PNG conversion
        final rawImage = img.Image.fromBytes(
          width: targetWidth,
          height: targetHeight,
          bytes: bytes.buffer,
          numChannels: 4,
        );
        final pngBytes = img.encodePng(rawImage);
        await tempFile.writeAsBytes(pngBytes);
      }

      // Clean up resources
      await doc.dispose();

      return tempFile.path;
    } catch (e, stackTrace) {
      print('Error converting PDF to PNG: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Uploads a resume PDF and returns both the PDF URL and preview PNG URL
  static Future<Map<String, String?>> uploadResumePDF(File pdfFile) async {
    try {
      // Verify file exists and is PDF
      if (!pdfFile.existsSync() ||
          !pdfFile.path.toLowerCase().endsWith('.pdf')) {
        throw Exception('Invalid PDF file: ${pdfFile.path}');
      }

      print('Starting PDF upload process...');

      // First upload the original PDF
      print('Uploading PDF file...');
      final pdfUrl = await CloudinaryService.uploadDocument(pdfFile);
      if (pdfUrl == null) {
        throw Exception('Failed to upload PDF to Cloudinary');
      }
      print('PDF uploaded successfully: $pdfUrl');

      // Then convert first page to PNG and upload it
      print('Converting first page to PNG...');
      String? previewUrl;
      final pngPath = await convertFirstPageToPng(pdfFile);

      if (pngPath != null) {
        final pngFile = File(pngPath);
        if (await pngFile.exists()) {
          print('PNG conversion successful, uploading preview...');
          print('PNG file size: ${await pngFile.length()} bytes');

          try {
            previewUrl = await CloudinaryService.uploadImage(pngFile);
            print('Preview uploaded successfully: $previewUrl');
          } catch (e) {
            print('Error uploading preview: $e');
            // Continue with PDF URL only
          }

          // Clean up temporary PNG file
          await pngFile.delete();
        } else {
          print('PNG file not found after conversion');
        }
      } else {
        print('Failed to convert PDF to PNG');
      }

      // Return both URLs - the PDF upload was successful even if preview failed
      return {'pdfUrl': pdfUrl, 'previewUrl': previewUrl};
    } catch (e, stackTrace) {
      print('Error uploading resume: $e');
      print('Stack trace: $stackTrace');
      return {'pdfUrl': null, 'previewUrl': null};
    }
  }
}
