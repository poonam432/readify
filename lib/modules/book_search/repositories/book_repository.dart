import '../entities/book.dart';

abstract class BookRepository {
  Future<List<Book>> searchBooks(String query);
  Future<List<Book>> searchByTitleAndAuthor({String? title, String? author});
  Future<Book?> searchByIsbn(String isbn);
  Future<List<Book>> searchByAuthor(String author);
}

