import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkedArticle {
  final String title;
  final String langCode;

  BookmarkedArticle({required this.title, required this.langCode});

  Map<String, String> toMap() => {'title': title, 'langCode': langCode};
  factory BookmarkedArticle.fromMap(Map<String, dynamic> map) => 
      BookmarkedArticle(title: map['title']!, langCode: map['langCode']!);
}

class BookmarksNotifier extends StateNotifier<List<BookmarkedArticle>> {
  BookmarksNotifier() : super([]) {
    _loadBookmarks();
  }

  static const _key = 'bookmarked_articles';

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_key);
    if (jsonList != null) {
      state = jsonList
          .map((item) => BookmarkedArticle.fromMap(json.decode(item)))
          .toList();
    }
  }

  Future<void> toggleBookmark(String title, String langCode) async {
    final isBookmarked = state.any((b) => b.title == title && b.langCode == langCode);
    
    if (isBookmarked) {
      state = state.where((b) => !(b.title == title && b.langCode == langCode)).toList();
    } else {
      state = [...state, BookmarkedArticle(title: title, langCode: langCode)];
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  bool isBookmarked(String title, String langCode) {
    return state.any((b) => b.title == title && b.langCode == langCode);
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<BookmarkedArticle>>((ref) {
  return BookmarksNotifier();
});
