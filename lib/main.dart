import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bookmark_service.dart';
import 'recent_files_service.dart';
import 'theme_service.dart';
import 'home_screen.dart';
import 'pdf_viewer_page.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'exit_dialog.dart';
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
  final themeService = ThemeService();

  runApp(
    MyApp(
      bookmarkService: bookmarkService,
      recentFilesService: recentFilesService,
      themeService: themeService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final BookmarkService bookmarkService;
  final RecentFilesService recentFilesService;
  final ThemeService themeService;

  const MyApp({
    Key? key,
    required this.bookmarkService,
    required this.recentFilesService,
    required this.themeService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookmarkService>.value(value: bookmarkService),
        ChangeNotifierProvider<RecentFilesService>.value(
          value: recentFilesService,
        ),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PDF Viewer',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF667EEA),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF667EEA),
                brightness: Brightness.light,
                primary: const Color(0xFF667EEA),
                secondary: const Color(0xFF764BA2),
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
                iconTheme: const IconThemeData(color: Colors.black87),
              ),
              cardTheme: CardThemeData(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.black.withOpacity(0.1),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF667EEA),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF667EEA),
                brightness: Brightness.dark,
                primary: const Color(0xFF667EEA),
                secondary: const Color(0xFF764BA2),
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              cardTheme: CardThemeData(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.black.withOpacity(0.3),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
            themeMode: themeService.themeMode,
            routes: {'/home': (context) => const HomeScreenWrapper()},
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _showSplash = true;
  bool _isOnboardingCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _isOnboardingCompleted = completed;
      _isLoading = false;
    });
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showSplash) {
      return SplashScreen(onAnimationComplete: _onSplashComplete);
    }

    if (!_isOnboardingCompleted) {
      return const OnboardingScreen();
    }

    return const HomeScreenWrapper();
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
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await ExitDialog.show(context);
        return shouldExit ?? false;
      },
      child: const HomeScreen(),
    );
  }
}
