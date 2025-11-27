import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/file_type_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileConverter {
  static Future<String?> convertToPdf(
    String filePath,
    FileTypeCategory fileType,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return null;
      }

      final pdfDocument = PdfDocument();
      final page = pdfDocument.pages.add();

      switch (fileType) {
        case FileTypeCategory.word:
        case FileTypeCategory.excel:
        case FileTypeCategory.powerpoint:
          // For Office files, we'll create a PDF with file info
          // Note: Full conversion requires backend or native libraries
          // This is a workaround that creates a PDF with file content info
          final graphics = page.graphics;
          final font = PdfStandardFont(PdfFontFamily.helvetica, 12);

          graphics.drawString(
            'File: ${path.basename(filePath)}',
            font,
            bounds: const Rect.fromLTWH(50, 50, 500, 30),
          );

          graphics.drawString(
            'Type: ${FileTypeUtils.getFileTypeName(fileType)}',
            font,
            bounds: const Rect.fromLTWH(50, 100, 500, 30),
          );

          graphics.drawString(
            'Note: Full conversion requires opening the file in its native app.',
            PdfStandardFont(PdfFontFamily.helvetica, 10),
            bounds: const Rect.fromLTWH(50, 150, 500, 30),
          );
          break;
        default:
          return null;
      }

      // Save PDF to temp directory
      final tempDir = await getTemporaryDirectory();
      final pdfPath = path.join(
        tempDir.path,
        '${path.basenameWithoutExtension(filePath)}.pdf',
      );

      final pdfBytes = await pdfDocument.save();
      await File(pdfPath).writeAsBytes(pdfBytes);
      pdfDocument.dispose();

      return pdfPath;
    } catch (e) {
      return null;
    }
  }

  static Future<void> showConversionDialog(
    BuildContext context,
    String filePath,
    FileTypeCategory fileType,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Convert to PDF'),
          ],
        ),
        content: const Text(
          'Full Office file conversion requires opening the file in its native app. '
          'Would you like to open this file with an external app that can convert it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open with external app
              // You can use open_filex package here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open with App'),
          ),
        ],
      ),
    );
  }
}
