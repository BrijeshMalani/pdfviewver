import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ArchiveViewer extends StatefulWidget {
  final String filePath;
  final String title;

  const ArchiveViewer({Key? key, required this.filePath, required this.title})
    : super(key: key);

  @override
  _ArchiveViewerState createState() => _ArchiveViewerState();
}

class _ArchiveViewerState extends State<ArchiveViewer> {
  List<ArchiveFile> _files = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'File not found';
          _isLoading = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
      Archive archive;

      if (widget.filePath.toLowerCase().endsWith('.zip')) {
        archive = ZipDecoder().decodeBytes(bytes);
      } else if (widget.filePath.toLowerCase().endsWith('.rar')) {
        // RAR support is limited, show message
        setState(() {
          _hasError = true;
          _errorMessage =
              'RAR files are not fully supported. Please extract using another app.';
          _isLoading = false;
        });
        return;
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Unsupported archive format';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _files = archive.files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading archive: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _extractFile(ArchiveFile archiveFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final extractPath = path.join(tempDir.path, archiveFile.name);
      final file = File(extractPath);

      // Create directory if needed
      await file.parent.create(recursive: true);

      await file.writeAsBytes(archiveFile.content as List<int>);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extracted to: $extractPath'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Icons.image_rounded;
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['txt', 'md'].contains(ext)) return Icons.text_snippet_rounded;
    if (['mp4', 'avi'].contains(ext)) return Icons.videocam_rounded;
    if (['mp3', 'wav'].contains(ext)) return Icons.audiotrack_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Error loading archive',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _files.isEmpty
          ? Center(
              child: Text(
                'Archive is empty',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667EEA),
                            const Color(0xFF764BA2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getFileIcon(file.name),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      file.name.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${_formatFileSize(file.size)} • ${file.isFile ? "File" : "Folder"}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    trailing: file.isFile
                        ? IconButton(
                            icon: const Icon(Icons.download_rounded),
                            onPressed: () => _extractFile(file),
                            tooltip: 'Extract',
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
