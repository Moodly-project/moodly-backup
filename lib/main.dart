import 'package:flutter/material.dart';
import 'package:moodyr/screens/auth/login_screen.dart'; // Placeholder import
import 'package:intl/date_symbol_data_local.dart'; // Import para locale

void main() {
  // Inicializa a formatação de data para pt_BR antes de rodar o app
  initializeDateFormatting('pt_BR', null).then((_) => runApp(const MoodlyApp()));
}

class MoodlyApp extends StatelessWidget {
  const MoodlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moodly',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(), // Placeholder screen
    );
  }
}
