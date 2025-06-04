import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// Manages the configuration of the API base URL.
/// It allows storing, retrieving, and automatically detecting the server URL.
class ApiConfigService {
  // Key used to store the API base URL in secure storage.
  static const String _storageKey = 'api_base_url';
  
  // URL pública do ngrok (atualizada)
  static const String _defaultUrl = 'https://e7a1-189-108-219-66.ngrok-free.app/api';
  
  final _storage = const FlutterSecureStorage();

  // Singleton pattern
  static final ApiConfigService _instance = ApiConfigService._internal();
  factory ApiConfigService() => _instance;
  ApiConfigService._internal();

  /// Retrieves the stored API base URL.
  /// Returns the default URL if no URL is stored.
  Future<String> getBaseUrl() async {
    final storedUrl = await _storage.read(key: _storageKey);
    return storedUrl ?? _defaultUrl;
  }

  /// Sets and stores the new API base URL.
  /// Performs validation and normalization:
  /// - Ensures the URL starts with 'http://' or 'https://'.
  /// - Removes a trailing slash if present.
  /// - Appends '/api' if not present.
  Future<void> setBaseUrl(String newUrl) async {
    // Basic URL validation.
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      throw Exception('URL inválida: deve começar com http:// ou https://');
    }
    
    // Remove trailing slash if it exists.
    if (newUrl.endsWith('/')) {
      newUrl = newUrl.substring(0, newUrl.length - 1);
    }

    // Add /api suffix if not already present.
    if (!newUrl.endsWith('/api')) {
      newUrl = '$newUrl/api';
    }

    await _storage.write(key: _storageKey, value: newUrl);
  }

  /// Resets the API base URL to the default value.
  Future<void> resetToDefault() async {
    await _storage.write(key: _storageKey, value: _defaultUrl);
  }
} 