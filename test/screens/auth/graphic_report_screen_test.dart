import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/screens/report/report_screen.dart'; 
import 'package:moodyr/screens/ai/ai_screen.dart'; 
void main() {
  group('Tela de Gráfico de Humor', () {
    testWidgets('Renderiza gráfico e estatísticas corretamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ReportScreen()), 
      );

      expect(find.text('Insights de Humor'), findsOneWidget);

      expect(find.text('50%'), findsNWidgets(2));
      expect(find.text('Feliz'), findsOneWidget);
      expect(find.text('Triste'), findsOneWidget);

      expect(find.text('Total de Entradas'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Humor Mais Comum'), findsOneWidget);
      expect(find.text('Feliz'), findsOneWidget);
      expect(find.text('Período Analisado'), findsOneWidget);
      expect(find.text('07/05/25 até 20/05/25'), findsOneWidget);
    });
  });

  group('Tela de Moodly AI ', () {
    testWidgets('Renderiza insights da IA corretamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AIScreen()), 
      );

      expect(find.text('Resumo da IA'), findsOneWidget);
      expect(find.text('Insights da IA'), findsOneWidget);
      expect(find.text('Sugestões da IA'), findsOneWidget);

      expect(find.textContaining('O humor oscila'), findsOneWidget);
      expect(find.textContaining('Eventos aparentemente menores'), findsOneWidget);
      expect(find.textContaining('Buscar apoio psicológico'), findsOneWidget);
    });
  });
}
