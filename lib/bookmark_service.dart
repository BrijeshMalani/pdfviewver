import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService extends ChangeNotifier {
  static const _key = 'bookmarked_pdfs';
  final SharedPreferences _prefs;
  List<String> _bookmarks = [];

  BookmarkService._(this._prefs) {
    _bookmarks = _prefs.getStringList(_key) ?? [];
  }

  static Future<BookmarkService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return BookmarkService._(prefs);
  }

  List<String> get bookmarks => List.unmodifiable(_bookmarks);

  bool isBookmarked(String id) => _bookmarks.contains(id);

  Future<void> add(String id) async {
    if (!_bookmarks.contains(id)) {
      _bookmarks.add(id);
      await _prefs.setStringList(_key, _bookmarks);
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    if (_bookmarks.contains(id)) {
      _bookmarks.remove(id);
      await _prefs.setStringList(_key, _bookmarks);
      notifyListeners();
    }
  }
}
