import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/widgets/custom_button.dart'; // Corrigido o path

void main() {
  testWidgets('CustomButton exibe texto e responde ao toque', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Clique Aqui',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Clique Aqui'), findsOneWidget);

    await tester.tap(find.byType(CustomButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
} 