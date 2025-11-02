import 'search_history_service.dart';
import 'book_cache_service.dart';
import '../../modules/book_search/entities/book.dart';

class SearchInsight {
  final String query;
  final int searchCount;
  final int booksFound;
  final String? mostPopularCategory;
  final double averageRating;

  SearchInsight({
    required this.query,
    required this.searchCount,
    required this.booksFound,
    this.mostPopularCategory,
    required this.averageRating,
  });
}

class SearchAnalyticsService {
  final SearchHistoryService _historyService;
  final BookCacheService _bookCacheService;

  SearchAnalyticsService(this._historyService, this._bookCacheService);

  Future<Map<String, dynamic>> getSearchAnalytics() async {
    final history = await _historyService.getSearchHistory();
    final cachedBooks = await _bookCacheService.getCachedBooks();

    // Most searched terms
    final mostSearchedTerms = _getMostSearchedTerms(history);

    // Search frequency
    final searchFrequency = _getSearchFrequency(history);

    // Categories from searched books
    final categories = _getCategoriesFromSearches(cachedBooks);

    // Average ratings
    final averageRating = _getAverageRating(cachedBooks);

    // Popular authors
    final popularAuthors = _getPopularAuthors(cachedBooks);

    return {
      'totalSearches': history.length,
      'uniqueSearches': history.toSet().length,
      'mostSearchedTerms': mostSearchedTerms,
      'searchFrequency': searchFrequency,
      'topCategories': categories,
      'averageRating': averageRating,
      'popularAuthors': popularAuthors,
    };
  }

  Future<List<SearchInsight>> getSearchInsights() async {
    final history = await _historyService.getSearchHistory();
    final cachedBooks = await _bookCacheService.getCachedBooks();
    final insights = <SearchInsight>[];

    final queryCounts = <String, List<String>>{};
    for (final query in history) {
      queryCounts.putIfAbsent(query, () => []).add(query);
    }

    for (final entry in queryCounts.entries) {
      final query = entry.key;
      final count = entry.value.length;
      final relatedBooks = cachedBooks.where((book) {
        final titleMatch = book.title.toLowerCase().contains(query.toLowerCase());
        final authorMatch = book.authorDisplay.toLowerCase().contains(query.toLowerCase());
        final categoryMatch = book.categories?.any((cat) =>
                cat.toLowerCase().contains(query.toLowerCase())) ?? false;
        return titleMatch || authorMatch || categoryMatch;
      }).toList();

      final categoryCounts = <String, int>{};
      for (final category in relatedBooks.expand((book) => book.categories ?? [])) {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
      final mostPopularCategory = categoryCounts.isEmpty
          ? null
          : categoryCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

      final ratings = relatedBooks
          .where((book) => book.averageRating != null)
          .map((book) => book.averageRating!)
          .toList();
      final avgRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      insights.add(SearchInsight(
        query: query,
        searchCount: count,
        booksFound: relatedBooks.length,
        mostPopularCategory: mostPopularCategory,
        averageRating: avgRating,
      ));
    }

    insights.sort((a, b) => b.searchCount.compareTo(a.searchCount));
    return insights.take(10).toList();
  }

  List<MapEntry<String, int>> _getMostSearchedTerms(List<String> history) {
    final counts = <String, int>{};
    for (final term in history) {
      final key = term.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Map<String, int> _getSearchFrequency(List<String> history) {
    final now = DateTime.now();
    final frequency = <String, int>{
      'today': 0,
      'thisWeek': 0,
      'thisMonth': 0,
    };

    // Note: SearchHistoryService doesn't store timestamps, so we approximate
    // by assuming recent items in history are more recent
    for (int i = 0; i < history.length && i < 7; i++) {
      if (i == 0) {
        frequency['today'] = 1;
      } else if (i < 3) {
        frequency['thisWeek'] = (frequency['thisWeek'] ?? 0) + 1;
      } else {
        frequency['thisMonth'] = (frequency['thisMonth'] ?? 0) + 1;
      }
    }

    return frequency;
  }

  List<String> _getCategoriesFromSearches(List<Book> books) {
    final categoryCounts = <String, int>{};
    for (final book in books) {
      for (final category in book.categories ?? []) {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  double _getAverageRating(List<Book> books) {
    final ratings = books
        .where((book) => book.averageRating != null)
        .map((book) => book.averageRating!)
        .toList();
    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  List<String> _getPopularAuthors(List<Book> books) {
    final authorCounts = <String, int>{};
    for (final book in books) {
      for (final author in book.authors) {
        authorCounts[author] = (authorCounts[author] ?? 0) + 1;
      }
    }
    final sorted = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }
}

