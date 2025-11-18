import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import 'bookmark_service.dart';
import 'recent_files_service.dart';

class PdfViewerPage extends StatefulWidget {
  final String id; // url or file path
  final bool isFile;
  final String title;

  const PdfViewerPage({
    Key? key,
    required this.id,
    required this.isFile,
    required this.title,
  }) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfViewerController? _pdfController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  bool _showControls = true;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _checkBookmarkStatus();
    if (widget.isFile) {
      _addToRecentFiles();
    }
  }

  void _checkBookmarkStatus() {
    final bookmarkService = Provider.of<BookmarkService>(
      context,
      listen: false,
    );
    setState(() {
      _isBookmarked = bookmarkService.isBookmarked(widget.id);
    });
  }

  Future<void> _addToRecentFiles() async {
    final recentFilesService = Provider.of<RecentFilesService>(
      context,
      listen: false,
    );
    await recentFilesService.addFile(widget.id);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showPageJumpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Page number (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= _totalPages) {
              _pdfController?.jumpToPage(page);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please enter a valid page number (1-$_totalPages)',
                  ),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkService = Provider.of<BookmarkService>(context);

    return Scaffold(
      appBar: _showControls
          ? AppBar(
              title: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_totalPages > 0)
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                  onPressed: () {
                    setState(() {
                      if (_isBookmarked) {
                        bookmarkService.remove(widget.id);
                        _isBookmarked = false;
                      } else {
                        bookmarkService.add(widget.id);
                        _isBookmarked = true;
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isBookmarked ? 'Bookmark added' : 'Bookmark removed',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit),
                  tooltip: 'Hide controls',
                  onPressed: _toggleControls,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // PDF Viewer
          widget.isFile ? _buildFileViewer() : _buildNetworkViewer(),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDF...'),
                  ],
                ),
              ),
            ),

          // Error Message
          if (_hasError)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading PDF',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isLoading = true;
                          });
                          _pdfController = PdfViewerController();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Controls Overlay
          if (_showControls && !_isLoading && !_hasError)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildControls()),

          // Tap to show/hide controls
          if (!_isLoading && !_hasError)
            GestureDetector(
              onTap: _toggleControls,
              child: Container(color: Colors.transparent),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous Page
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                tooltip: 'Previous page',
                onPressed: _currentPage > 1
                    ? () {
                        _pdfController?.previousPage();
                      }
                    : null,
              ),

              // Page Info & Jump
              GestureDetector(
                onTap: _showPageJumpDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Next Page
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                tooltip: 'Next page',
                onPressed: _currentPage < _totalPages
                    ? () {
                        _pdfController?.nextPage();
                      }
                    : null,
              ),

              // Zoom Out
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white),
                tooltip: 'Zoom out',
                onPressed: () {
                  if (_zoomLevel > 0.5) {
                    setState(() {
                      _zoomLevel -= 0.25;
                    });
                    _pdfController?.zoomLevel = _zoomLevel;
                  }
                },
              ),

              // Reset Zoom
              IconButton(
                icon: const Icon(Icons.fit_screen, color: Colors.white),
                tooltip: 'Fit to screen',
                onPressed: () {
                  setState(() {
                    _zoomLevel = 1.0;
                  });
                  _pdfController?.zoomLevel = 1.0;
                },
              ),

              // Zoom In
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white),
                tooltip: 'Zoom in',
                onPressed: () {
                  if (_zoomLevel < 3.0) {
                    setState(() {
                      _zoomLevel += 0.25;
                    });
                    _pdfController?.zoomLevel = _zoomLevel;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkViewer() {
    return SfPdfViewer.network(
      widget.id,
      controller: _pdfController,
      onDocumentLoaded: (details) {
        setState(() {
          _isLoading = false;
          _totalPages = details.document.pages.count;
          _currentPage = 1;
        });
      },
      onDocumentLoadFailed: (args) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              args.error?.toString() ?? 'Failed to load PDF from network';
        });
      },
      onPageChanged: (details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      enableDoubleTapZooming: true,
      enableTextSelection: true,
    );
  }

  Widget _buildFileViewer() {
    final file = File(widget.id);
    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'File not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.id,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.file(
      file,
      controller: _pdfController,
      onDocumentLoaded: (details) {
        setState(() {
          _isLoading = false;
          _totalPages = details.document.pages.count;
          _currentPage = 1;
        });
      },
      onDocumentLoadFailed: (args) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = args.error?.toString() ?? 'Failed to load PDF file';
        });
      },
      onPageChanged: (details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      enableDoubleTapZooming: true,
      enableTextSelection: true,
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }
}
