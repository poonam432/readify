import '../../modules/book_search/entities/book.dart';
import 'book_cache_service.dart';

class GenreData {
  final String genre;
  final int count;
  final double percentage;

  GenreData({
    required this.genre,
    required this.count,
    required this.percentage,
  });
}

class PublishingTrendData {
  final String year;
  final int count;

  PublishingTrendData({
    required this.year,
    required this.count,
  });
}

class AnalyticsService {
  final BookCacheService _bookCacheService;

  AnalyticsService(this._bookCacheService);

  Future<List<GenreData>> getGenreDistribution() async {
    final books = await _bookCacheService.getCachedBooks();
    
    if (books.isEmpty) {
      return _getDefaultGenres();
    }

    final Map<String, int> genreCount = {};
    int totalBooksWithGenres = 0;

    for (final book in books) {
      if (book.categories != null && book.categories!.isNotEmpty) {
        for (final category in book.categories!) {
          // Normalize category names
          final normalized = _normalizeGenre(category);
          genreCount[normalized] = (genreCount[normalized] ?? 0) + 1;
          totalBooksWithGenres++;
        }
      }
    }

    if (genreCount.isEmpty) {
      return _getDefaultGenres();
    }

    // Sort by count and take top genres
    final sortedGenres = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Group into main categories
    final Map<String, int> categorized = _categorizeGenres(sortedGenres);

    final total = categorized.values.fold(0, (sum, count) => sum + count);
    
    return categorized.entries.map((entry) {
      return GenreData(
        genre: entry.key,
        count: entry.value,
        percentage: total > 0 ? (entry.value / total) * 100 : 0,
      );
    }).toList();
  }

  Future<List<PublishingTrendData>> getPublishingTrend() async {
    final books = await _bookCacheService.getCachedBooks();
    
    if (books.isEmpty) {
      return _getDefaultPublishingTrend();
    }

    final Map<String, int> yearCount = {};

    for (final book in books) {
      if (book.publishedDate != null) {
        final year = _extractYear(book.publishedDate!);
        if (year != null) {
          yearCount[year] = (yearCount[year] ?? 0) + 1;
        }
      }
    }

    if (yearCount.isEmpty) {
      return _getDefaultPublishingTrend();
    }

    // Get current year and create range
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 4; // Last 5 years
    
    final List<PublishingTrendData> trends = [];
    
    for (int year = startYear; year <= currentYear; year++) {
      final yearStr = year.toString();
      trends.add(PublishingTrendData(
        year: yearStr,
        count: yearCount[yearStr] ?? 0,
      ));
    }

    return trends;
  }

  String _normalizeGenre(String genre) {
    final normalized = genre.toLowerCase().trim();
    
    // Map variations to standard categories
    if (normalized.contains('fiction') && !normalized.contains('non')) {
      return 'Fiction';
    } else if (normalized.contains('non-fiction') || normalized.contains('nonfiction')) {
      return 'Non-fiction';
    } else if (normalized.contains('romance')) {
      return 'Romance';
    } else if (normalized.contains('sci-fi') || normalized.contains('science fiction')) {
      return 'Sci-fi';
    } else if (normalized.contains('biography')) {
      return 'Biography';
    } else if (normalized.contains('mathematics') || normalized.contains('math')) {
      return 'Mathematics';
    } else if (normalized.contains('music')) {
      return 'Music';
    }
    
    // Return capitalized first word or original if short
    if (normalized.length < 3) return genre;
    final words = normalized.split(' ');
    return words.first.substring(0, 1).toUpperCase() + words.first.substring(1);
  }

  Map<String, int> _categorizeGenres(List<MapEntry<String, int>> genres) {
    final Map<String, int> categorized = {};
    
    for (final entry in genres) {
      final category = _normalizeGenre(entry.key);
      categorized[category] = (categorized[category] ?? 0) + entry.value;
    }

    // Ensure we have at least Fiction, Non-fiction, and Romance
    if (!categorized.containsKey('Fiction')) categorized['Fiction'] = 0;
    if (!categorized.containsKey('Non-fiction')) categorized['Non-fiction'] = 0;
    if (!categorized.containsKey('Romance')) categorized['Romance'] = 0;

    // Return top 3 categories by count
    final sorted = categorized.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final result = <String, int>{};
    for (final entry in sorted.take(3)) {
      result[entry.key] = entry.value;
    }

    // Fill with defaults if needed
    if (result.length < 3) {
      if (!result.containsKey('Fiction')) result['Fiction'] = result.values.isNotEmpty 
          ? (result.values.first * 0.45).round() : 45;
      if (!result.containsKey('Non-fiction')) result['Non-fiction'] = result.values.isNotEmpty 
          ? (result.values.first * 0.35).round() : 35;
      if (!result.containsKey('Romance')) result['Romance'] = result.values.isNotEmpty 
          ? (result.values.first * 0.20).round() : 20;
    }

    return result;
  }

  String? _extractYear(String publishedDate) {
    try {
      // Try to extract year from various date formats
      final dateStr = publishedDate.trim();
      
      // If it's just a year (4 digits)
      if (RegExp(r'^\d{4}$').hasMatch(dateStr)) {
        return dateStr;
      }
      
      // If it's in format YYYY-MM-DD or YYYY-MM
      final yearMatch = RegExp(r'^(\d{4})').firstMatch(dateStr);
      if (yearMatch != null) {
        return yearMatch.group(1);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  List<GenreData> _getDefaultGenres() {
    return [
      GenreData(genre: 'Fiction', count: 45, percentage: 45.0),
      GenreData(genre: 'Non-fiction', count: 35, percentage: 35.0),
      GenreData(genre: 'Romance', count: 20, percentage: 20.0),
    ];
  }

  List<PublishingTrendData> _getDefaultPublishingTrend() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) {
      final year = (currentYear - 4 + index).toString();
      return PublishingTrendData(
        year: year,
        count: 0,
      );
    });
  }
}


