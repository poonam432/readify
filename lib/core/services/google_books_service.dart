import 'dart:convert';
import 'package:http/http.dart' as http;
import 'error_handler_service.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    try {
      // Search by both title and author
      // The query will search in title, author, and other fields
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}&maxResults=40');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        throw ErrorHandlerService.handleHttpError(response);
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ErrorHandlerService.handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> searchByTitleAndAuthor({
    String? title,
    String? author,
  }) async {
    try {
      // Build query with title and author parameters
      String query = '';
      if (title != null && title.trim().isNotEmpty) {
        query += 'intitle:${Uri.encodeComponent(title.trim())}';
      }
      if (author != null && author.trim().isNotEmpty) {
        if (query.isNotEmpty) {
          query += '+';
        }
        query += 'inauthor:${Uri.encodeComponent(author.trim())}';
      }
      
      if (query.isEmpty) {
        return [];
      }
      
      final uri = Uri.parse('$_baseUrl?q=$query&maxResults=40');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        throw ErrorHandlerService.handleHttpError(response);
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ErrorHandlerService.handleError(e);
    }
  }

  Future<Map<String, dynamic>?> searchByIsbn(String isbn) async {
    try {
      // Clean ISBN - remove any dashes or spaces
      final cleanIsbn = isbn.replaceAll(RegExp(r'[-\s]'), '');
      final uri = Uri.parse('$_baseUrl?q=isbn:$cleanIsbn');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          return items[0] as Map<String, dynamic>;
        }
        return null;
      } else if (response.statusCode == 404) {
        return null; // Book not found is not an error
      } else {
        throw ErrorHandlerService.handleHttpError(response);
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ErrorHandlerService.handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> searchByAuthor(String author) async {
    try {
      final uri = Uri.parse('$_baseUrl?q=inauthor:${Uri.encodeComponent(author)}&maxResults=20');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        throw ErrorHandlerService.handleHttpError(response);
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ErrorHandlerService.handleError(e);
    }
  }

  Future<Map<String, dynamic>?> getBookById(String bookId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$bookId');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 404) {
        return null; // Book not found is not an error
      } else {
        throw ErrorHandlerService.handleHttpError(response);
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ErrorHandlerService.handleError(e);
    }
  }
}

