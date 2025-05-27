import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// Manages the configuration of the API base URL.
/// It allows storing, retrieving, and automatically detecting the server URL.
class ApiConfigService {
  // Key used to store the API base URL in secure storage.
  static const String _storageKey = 'api_base_url';
  // Default API URL, typically used for Android Emulator.
  static const String _defaultUrl = 'http://10.0.2.2:3000/api';
  final _storage = const FlutterSecureStorage();

  // List of common IP addresses for development environments and emulators.
  // These are used as the initial set of IPs to test in `detectServerIp`.
  static const List<String> _commonIps = [
    '10.0.2.2', // Android Emulator
    'localhost',
    '127.0.0.1',
  ];

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

  /// Resets the API base URL to the default value (_defaultUrl).
  /// This is typically the Android emulator's loopback address.
  Future<void> resetToDefault() async {
    await _storage.write(key: _storageKey, value: _defaultUrl);
  }

  /// Attempts to automatically detect the server IP on the local network.
  /// It tests a predefined list of common IPs by checking the `/api/health` endpoint.
  ///
  /// Note: Automatic IP detection has limitations and might not work reliably
  /// across all network configurations. For greater reliability, especially in diverse
  /// network environments, providing a manual URL configuration option for the user
  /// within the application is recommended.
  Future<String?> detectServerIp() async {
    // List of IPs to test, including common local network IPs and gateways.
    final List<String> ipsToTest = [
      ..._commonIps,
      '192.168.1.1', // Common gateway
      '192.168.0.1', // Another common gateway
    ];

    // Timeout for each connection attempt.
    const timeout = Duration(seconds: 1);

    // Try connecting to each IP in parallel.
    // Uses the /api/health endpoint to verify server connectivity.
    final futures = ipsToTest.map((ip) async {
      try {
        final url = 'http://$ip:3000/api/health';
        final response = await http.get(Uri.parse(url)).timeout(timeout);
        if (response.statusCode == 200) {
          return ip;
        }
      } catch (e) {
        // Ignora erros de timeout ou conexão recusada
      }
      return null;
    });

    // Aguarda todas as tentativas e retorna o primeiro IP que respondeu
    final results = await Future.wait(futures);
    final workingIp = results.firstWhere((ip) => ip != null, orElse: () => null);

    if (workingIp != null) {
      // Se encontrou um IP funcionando, atualiza a URL base
      await setBaseUrl('http://$workingIp:3000');
      return 'http://$workingIp:3000/api';
    }

    return null;
  }
} 