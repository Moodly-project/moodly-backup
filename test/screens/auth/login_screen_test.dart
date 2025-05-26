import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/screens/auth/login_screen.dart';
import 'package:moodyr/widgets/custom_button.dart'; // Necessário para encontrar o CustomButton

void main() {
  // Helper para envolver o widget em teste com MaterialApp e Scaffold
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Campos vazios devem exibir mensagens de erro', (WidgetTester tester) async {
      // Renderiza a LoginScreen
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Tenta submeter o formulário (clicar no botão Entrar)
      // Primeiro, encontra o CustomButton. Pode ser necessário ajustar o Finder se houver mais de um.
      final Finder loginButton = find.widgetWithText(CustomButton, 'Entrar');
      expect(loginButton, findsOneWidget, reason: 'Botão "Entrar" não encontrado');
      await tester.tap(loginButton);
      await tester.pump(); // Reconstrói o widget após o tap para exibir erros

      // Verifica as mensagens de erro
      expect(find.text('E-mail Inválido'), findsOneWidget);
      expect(find.text('Senha Inválida '), findsOneWidget);
    });

    testWidgets('E-mail inválido deve exibir mensagem de erro para e-mail', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Encontra o campo de e-mail e insere um e-mail inválido
      final emailField = find.widgetWithText(TextFormField, 'Email'); // Procura pelo labelText
      expect(emailField, findsOneWidget, reason: 'Campo de texto "Email" não encontrado');
      await tester.enterText(emailField, 'emailinvalido');
      
      // Encontra o campo de senha e insere uma senha qualquer (válida ou não, para isolar o teste do email)
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      expect(passwordField, findsOneWidget, reason: 'Campo de texto "Senha" não encontrado');
      await tester.enterText(passwordField, 'Valida123'); // Senha válida para não interferir

      // Toca no botão de login
      final Finder loginButton = find.widgetWithText(CustomButton, 'Entrar');
      expect(loginButton, findsOneWidget, reason: 'Botão "Entrar" não encontrado');
      await tester.tap(loginButton);
      await tester.pump();

      // Verifica a mensagem de erro para o e-mail
      expect(find.text('E-mail Inválido'), findsOneWidget);
      // Garante que não há erro de senha, pois a senha inserida é válida
      expect(find.text('Senha Inválida '), findsNothing);
    });

    testWidgets('Senha inválida deve exibir mensagem de erro para senha', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // E-mail válido
      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget, reason: 'Campo de texto "Email" não encontrado');
      await tester.enterText(emailField, 'valido@email.com');

      // Senha inválida
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      expect(passwordField, findsOneWidget, reason: 'Campo de texto "Senha" não encontrado');
      await tester.enterText(passwordField, 'curta');
      
      final Finder loginButton = find.widgetWithText(CustomButton, 'Entrar');
      expect(loginButton, findsOneWidget, reason: 'Botão "Entrar" não encontrado');
      await tester.tap(loginButton);
      await tester.pump();

      // Verifica a mensagem de erro para a senha
      expect(find.text('Senha Inválida '), findsOneWidget);
      // Garante que não há erro de email
      expect(find.text('E-mail Inválido'), findsNothing);
    });

    testWidgets('Dados válidos não devem exibir mensagens de erro de validação', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // E-mail válido
      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget, reason: 'Campo de texto "Email" não encontrado');
      await tester.enterText(emailField, 'valido@email.com');

      // Senha válida
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      expect(passwordField, findsOneWidget, reason: 'Campo de texto "Senha" não encontrado');
      await tester.enterText(passwordField, 'ValidaSenha123');
      
      final Finder loginButton = find.widgetWithText(CustomButton, 'Entrar');
      expect(loginButton, findsOneWidget, reason: 'Botão "Entrar" não encontrado');
      await tester.tap(loginButton);
      await tester.pump(); // pump para processar o tap

      // Nenhuma mensagem de erro deve ser exibida para os validadores locais.
      // O teste não verifica a lógica de login (chamada HTTP), apenas a validação do formulário.
      expect(find.text('E-mail Inválido'), findsNothing);
      expect(find.text('Senha Inválida '), findsNothing);

      // Poderia verificar se o CircularProgressIndicator aparece, indicando que a validação passou
      // e a lógica de login foi acionada.
      // expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // No entanto, para evitar que o teste dependa da lógica de rede, vamos manter focado na validação.
    });
  });
}
