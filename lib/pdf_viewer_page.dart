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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                Icons.navigation_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Jump to Page'),
          ],
        ),
        content: TextField(
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page number (1-$_totalPages)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.numbers_rounded),
            filled: true,
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
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_totalPages > 0)
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: Colors.white,
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
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded),
                  color: Colors.white,
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error Message
          if (_hasError)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Error Loading PDF',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667EEA),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous Page
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: Colors.white),
                  tooltip: 'Previous page',
                  onPressed: _currentPage > 1
                      ? () {
                          _pdfController?.previousPage();
                        }
                      : null,
                ),
              ),

              // Page Info & Jump
              GestureDetector(
                onTap: _showPageJumpDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Next Page
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                  tooltip: 'Next page',
                  onPressed: _currentPage < _totalPages
                      ? () {
                          _pdfController?.nextPage();
                        }
                      : null,
                ),
              ),

              // Zoom Out
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.zoom_out_rounded, color: Colors.white),
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
              ),

              // Reset Zoom
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.fit_screen_rounded, color: Colors.white),
                  tooltip: 'Fit to screen',
                  onPressed: () {
                    setState(() {
                      _zoomLevel = 1.0;
                    });
                    _pdfController?.zoomLevel = 1.0;
                  },
                ),
              ),

              // Zoom In
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.zoom_in_rounded, color: Colors.white),
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
