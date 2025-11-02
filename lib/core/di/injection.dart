import 'package:get_it/get_it.dart';
import '../../modules/book_search/repositories/book_repository.dart';
import '../../modules/book_search/repositories/book_repository_impl.dart';
import '../services/google_books_service.dart';
import '../services/gemini_service.dart';
import '../services/search_history_service.dart';
import '../services/book_cache_service.dart';
import '../services/analytics_service.dart';
import '../services/websocket_service.dart';
import '../services/contacts_service.dart';
import '../services/user_profile_service.dart';
import '../services/search_analytics_service.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';
import '../services/firebase_auth_service.dart';
import '../config/gemini_config.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Configure Gemini API key
  // ⚠️ WARNING: For production, use secure storage or environment variables
  // Never commit API keys to version control!
  // 
  // Option 1: Set via environment variable (recommended for CI/CD)
  // Run: flutter run --dart-define=GEMINI_API_KEY=your_key_here
  //
  // Option 2: Set programmatically (only for development)
  // GeminiConfig.setApiKey('YOUR_API_KEY_HERE');
  //
  // Option 3: Use secure storage (recommended for production)
  // See GEMINI_API_SETUP.md for detailed instructions
  
  // Services
  getIt.registerSingleton<GoogleBooksService>(GoogleBooksService());
  getIt.registerSingleton<SearchHistoryService>(SearchHistoryService());
  getIt.registerSingleton<BookCacheService>(BookCacheService());
  getIt.registerSingleton<GeminiService>(
    GeminiService(
      bookCacheService: getIt<BookCacheService>(),
    ),
  );
  getIt.registerSingleton<AnalyticsService>(
    AnalyticsService(getIt<BookCacheService>()),
  );
  getIt.registerSingleton<WebSocketService>(WebSocketService());
  getIt.registerSingleton<ContactsService>(ContactsService());
  getIt.registerSingleton<UserProfileService>(UserProfileService());
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<FirebaseAuthService>(FirebaseAuthService());
  getIt.registerSingleton<GoogleSignInService>(GoogleSignInService());
  getIt.registerSingleton<SearchAnalyticsService>(
    SearchAnalyticsService(
      getIt<SearchHistoryService>(),
      getIt<BookCacheService>(),
    ),
  );
  
  // Repositories
  getIt.registerSingleton<BookRepository>(
    BookRepositoryImpl(getIt<GoogleBooksService>()),
  );
}

