import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../modules/book_search/entities/book.dart';

class BookCacheService {
  static const String _cacheKey = 'cached_books';
  static const int _maxCacheSize = 500; // Maximum number of books to cache

  Future<void> cacheBook(Book book) async {
    try {
      final cachedBooks = await getCachedBooks();
      
      // Remove existing book with same ID if present
      cachedBooks.removeWhere((b) => b.id == book.id);
      
      // Add new book at the beginning
      cachedBooks.insert(0, book);
      
      // Limit cache size
      if (cachedBooks.length > _maxCacheSize) {
        cachedBooks.removeRange(_maxCacheSize, cachedBooks.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final booksJson = cachedBooks.map((b) => _bookToJson(b)).toList();
      await prefs.setString(_cacheKey, json.encode(booksJson));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> cacheBooks(List<Book> books) async {
    try {
      for (final book in books) {
        await cacheBook(book);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Book>> getCachedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_cacheKey);
      
      if (booksJson != null) {
        final List<dynamic> booksList = json.decode(booksJson);
        return booksList.map((json) => _bookFromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      // Handle error silently
    }
  }

  Map<String, dynamic> _bookToJson(Book book) {
    return {
      'id': book.id,
      'title': book.title,
      'subtitle': book.subtitle,
      'authors': book.authors,
      'description': book.description,
      'publisher': book.publisher,
      'publishedDate': book.publishedDate,
      'pageCount': book.pageCount,
      'categories': book.categories,
      'thumbnailUrl': book.thumbnailUrl,
      'previewLink': book.previewLink,
      'infoLink': book.infoLink,
      'language': book.language,
      'averageRating': book.averageRating,
      'ratingsCount': book.ratingsCount,
      'isbn10': book.isbn10,
      'isbn13': book.isbn13,
    };
  }

  Book _bookFromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      authors: (json['authors'] as List?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int?,
      categories: (json['categories'] as List?)?.cast<String>(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      previewLink: json['previewLink'] as String?,
      infoLink: json['infoLink'] as String?,
      language: json['language'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      ratingsCount: json['ratingsCount'] as int?,
      isbn10: json['isbn10'] as String?,
      isbn13: json['isbn13'] as String?,
    );
  }
}


