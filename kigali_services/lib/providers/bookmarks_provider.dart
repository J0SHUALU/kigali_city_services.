import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksProvider extends ChangeNotifier {
  List<String> _bookmarks = [];
  List<String> get bookmarks => _bookmarks;

  BookmarksProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarks = prefs.getStringList('bookmarks') ?? [];
    notifyListeners();
  }

  Future<void> toggle(String serviceId) async {
    if (_bookmarks.contains(serviceId)) {
      _bookmarks.remove(serviceId);
    } else {
      _bookmarks.add(serviceId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', _bookmarks);
    notifyListeners();
  }

  bool isBookmarked(String serviceId) => _bookmarks.contains(serviceId);
}
