import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class RecentFile {
  final String path;
  final String name;
  final DateTime lastOpened;

  RecentFile({
    required this.path,
    required this.name,
    required this.lastOpened,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'lastOpened': lastOpened.toIso8601String(),
      };

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        path: json['path'],
        name: json['name'],
        lastOpened: DateTime.parse(json['lastOpened']),
      );
}

class RecentFilesService extends ChangeNotifier {
  static const _key = 'recent_files';
  final SharedPreferences _prefs;
  List<RecentFile> _recentFiles = [];
  static const int maxRecentFiles = 10;

  RecentFilesService._(this._prefs) {
    _loadRecentFiles();
  }

  static Future<RecentFilesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return RecentFilesService._(prefs);
  }

  void _loadRecentFiles() {
    try {
      final jsonList = _prefs.getStringList(_key) ?? [];
      _recentFiles = jsonList
          .map((json) {
            try {
              final parts = json.split('|');
              if (parts.length >= 3) {
                return RecentFile.fromJson({
                  'path': parts[0],
                  'name': parts[1],
                  'lastOpened': parts[2],
                });
              }
            } catch (e) {
              // Skip invalid entries
            }
            return null;
          })
          .whereType<RecentFile>()
          .toList();
      _recentFiles.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    } catch (e) {
      _recentFiles = [];
    }
    notifyListeners();
  }

  Future<void> _saveRecentFiles() async {
    final jsonList = _recentFiles
        .map((file) =>
            '${file.path}|${file.name}|${file.lastOpened.toIso8601String()}')
        .toList();
    await _prefs.setStringList(_key, jsonList);
  }

  List<RecentFile> get recentFiles => List.unmodifiable(_recentFiles);

  Future<void> addFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    final fileName = path.split('/').last.split('\\').last;
    
    // Remove if already exists
    _recentFiles.removeWhere((f) => f.path == path);
    
    // Add to beginning
    _recentFiles.insert(0, RecentFile(
      path: path,
      name: fileName,
      lastOpened: DateTime.now(),
    ));

    // Keep only maxRecentFiles
    if (_recentFiles.length > maxRecentFiles) {
      _recentFiles = _recentFiles.take(maxRecentFiles).toList();
    }

    await _saveRecentFiles();
    notifyListeners();
  }

  Future<void> removeFile(String path) async {
    _recentFiles.removeWhere((f) => f.path == path);
    await _saveRecentFiles();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _recentFiles.clear();
    await _saveRecentFiles();
    notifyListeners();
  }
}

