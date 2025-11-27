import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

enum FileTypeCategory {
  pdf,
  word,
  excel,
  powerpoint,
  image,
  text,
  html,
  archive,
  audio,
  video,
  unknown,
}

class FileTypeUtils {
  static FileTypeCategory getFileCategory(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    final mimeType = lookupMimeType(filePath);

    // PDF
    if (extension == 'pdf' || mimeType == 'application/pdf') {
      return FileTypeCategory.pdf;
    }

    // Word Documents
    if (['doc', 'docx', 'docm', 'dot', 'dotx'].contains(extension) ||
        mimeType?.contains('msword') == true ||
        mimeType?.contains('wordprocessingml') == true) {
      return FileTypeCategory.word;
    }

    // Excel
    if (['xls', 'xlsx', 'xlsm', 'xlsb', 'csv'].contains(extension) ||
        mimeType?.contains('spreadsheetml') == true ||
        mimeType?.contains('ms-excel') == true) {
      return FileTypeCategory.excel;
    }

    // PowerPoint
    if (['ppt', 'pptx', 'pptm', 'pot', 'potx'].contains(extension) ||
        mimeType?.contains('presentationml') == true ||
        mimeType?.contains('ms-powerpoint') == true) {
      return FileTypeCategory.powerpoint;
    }

    // Images
    if ([
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'webp',
          'svg',
          'ico',
        ].contains(extension) ||
        mimeType?.startsWith('image/') == true) {
      return FileTypeCategory.image;
    }

    // Text Files
    if ([
          'txt',
          'md',
          'log',
          'json',
          'xml',
          'yaml',
          'yml',
          'ini',
          'conf',
        ].contains(extension) ||
        mimeType?.startsWith('text/') == true) {
      return FileTypeCategory.text;
    }

    // HTML
    if (extension == 'html' || extension == 'htm' || mimeType == 'text/html') {
      return FileTypeCategory.html;
    }

    // Archives
    if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].contains(extension) ||
        mimeType?.contains('zip') == true ||
        mimeType?.contains('rar') == true ||
        mimeType?.contains('7z') == true) {
      return FileTypeCategory.archive;
    }

    // Audio
    if ([
          'mp3',
          'wav',
          'aac',
          'ogg',
          'm4a',
          'flac',
          'wma',
        ].contains(extension) ||
        mimeType?.startsWith('audio/') == true) {
      return FileTypeCategory.audio;
    }

    // Video
    if ([
          'mp4',
          'avi',
          'mkv',
          'mov',
          'wmv',
          'flv',
          'webm',
          '3gp',
          'm4v',
        ].contains(extension) ||
        mimeType?.startsWith('video/') == true) {
      return FileTypeCategory.video;
    }

    return FileTypeCategory.unknown;
  }

  static String getFileTypeName(FileTypeCategory category) {
    switch (category) {
      case FileTypeCategory.pdf:
        return 'PDF';
      case FileTypeCategory.word:
        return 'Word Document';
      case FileTypeCategory.excel:
        return 'Excel Spreadsheet';
      case FileTypeCategory.powerpoint:
        return 'PowerPoint';
      case FileTypeCategory.image:
        return 'Image';
      case FileTypeCategory.text:
        return 'Text File';
      case FileTypeCategory.html:
        return 'HTML';
      case FileTypeCategory.archive:
        return 'Archive';
      case FileTypeCategory.audio:
        return 'Audio';
      case FileTypeCategory.video:
        return 'Video';
      case FileTypeCategory.unknown:
        return 'Unknown';
    }
  }

  static IconData getFileTypeIcon(FileTypeCategory category) {
    switch (category) {
      case FileTypeCategory.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileTypeCategory.word:
        return Icons.description_rounded;
      case FileTypeCategory.excel:
        return Icons.table_chart_rounded;
      case FileTypeCategory.powerpoint:
        return Icons.slideshow_rounded;
      case FileTypeCategory.image:
        return Icons.image_rounded;
      case FileTypeCategory.text:
        return Icons.text_snippet_rounded;
      case FileTypeCategory.html:
        return Icons.code_rounded;
      case FileTypeCategory.archive:
        return Icons.folder_zip_rounded;
      case FileTypeCategory.audio:
        return Icons.audiotrack_rounded;
      case FileTypeCategory.video:
        return Icons.videocam_rounded;
      case FileTypeCategory.unknown:
        return Icons.insert_drive_file_rounded;
    }
  }

  static List<Color> getFileTypeGradient(FileTypeCategory category) {
    switch (category) {
      case FileTypeCategory.pdf:
        return [const Color(0xFFF093FB), const Color(0xFFF5576C)];
      case FileTypeCategory.word:
        return [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
      case FileTypeCategory.excel:
        return [const Color(0xFF43E97B), const Color(0xFF38F9D7)];
      case FileTypeCategory.powerpoint:
        return [const Color(0xFFFA709A), const Color(0xFFFEE140)];
      case FileTypeCategory.image:
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case FileTypeCategory.text:
        return [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
      case FileTypeCategory.html:
        return [const Color(0xFF43E97B), const Color(0xFF38F9D7)];
      case FileTypeCategory.archive:
        return [const Color(0xFFF093FB), const Color(0xFFF5576C)];
      case FileTypeCategory.audio:
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case FileTypeCategory.video:
        return [const Color(0xFFFA709A), const Color(0xFFFEE140)];
      case FileTypeCategory.unknown:
        return [Colors.grey, Colors.grey.shade700];
    }
  }

  static bool canConvertToPdf(FileTypeCategory category) {
    return [
      FileTypeCategory.word,
      FileTypeCategory.excel,
      FileTypeCategory.powerpoint,
    ].contains(category);
  }
}
