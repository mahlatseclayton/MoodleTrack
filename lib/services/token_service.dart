import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const storage = FlutterSecureStorage();
  static String? _cachedToken; // In-memory cache for quick access

  // Store token after login
  static Future<void> storeToken(String token) async {
    _cachedToken = token; // Cache in memory
    await storage.write(key: 'moodle_token', value: token);
  }

  // Get token anywhere in your app
  static Future<String?> getToken() async {
    // Return cached token if available
    if (_cachedToken != null) return _cachedToken;

    // Otherwise get from secure storage
    _cachedToken = await storage.read(key: 'moodle_token');
    return _cachedToken;
  }

  // Clear token on logout
  static Future<void> clearToken() async {
    _cachedToken = null;
    await storage.delete(key: 'moodle_token');
  }

  // Check if user has token
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}