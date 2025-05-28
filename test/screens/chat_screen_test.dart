import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/screens/ai/chat_screen.dart'; 

void main() {
  group('Tela de Chat com a IA', () {
    testWidgets('Exibe mensagens do usuário e da IA', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen()),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'quero adicionar a emocao feliz');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(find.text('quero adicionar a emocao feliz'), findsOneWidget);

      expect(find.textContaining('Que ótimo saber que você está se sentindo feliz!'), findsOneWidget);

      expect(find.text('Sim'), findsOneWidget);
      expect(find.text('Não'), findsOneWidget);
    });

    testWidgets('Botão de Sim redireciona para adicionar entrada', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen()),
      );

      await tester.enterText(find.byType(TextField), 'quero adicionar a emocao feliz');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      await tester.tap(find.text('Sim'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Como você está hoje?'), findsOneWidget);
    });
  });
}
