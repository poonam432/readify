/// Configuration for Gemini API
/// 
/// To use Gemini API, set your API key:
/// 1. Get your API key from: https://makersuite.google.com/app/apikey
/// 2. For development: Set GEMINI_API_KEY environment variable
/// 3. For production: Use secure storage or environment configuration
class GeminiConfig {
  /// Static API key (can be set at runtime)
  /// ⚠️ WARNING: Never commit API keys to version control!
  static String? _staticApiKey;
  
  /// Set the API key programmatically
  /// Use this for testing or when loading from secure storage
  static void setApiKey(String key) {
    _staticApiKey = key;
  }
  
  /// Gemini API Key
  /// 
  /// Priority order:
  /// 1. Static API key (set via setApiKey())
  /// 2. Environment variable: GEMINI_API_KEY
  /// 3. null (fallback to description)
  static String? get apiKey {
    // First check static API key (set programmatically)
    if (_staticApiKey != null && _staticApiKey!.isNotEmpty) {
      return _staticApiKey;
    }
    
    // Try to get from environment variable
    const String envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    return null;
  }
  
  /// Base URL for Gemini API
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  /// Default model to use
  /// Options: 'gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'
  static const String defaultModel = 'gemini-1.5-flash';
  
  /// Check if Gemini API is configured
  static bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;
}

