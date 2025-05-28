import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/main.dart'; 
import 'package:moodyr/screens/auth/api_key_setup_screen.dart';

void main() {
  testWidgets('Testes da tela de Configuração de Chave de API', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ApiKeySetupScreen(),
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Sua Chave de API'), findsOneWidget);

    expect(find.text('Salvar Chave e Continuar'), findsOneWidget);
    expect(find.text('Pular por agora'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'test-api-key');
    expect(find.text('test-api-key'), findsOneWidget);

    await tester.tap(find.text('Salvar Chave e Continuar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pular por agora'));
    await tester.pumpAndSettle();
  });
}