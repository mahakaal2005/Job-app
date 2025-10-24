import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/cd_servi.dart';
import 'package:image/image.dart' as img;
// Note: flutter_pdfview doesn't have PDF to image conversion capabilities
// We'll need to use a different approach for PDF preview generation

class PDFService {
  /// Since flutter_pdfview doesn't support PDF to image conversion,
  /// we'll create a simpler solution for PDF preview
  static Future<String?> createPDFPreview(File pdfFile) async {
    try {
      // Verify file exists and is PDF
      if (!pdfFile.existsSync() ||
          !pdfFile.path.toLowerCase().endsWith('.pdf')) {
        print('Invalid PDF file: ${pdfFile.path}');
        return null;
      }

      // Create a placeholder image for PDF preview
      // This is a temporary solution since flutter_pdfview doesn't support image conversion
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/resume_preview_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Create a simple placeholder image
      final image = img.Image(width: 400, height: 600);
      img.fill(image, color: img.ColorRgb8(255, 255, 255)); // White background

      // Add some text to indicate it's a PDF
      img.drawString(image, 'PDF Document', font: img.arial24,
          x: 50, y: 50, color: img.ColorRgb8(0, 0, 0));
      img.drawString(image, 'Preview not available', font: img.arial14,
          x: 50, y: 80, color: img.ColorRgb8(100, 100, 100));

      final pngBytes = img.encodePng(image);
      await tempFile.writeAsBytes(pngBytes);

      print('PDF preview placeholder created: ${tempFile.path}');
      return tempFile.path;
    } catch (e, stackTrace) {
      print('Error creating PDF preview: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Alternative method: Just return the PDF file info without conversion
  static Future<Map<String, dynamic>> getPDFInfo(File pdfFile) async {
    try {
      if (!pdfFile.existsSync() ||
          !pdfFile.path.toLowerCase().endsWith('.pdf')) {
        throw Exception('Invalid PDF file: ${pdfFile.path}');
      }

      final fileSize = await pdfFile.length();
      final fileName = pdfFile.path.split('/').last;

      return {
        'fileName': fileName,
        'fileSize': fileSize,
        'filePath': pdfFile.path,
        'hasPreview': false, // No preview available with flutter_pdfview
      };
    } catch (e) {
      print('Error getting PDF info: $e');
      return {};
    }
  }

  /// Uploads a resume PDF and generates preview using Cloudinary's built-in PDF to image conversion
  static Future<Map<String, String?>> uploadResumePDF(File pdfFile) async {
    try {
      // Verify file exists and is PDF
      if (!pdfFile.existsSync() ||
          !pdfFile.path.toLowerCase().endsWith('.pdf')) {
        throw Exception('Invalid PDF file: ${pdfFile.path}');
      }

      print('📄 [PDF SERVICE] Starting PDF upload process...');
      print('   File: ${pdfFile.path}');
      print('   Size: ${await pdfFile.length()} bytes');

      // Upload the original PDF to Cloudinary (now uses /raw/upload with proper extension)
      print('📤 [PDF SERVICE] Uploading PDF file to Cloudinary...');
      final pdfUrl = await CloudinaryService.uploadDocument(pdfFile);
      if (pdfUrl == null) {
        throw Exception('Failed to upload PDF to Cloudinary');
      }
      print('✅ [PDF SERVICE] PDF uploaded successfully: $pdfUrl');

      // Generate preview URL for thumbnail display
      String? previewUrl;
      
      try {
        // Extract public ID and cloud name from the PDF URL
        final publicId = CloudinaryService.extractPublicId(pdfUrl);
        final cloudName = pdfUrl.split('/')[3];
        
        if (publicId != null) {
          // Generate preview URL by converting PDF first page to JPG
          // This works because Cloudinary can convert PDFs to images on-the-fly
          previewUrl = 'https://res.cloudinary.com/$cloudName/image/upload/pg_1,w_800,h_1000,c_fit,q_auto/$publicId.jpg';
          
          print('✅ [PDF SERVICE] Preview URL generated: $previewUrl');
        } else {
          print('⚠️ [PDF SERVICE] Could not extract public ID from PDF URL');
        }
      } catch (e) {
        print('⚠️ [PDF SERVICE] Error generating preview URL: $e');
      }

      print('🎉 [PDF SERVICE] Upload complete!');
      print('   PDF URL (for sharing/opening): $pdfUrl');
      print('   Preview URL (for thumbnail): $previewUrl');
      
      // Return the raw PDF URL (now has proper .pdf extension) and preview URL
      return {
        'pdfUrl': pdfUrl, // This now has .pdf extension and will open correctly
        'previewUrl': previewUrl
      };
    } catch (e, stackTrace) {
      print('❌ [PDF SERVICE] Error uploading resume: $e');
      print('Stack trace: $stackTrace');
      return {'pdfUrl': null, 'previewUrl': null};
    }
  }

  /// Method to display PDF using flutter_pdfview
  static Widget createPDFViewer(String pdfPath) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: Container(
        child: const Center(
          child: Text('PDF Viewer would go here\n'
              'Use flutter_pdfview PDFView widget\n'
              'when you need to display the PDF'),
        ),
      ),
    );
  }
}

// Example of how to use flutter_pdfview in a widget
class PDFViewerWidget extends StatelessWidget {
  final String pdfPath;

  const PDFViewerWidget({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: Container(
        child: const Center(
          child: Text(
            'To implement PDF viewing:\n\n'
                '1. Import: import \'package:flutter_pdfview/flutter_pdfview.dart\';\n\n'
                '2. Use PDFView widget:\n'
                'PDFView(\n'
                '  filePath: pdfPath,\n'
                '  enableSwipe: true,\n'
                '  swipeHorizontal: false,\n'
                '  autoSpacing: false,\n'
                '  pageFling: false,\n'
                '  onRender: (pages) { /* handle render */ },\n'
                '  onError: (error) { /* handle error */ },\n'
                ')',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}