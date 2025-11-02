import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/book_repository.dart';
import 'book_search_event.dart';
import 'book_search_state.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/book_cache_service.dart';
import '../../../core/services/error_handler_service.dart';

class BookSearchBloc extends Bloc<BookSearchEvent, BookSearchState> {
  BookSearchBloc(this._repository) : super(const BookSearchInitial()) {
    on<SearchBooksEvent>(_onSearchBooks);
    on<SearchByIsbnEvent>(_onSearchByIsbn);
    on<SearchByAuthorEvent>(_onSearchByAuthor);
    on<ClearSearchEvent>(_onClearSearch);
  }

  final BookRepository _repository;
  final BookCacheService _cacheService = getIt<BookCacheService>();

  Future<void> _onSearchBooks(
    SearchBooksEvent event,
    Emitter<BookSearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const BookSearchSuccess([]));
      return;
    }
    emit(const BookSearchLoading());
    try {
      final books = await _repository.searchBooks(event.query);
      // Cache books for analytics
      await _cacheService.cacheBooks(books);
      emit(BookSearchSuccess(books));
    } catch (e) {
      final userMessage = ErrorHandlerService.getUserFriendlyMessage(e);
      emit(BookSearchError(userMessage));
    }
  }

  Future<void> _onSearchByIsbn(
    SearchByIsbnEvent event,
    Emitter<BookSearchState> emit,
  ) async {
    if (event.isbn.isEmpty) {
      emit(const BookSearchSuccess([]));
      return;
    }
    emit(const BookSearchLoading());
    try {
      final book = await _repository.searchByIsbn(event.isbn);
      if (book != null) {
        // Cache book for analytics
        await _cacheService.cacheBook(book);
        emit(BookSearchSuccess([book]));
      } else {
        emit(const BookSearchSuccess([]));
      }
    } catch (e) {
      final userMessage = ErrorHandlerService.getUserFriendlyMessage(e);
      emit(BookSearchError(userMessage));
    }
  }

  Future<void> _onSearchByAuthor(
    SearchByAuthorEvent event,
    Emitter<BookSearchState> emit,
  ) async {
    if (event.author.isEmpty) {
      emit(const BookSearchSuccess([]));
      return;
    }
    emit(const BookSearchLoading());
    try {
      final books = await _repository.searchByAuthor(event.author);
      // Cache books for analytics
      await _cacheService.cacheBooks(books);
      emit(BookSearchSuccess(books));
    } catch (e) {
      final userMessage = ErrorHandlerService.getUserFriendlyMessage(e);
      emit(BookSearchError(userMessage));
    }
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<BookSearchState> emit,
  ) {
    emit(const BookSearchInitial());
  }
}

