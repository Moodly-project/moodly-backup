import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/screens/diary/diary_screen.dart';

void main() {
  testWidgets('Testes da tela de Diário de Emoções', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DiaryScreen(),
      ),
    );

    expect(find.text('Como você está hoje?'), findsOneWidget);
    expect(find.text('Data:'), findsOneWidget);
    expect(find.text('Humor:'), findsOneWidget);
    expect(find.text('Diário:'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>)); 
    await tester.pumpAndSettle();
    expect(find.text('Feliz'), findsWidgets);

    await tester.tap(find.text('Feliz').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Ganhei 10 reais hoje');
    expect(find.text('Ganhei 10 reais hoje'), findsOneWidget);

    await tester.tap(find.text('Salvar Entrada'));
    await tester.pumpAndSettle();

    expect(find.text('Ganhei 10 reais hoje'), findsOneWidget);
    expect(find.text('Feliz'), findsOneWidget);

    expect(find.byIcon(Icons.edit), findsWidgets);
    expect(find.byIcon(Icons.delete), findsWidgets);

    expect(find.byIcon(Icons.bar_chart), findsOneWidget); 
    expect(find.byIcon(Icons.smart_toy), findsOneWidget); 

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.smart_toy));
    await tester.pumpAndSettle();
    
  });
}
