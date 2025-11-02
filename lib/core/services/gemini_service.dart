import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/gemini_config.dart';
import '../../modules/book_search/entities/book.dart';
import 'book_cache_service.dart';
import '../di/injection.dart';

/// Service for interacting with Google's Gemini API
/// Provides AI-powered book summaries and personalized recommendations
class GeminiService {
  final String? _apiKey;
  final BookCacheService _bookCacheService;

  GeminiService({
    String? apiKey,
    BookCacheService? bookCacheService,
  })  : _apiKey = apiKey ?? GeminiConfig.apiKey,
        _bookCacheService = bookCacheService ?? getIt<BookCacheService>();

  /// Check if Gemini API is available
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  /// Generate a concise and engaging book summary
  /// 
  /// Uses Gemini AI to create a 2-3 paragraph summary based on:
  /// - Book title
  /// - Author information
  /// - Description
  /// - Categories/genres
  Future<String> generateBookSummary({
    required String title,
    String? description,
    String? author,
    List<String>? categories,
  }) async {
    if (!isAvailable) {
      return _generateFallbackSummary(title, description, author);
    }

    try {
      final prompt = _buildSummaryPrompt(
        title: title,
        description: description,
        author: author,
        categories: categories,
      );

      final response = await _callGeminiAPI(prompt);

      if (response != null && response.isNotEmpty) {
        return response;
      }

      return _generateFallbackSummary(title, description, author);
    } catch (e) {
      // Log error in production
      return _generateFallbackSummary(title, description, author);
    }
  }

  /// Generate personalized book recommendations
  /// 
  /// Provides 5 book recommendations based on:
  /// - Current book title and author
  /// - Book categories
  /// - User's reading history (if available)
  Future<List<String>> generateRecommendations({
    required String title,
    String? author,
    List<String>? categories,
    int maxRecommendations = 5,
  }) async {
    if (!isAvailable) {
      return [];
    }

    try {
      // Get user's reading history for personalized recommendations
      final readingHistory = await _getUserReadingHistory();

      final prompt = _buildRecommendationsPrompt(
        title: title,
        author: author,
        categories: categories,
        readingHistory: readingHistory,
        maxRecommendations: maxRecommendations,
      );

      final response = await _callGeminiAPI(prompt);

      if (response != null && response.isNotEmpty) {
        return _parseRecommendations(response, maxRecommendations);
      }

      return [];
    } catch (e) {
      // Log error in production
      return [];
    }
  }

  /// Generate personalized recommendations based on user's reading history
  Future<List<String>> generatePersonalizedRecommendations({
    int maxRecommendations = 5,
  }) async {
    if (!isAvailable) {
      return [];
    }

    try {
      final readingHistory = await _getUserReadingHistory();

      if (readingHistory.isEmpty) {
        return [];
      }

      final prompt = _buildPersonalizedRecommendationsPrompt(
        readingHistory: readingHistory,
        maxRecommendations: maxRecommendations,
      );

      final response = await _callGeminiAPI(prompt);

      if (response != null && response.isNotEmpty) {
        return _parseRecommendations(response, maxRecommendations);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Call Gemini API with the given prompt
  Future<String?> _callGeminiAPI(String prompt) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return null;
    }

    try {
      final model = GeminiConfig.defaultModel;
      final uri = Uri.parse(
        '${GeminiConfig.baseUrl}/models/$model:generateContent?key=$_apiKey',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Gemini API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Handle API errors from Gemini
        if (data.containsKey('error')) {
          final error = data['error'] as Map<String, dynamic>;
          throw Exception('Gemini API Error: ${error['message'] ?? 'Unknown error'}');
        }

        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return text.trim();
            }
          }
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        throw Exception('Invalid request: ${errorData?['error']?['message'] ?? 'Bad request'}');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your Gemini API key.');
      } else if (response.statusCode == 429) {
        throw Exception('API quota exceeded. Please try again later.');
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      // Re-throw with context
      if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Failed to call Gemini API: ${e.toString()}');
    }

    return null;
  }

