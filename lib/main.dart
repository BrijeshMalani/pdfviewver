import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'bookmark_service.dart';
import 'recent_files_service.dart';
import 'home_screen.dart';
import 'pdf_viewer_page.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final bookmarkService = await BookmarkService.init();
  final recentFilesService = await RecentFilesService.init();

  runApp(
    MyApp(
      bookmarkService: bookmarkService,
      recentFilesService: recentFilesService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final BookmarkService bookmarkService;
  final RecentFilesService recentFilesService;

  const MyApp({
    Key? key,
    required this.bookmarkService,
    required this.recentFilesService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookmarkService>.value(value: bookmarkService),
        ChangeNotifierProvider<RecentFilesService>.value(
          value: recentFilesService,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Professional PDF Viewer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue.shade700,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue.shade300,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreenWrapper(),
      ),
    );
  }
}

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({Key? key}) : super(key: key);

  @override
  _HomeScreenWrapperState createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  static const platform = MethodChannel('com.pdfviewer/file_intent');

  @override
  void initState() {
    super.initState();
    _checkForInitialFile();
  }

  Future<void> _checkForInitialFile() async {
    try {
      // First try to get file path (works for most cases)
      final String? filePath = await platform.invokeMethod(
        'getInitialFilePath',
      );
      if (filePath != null && filePath.isNotEmpty && mounted) {
        // Wait a bit for the app to fully load
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _openFileFromIntent(filePath);
          return;
        }
      }

      // Fallback to URI if path not available
      final String? fileUri = await platform.invokeMethod('getInitialFileUri');
      if (fileUri != null && fileUri.isNotEmpty && mounted) {
        // Wait a bit for the app to fully load
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _openFileFromIntent(fileUri);
        }
      }
    } catch (e) {
      // Handle error silently
      print('Error getting initial file: $e');
    }
  }

  Future<void> _openFileFromIntent(String uri) async {
    try {
      // Handle content:// URIs first
      if (uri.startsWith('content://')) {
        final fileName = 'PDF Document';
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerPage(
                id: uri,
                isFile: false, // Content URIs are treated as network-like
                title: fileName,
              ),
            ),
          );
        }
        return;
      }

      // Handle file:// URIs and direct paths
      String filePath;
      if (uri.startsWith('file://')) {
        filePath = uri.replaceFirst('file://', '');
      } else {
        filePath = uri;
      }

      // Check if file exists
      final file = File(filePath);
      if (file.existsSync()) {
        final fileName = filePath.split('/').last.split('\\').last;

        // Add to recent files
        final recentFilesService = Provider.of<RecentFilesService>(
          context,
          listen: false,
        );
        await recentFilesService.addFile(filePath);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PdfViewerPage(id: filePath, isFile: true, title: fileName),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
