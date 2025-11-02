import 'book_repository.dart';
import '../entities/book.dart';
import '../../../core/services/google_books_service.dart';

class BookRepositoryImpl implements BookRepository {
  final GoogleBooksService _googleBooksService;

  BookRepositoryImpl(this._googleBooksService);

  @override
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final results = await _googleBooksService.searchBooks(query);
    return results.map((json) => Book.fromJson(json)).toList();
  }

  @override
  Future<Book?> searchByIsbn(String isbn) async {
    if (isbn.isEmpty) {
      return null;
    }
    final result = await _googleBooksService.searchByIsbn(isbn);
    if (result != null) {
      return Book.fromJson(result);
    }
    return null;
  }

  @override
  Future<List<Book>> searchByTitleAndAuthor({String? title, String? author}) async {
    final results = await _googleBooksService.searchByTitleAndAuthor(
      title: title,
      author: author,
    );
    return results.map((json) => Book.fromJson(json)).toList();
  }

  @override
  Future<List<Book>> searchByAuthor(String author) async {
    if (author.isEmpty) {
      return [];
    }
    final results = await _googleBooksService.searchByAuthor(author);
    return results.map((json) => Book.fromJson(json)).toList();
  }
}

