import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen deve mostrar o logo e o texto de carregamento',
      (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(),
      ),
    );

    await tester.pump();

    // Assert
    // Verifica se o título está presente
    expect(find.text('Moodly'), findsOneWidget);
    
    // Verifica se o subtítulo está presente
    expect(find.text('Seu diário de emoções pessoal'), findsOneWidget);
    
    // Verifica se a animação está presente (CircularProgressIndicator)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SplashScreen deve navegar após o tempo de espera',
      (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
      ),
    );

    // Act
    // Avança o tempo para simular o tempo de espera da splash screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
} 