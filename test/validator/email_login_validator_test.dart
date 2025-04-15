import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/validators/email_login_validator.dart';

void main() {
  group('Validação de E-mail - Login', () {
    test('[Caixa-Preta] E-mail Valido', () {
      expect(
          EmailLoginValidator.isValidEmailLogin("teste.email_123@gmail.com.br"),
          true);
    });
    test('[Caixa-Preta] E-mail sem @', () {
      expect(
          EmailLoginValidator.isValidEmailLogin("emailsemarroba.com"), false);
    });
    test('[Caixa-Preta] Sem usuario antes do @', () {
      expect(EmailLoginValidator.isValidEmailLogin("@teste.com"), false);
    });
    test('[Caixa-Preta] Sem domínio depois do @', () {
      expect(EmailLoginValidator.isValidEmailLogin("testeemail@.com"), false);
    });
    test('[Caixa-Preta] Letra com acento (Í)', () {
      expect(
          EmailLoginValidator.isValidEmailLogin("testeemail@gmaíl.com"), false);
    });
    test('[Caixa-Preta] Não aceita TDLs > 4 e < 2', () {
      expect(
          EmailLoginValidator.isValidEmailLogin(
              "teste.email_123@gmail.com.online"),
          false);
    });
  });
}
