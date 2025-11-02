class Book {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? description;
  final String? publisher;
  final String? publishedDate;
  final int? pageCount;
  final List<String>? categories;
  final String? thumbnailUrl;
  final String? previewLink;
  final String? infoLink;
  final String? language;
  final double? averageRating;
  final int? ratingsCount;
  final String? isbn10;
  final String? isbn13;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    required this.authors,
    this.description,
    this.publisher,
    this.publishedDate,
    this.pageCount,
    this.categories,
    this.thumbnailUrl,
    this.previewLink,
    this.infoLink,
    this.language,
    this.averageRating,
    this.ratingsCount,
    this.isbn10,
    this.isbn13,
  });

  String get authorDisplay => authors.isEmpty ? 'Unknown' : authors.join(', ');

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final industryIdentifiers = volumeInfo['industryIdentifiers'] as List? ?? [];
    
    String? isbn10;
    String? isbn13;
    
    for (var identifier in industryIdentifiers) {
      final type = identifier['type'] as String?;
      final identifierValue = identifier['identifier'] as String?;
      if (type == 'ISBN_10') {
        isbn10 = identifierValue;
      } else if (type == 'ISBN_13') {
        isbn13 = identifierValue;
      }
    }

    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    
    return Book(
      id: json['id'] as String? ?? '',
      title: volumeInfo['title'] as String? ?? '',
      subtitle: volumeInfo['subtitle'] as String?,
      authors: (volumeInfo['authors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      description: volumeInfo['description'] as String?,
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      categories: (volumeInfo['categories'] as List?)?.map((e) => e.toString()).toList(),
      thumbnailUrl: imageLinks?['thumbnail'] as String? ?? imageLinks?['smallThumbnail'] as String?,
      previewLink: volumeInfo['previewLink'] as String?,
      infoLink: volumeInfo['infoLink'] as String?,
      language: volumeInfo['language'] as String?,
      averageRating: (volumeInfo['averageRating'] as num?)?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount'] as int?,
      isbn10: isbn10,
      isbn13: isbn13,
    );
  }
}

