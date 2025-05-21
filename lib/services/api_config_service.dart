import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiConfigService {
  static const String _storageKey = 'api_base_url';
  static const String _defaultUrl = 'http://10.0.2.2:3000/api';
  final _storage = const FlutterSecureStorage();

  // Lista de IPs comuns para testar
  static const List<String> _commonIps = [
    '10.0.2.2', // Android Emulator
    'localhost',
    '127.0.0.1',
  ];

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

  // Método para detectar automaticamente o IP do servidor
  Future<String?> detectServerIp() async {
    // Lista de IPs para testar, incluindo IPs comuns de rede local
    final List<String> ipsToTest = [
      ..._commonIps,
      // Adiciona IPs comuns de rede local (192.168.0.x e 192.168.1.x)
      for (var i = 1; i <= 255; i++) ...[
        '192.168.0.$i',
        '192.168.1.$i',
      ],
    ];

    // Timeout para cada tentativa
    const timeout = Duration(seconds: 1);

    // Tenta cada IP em paralelo
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