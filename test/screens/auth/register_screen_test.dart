import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/screens/auth/register_screen.dart';
import 'package:moodyr/widgets/custom_button.dart'; // Necessário para encontrar o CustomButton

void main() {
  // Helper para envolver o widget em teste com MaterialApp e Scaffold
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('Campos vazios devem exibir mensagens de erro', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const RegisterScreen()));

      final Finder registerButton = find.widgetWithText(CustomButton, 'Registrar');
      expect(registerButton, findsOneWidget, reason: 'Botão "Registrar" não encontrado');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Nome Inválido'), findsOneWidget);
      expect(find.text('E-mail Inválido'), findsOneWidget);
      // A mensagem exata para senha pode variar dependendo da implementação do validador
      expect(find.textContaining('A senha deve ter pelo menos'), findsOneWidget); 
      expect(find.text('Por favor, confirme sua senha'), findsOneWidget);
    });

    testWidgets('Nome inválido deve exibir mensagem de erro para nome', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const RegisterScreen()));

      final nameField = find.widgetWithText(TextFormField, 'Nome');
      expect(nameField, findsOneWidget, reason: 'Campo "Nome" não encontrado');
      await tester.enterText(nameField, 'N0meComNumer0'); // Inválido

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'valido@email.com');
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      await tester.enterText(passwordField, 'Valida123!');
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmar Senha');
      await tester.enterText(confirmPasswordField, 'Valida123!');

      final Finder registerButton = find.widgetWithText(CustomButton, 'Registrar');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Nome Inválido'), findsOneWidget);
      expect(find.text('E-mail Inválido'), findsNothing);
      expect(find.textContaining('A senha deve ter pelo menos'), findsNothing);
      expect(find.text('As senhas não coincidem'), findsNothing);
    });

    testWidgets('E-mail inválido deve exibir mensagem de erro para e-mail', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const RegisterScreen()));

      final nameField = find.widgetWithText(TextFormField, 'Nome');
      await tester.enterText(nameField, 'Nome Valido');
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'emailinvalido'); // Inválido
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      await tester.enterText(passwordField, 'Valida123!');
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmar Senha');
      await tester.enterText(confirmPasswordField, 'Valida123!');

      final Finder registerButton = find.widgetWithText(CustomButton, 'Registrar');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('E-mail Inválido'), findsOneWidget);
      expect(find.text('Nome Inválido'), findsNothing);
      expect(find.textContaining('A senha deve ter pelo menos'), findsNothing);
    });
    
    testWidgets('Senha inválida deve exibir mensagem de erro para senha', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const RegisterScreen()));

      final nameField = find.widgetWithText(TextFormField, 'Nome');
      await tester.enterText(nameField, 'Nome Valido');
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'valido@email.com');
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      await tester.enterText(passwordField, 'curta'); // Inválida
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmar Senha');
      await tester.enterText(confirmPasswordField, 'curta');


      final Finder registerButton = find.widgetWithText(CustomButton, 'Registrar');
      await tester.tap(registerButton);
      await tester.pump();
      
      expect(find.textContaining('A senha deve ter pelo menos'), findsOneWidget);
      expect(find.text('Nome Inválido'), findsNothing);
      expect(find.text('E-mail Inválido'), findsNothing);
    });

    testWidgets('Senhas não coincidentes devem exibir mensagem de erro', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const RegisterScreen()));

      final nameField = find.widgetWithText(TextFormField, 'Nome');
      await tester.enterText(nameField, 'Nome Valido');
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'valido@email.com');
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      await tester.enterText(passwordField, 'Valida123!');
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmar Senha');
      await tester.enterText(confirmPasswordField, 'Diferente123!'); // Diferente

      final Finder registerButton = find.widgetWithText(CustomButton, 'Registrar');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('As senhas não coincidem'), findsOneWidget);
      expect(find.text('Nome Inválido'), findsNothing);
      expect(find.text('E-mail Inválido'), findsNothing);
      expect(find.textContaining('A senha deve ter pelo menos'), findsNothing); // Assumindo que "Valida123!" é válida
    });

    testWidgets('Dados válidos não devem exibir mensagens de erro de validação', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const RegisterScreen()));

      final nameField = find.widgetWithText(TextFormField, 'Nome');
      await tester.enterText(nameField, 'Nome Valido');
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'valido@email.com');
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      await tester.enterText(passwordField, 'Valida123!');
      final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmar Senha');
      await tester.enterText(confirmPasswordField, 'Valida123!');
      
      final Finder registerButton = find.widgetWithText(CustomButton, 'Registrar');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Nome Inválido'), findsNothing);
      expect(find.text('E-mail Inválido'), findsNothing);
      expect(find.textContaining('A senha deve ter pelo menos'), findsNothing);
      expect(find.text('Por favor, confirme sua senha'), findsNothing);
      expect(find.text('As senhas não coincidem'), findsNothing);
      // Assim como no login, não verificaremos a lógica de API, apenas validação.
      // expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
