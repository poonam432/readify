import 'dart:async';
import 'dart:convert';
import '../../modules/book_search/entities/book.dart';
import 'book_cache_service.dart';
import '../di/injection.dart';

class TrendingBook {
  final String title;
  final String author;
  final String thumbnailUrl;
  final int trendScore;

  TrendingBook({
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.trendScore,
  });

  factory TrendingBook.fromJson(Map<String, dynamic> json) {
    return TrendingBook(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      trendScore: json['trendScore'] as int? ?? 0,
    );
  }
}

class WebSocketService {
  StreamController<List<TrendingBook>>? _trendingController;
  Timer? _mockUpdateTimer;
  bool _isConnected = false;

  Stream<List<TrendingBook>> get trendingBooksStream {
    _trendingController ??= StreamController<List<TrendingBook>>.broadcast();
    
    // Start mock updates if not already started
    if (!_isConnected) {
      _startMockUpdates();
    }
    
    return _trendingController!.stream;
  }

  void _startMockUpdates() {
    _isConnected = true;
    
    // Send initial trending books
    _sendMockTrendingBooks();
    
    // Update every 30 seconds with new mock data
    _mockUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendMockTrendingBooks();
    });
  }

  Future<void> _sendMockTrendingBooks() async {
    // Generate mock trending books based on cached books
    final cacheService = getIt<BookCacheService>();
    final cachedBooks = await cacheService.getCachedBooks();
    
    List<TrendingBook> trending = [];
    
    if (cachedBooks.isNotEmpty) {
      // Use most recent books as trending
      final recentBooks = cachedBooks.take(5).toList();
      for (int i = 0; i < recentBooks.length; i++) {
        trending.add(TrendingBook(
          title: recentBooks[i].title,
          author: recentBooks[i].authorDisplay,
          thumbnailUrl: recentBooks[i].thumbnailUrl ?? '',
          trendScore: 100 - (i * 10), // Decreasing trend score
        ));
      }
    } else {
      // Generate mock data if no cached books
      trending = [
        TrendingBook(
          title: 'The Future of Technology',
          author: 'Jane Smith',
          thumbnailUrl: '',
          trendScore: 95,
        ),
        TrendingBook(
          title: 'Design Patterns',
          author: 'John Doe',
          thumbnailUrl: '',
          trendScore: 85,
        ),
        TrendingBook(
          title: 'Flutter Development',
          author: 'Tech Writer',
          thumbnailUrl: '',
          trendScore: 75,
        ),
      ];
    }
    
    _trendingController?.add(trending);
  }

  Future<void> connect() async {
    if (_isConnected) return;
    _startMockUpdates();
  }

  Future<void> disconnect() async {
    _mockUpdateTimer?.cancel();
    _mockUpdateTimer = null;
    _isConnected = false;
  }

  void dispose() {
    _mockUpdateTimer?.cancel();
    _trendingController?.close();
    _trendingController = null;
    _isConnected = false;
  }
}

