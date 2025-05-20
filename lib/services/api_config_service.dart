import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfigService {
  static const String _storageKey = 'api_base_url';
  static const String _defaultUrl = 'http://10.0.2.2:3000/api';
  final _storage = const FlutterSecureStorage();

  // Singleton pattern
  static final ApiConfigService _instance = ApiConfigService._internal();
  factory ApiConfigService() => _instance;
  ApiConfigService._internal();

  // Getter para a URL base
  Future<String> getBaseUrl() async {
    final storedUrl = await _storage.read(key: _storageKey);
    return storedUrl ?? _defaultUrl;
  }

  // Setter para atualizar a URL base
  Future<void> setBaseUrl(String newUrl) async {
    // Validação básica da URL
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      throw Exception('URL inválida: deve começar com http:// ou https://');
    }
    
    // Remove trailing slash se existir
    if (newUrl.endsWith('/')) {
      newUrl = newUrl.substring(0, newUrl.length - 1);
    }

    // Adiciona /api se não estiver presente
    if (!newUrl.endsWith('/api')) {
      newUrl = '$newUrl/api';
    }

    await _storage.write(key: _storageKey, value: newUrl);
  }

  // Método para resetar para a URL padrão
  Future<void> resetToDefault() async {
    await _storage.write(key: _storageKey, value: _defaultUrl);
  }
} 