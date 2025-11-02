import 'package:equatable/equatable.dart';

abstract class BookSearchEvent extends Equatable {
  const BookSearchEvent();

  @override
  List<Object> get props => [];
}

class SearchBooksEvent extends BookSearchEvent {
  final String query;

  const SearchBooksEvent(this.query);

  @override
  List<Object> get props => [query];
}

class SearchByIsbnEvent extends BookSearchEvent {
  final String isbn;

  const SearchByIsbnEvent(this.isbn);

  @override
  List<Object> get props => [isbn];
}

class SearchByAuthorEvent extends BookSearchEvent {
  final String author;

  const SearchByAuthorEvent(this.author);

  @override
  List<Object> get props => [author];
}

class ClearSearchEvent extends BookSearchEvent {
  const ClearSearchEvent();
}