  /// Build prompt for book summary generation
  String _buildSummaryPrompt({
    required String title,
    String? description,
    String? author,
    List<String>? categories,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Generate a concise and engaging book summary (2-3 paragraphs, approximately 200-300 words) for the following book:');
    buffer.writeln();
    buffer.writeln('Title: $title');
    
    if (author != null && author.isNotEmpty) {
      buffer.writeln('Author: $author');
    }
    
    if (categories != null && categories.isNotEmpty) {
      buffer.writeln('Categories: ${categories.join(', ')}');
    }
    
    if (description != null && description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Book Description:');
      buffer.writeln(description.length > 500 ? '${description.substring(0, 500)}...' : description);
    }
    
    buffer.writeln();
    buffer.writeln('Please provide a well-written summary that:');
    buffer.writeln('- Highlights key themes and plot elements');
    buffer.writeln('- Captures the book\'s tone and style');
    buffer.writeln('- Appeals to potential readers');
    buffer.writeln('- Is engaging and informative');
    buffer.writeln('- Does not include spoilers');
    
    return buffer.toString();
  }

  /// Build prompt for book recommendations
  String _buildRecommendationsPrompt({
    required String title,
    String? author,
    List<String>? categories,
    List<Book> readingHistory = const [],
    int maxRecommendations = 5,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Based on the book "$title"');
    if (author != null && author.isNotEmpty) {
      buffer.writeln('by $author');
    }
    
    if (categories != null && categories.isNotEmpty) {
      buffer.writeln('(categories: ${categories.join(', ')})');
    }
    
    if (readingHistory.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('User\'s recent reading history:');
      for (final book in readingHistory.take(5)) {
        buffer.writeln('- ${book.title}${book.authors.isNotEmpty ? " by ${book.authors.first}" : ""}');
      }
    }
    
    buffer.writeln();
    buffer.writeln('Suggest $maxRecommendations similar book titles that readers might enjoy.');
    buffer.writeln('Return only the book titles, one per line, without numbering, bullets, or additional text.');
    buffer.writeln('Each title should be on its own line.');
    
    return buffer.toString();
  }

  /// Build prompt for personalized recommendations
  String _buildPersonalizedRecommendationsPrompt({
    required List<Book> readingHistory,
    int maxRecommendations = 5,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Based on the user\'s reading history, suggest $maxRecommendations personalized book recommendations.');
    buffer.writeln();
    buffer.writeln('User\'s reading history:');
    for (final book in readingHistory.take(10)) {
      buffer.writeln('- ${book.title}');
      if (book.authors.isNotEmpty) {
        buffer.writeln('  Author: ${book.authors.first}');
      }
      if (book.categories != null && book.categories!.isNotEmpty) {
        buffer.writeln('  Categories: ${book.categories!.take(3).join(', ')}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('Return only the book titles, one per line, without numbering, bullets, or additional text.');
    buffer.writeln('Each title should be on its own line.');
    buffer.writeln('Focus on books that match the user\'s interests and reading patterns.');
    
    return buffer.toString();
  }

  /// Parse recommendations from API response
  List<String> _parseRecommendations(String response, int maxRecommendations) {
    final lines = response
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !line.startsWith(RegExp(r'^\d+[\.\)]'))) // Remove numbering
        .where((line) => !line.startsWith('-')) // Remove bullets
        .where((line) => !line.startsWith('•')) // Remove bullets
        .take(maxRecommendations)
        .toList();

    return lines;
  }

  /// Get user's reading history from cached books
  Future<List<Book>> _getUserReadingHistory() async {
    try {
      final cachedBooks = await _bookCacheService.getCachedBooks();
      // Return most recently viewed books (limit to 10 for prompt)
      return cachedBooks.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// Generate fallback summary when API is unavailable
  String _generateFallbackSummary(String title, String? description, String? author) {
    if (description != null && description.isNotEmpty) {
      // Use description if available, truncate if too long
      if (description.length > 300) {
        return '${description.substring(0, 300)}...';
      }
      return description;
    }

    // Generate a basic fallback summary
    final buffer = StringBuffer();
    buffer.write('"$title"');
    if (author != null && author.isNotEmpty) {
      buffer.write(' by $author');
    }
    buffer.write(' is a compelling book that invites readers to explore its narrative.');
    buffer.write(' Discover the engaging story and immerse yourself in the author\'s world.');
    
    return buffer.toString();
  }
}

