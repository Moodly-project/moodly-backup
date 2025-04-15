import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/screens/auth/eula_screen.dart';
import 'package:moodyr/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkEulaAndNavigate();
  }

  Future<void> _checkEulaAndNavigate() async {
    // Aguarda um tempo para a splash screen ser visível
    await Future.delayed(const Duration(seconds: 3));

    String? eulaAccepted = await _storage.read(key: 'eula_accepted');

    if (!mounted) return; // Verifica se o widget ainda está montado

    if (eulaAccepted == 'true') {
      // Se EULA aceito, vai para Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // Se EULA não aceito ou primeira vez, vai para EULA
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EulaScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
              // Colors.deepPurple.shade200,
              // Colors.blue.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Moodly',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Seu diário de emoções pessoal',
                style: TextStyle(
                  fontSize: 18,
                   color: Theme.of(context).colorScheme.secondary,
                ),
              ),
               const SizedBox(height: 50),
               CircularProgressIndicator(
                 valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
               ),
            ],
          ),
        ),
      ),
    );
  }
} 