import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/screens/auth/login_screen.dart';
import 'package:moodyr/screens/auth/eula_screen.dart';
import 'package:moodyr/screens/auth/api_key_setup_screen.dart';
import 'package:moodyr/screens/diary/diary_screen.dart'; // lógica para o diário
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necessário para SharedPreferences/SecureStorage antes do runApp
  await initializeDateFormatting('pt_BR', null);

  // Verificar estado inicial
  final storage = const FlutterSecureStorage();
  String? eulaAccepted = await storage.read(key: 'eula_accepted');
  String? apiKey = await storage.read(key: 'api_key');
  String? jwtToken = await storage.read(key: 'jwt_token'); // Verificar se já está logado

  Widget initialScreen;

  if (jwtToken != null && jwtToken.isNotEmpty) {
      initialScreen = const DiaryScreen(); // Usuário já logado, vai direto pro diário
  } else if (eulaAccepted != 'true') {
    initialScreen = const EulaScreen(); // Precisa aceitar o EULA
  } else if (apiKey == null || apiKey.trim().isEmpty) {
    initialScreen = const ApiKeySetupScreen(); // Precisa configurar a API Key
  } else {
    initialScreen = const LoginScreen(); // Já aceitou EULA e configurou API Key, vai pro Login
  }

  runApp(MoodlyApp(initialScreen: initialScreen));
}

class MoodlyApp extends StatelessWidget {
  final Widget initialScreen; // Recebe a tela inicial

  const MoodlyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moodly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use cores mais consistentes com as telas novas
        primarySwatch: Colors.teal, // Ou Colors.deepPurple, etc.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), // Ajuste a seedColor
        useMaterial3: true, // Recomendado
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: initialScreen, // Usa a tela inicial determinada
    );
  }
}