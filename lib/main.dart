import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/screens/splash_screen.dart'; // Adicionado
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Inicia diretamente com a SplashScreen
  runApp(const MoodlyApp());
}

class MoodlyApp extends StatelessWidget {
  // final Widget initialScreen; // Removido

  const MoodlyApp({super.key}); // Modificado

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moodly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(), // Define SplashScreen como home
    );
  }
}
