import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/validators/email_register_validator.dart';

void main() {
  group('Validação de E-mail - Register', () {
    test('[Caixa-Preta] E-mail Valido', () {
      expect(
          EmailRegisterValidator.isValidEmailRegister(
              "teste.email_123@gmail.com.br"),
          true);
    });
    test('[Caixa-Preta] E-mail sem @', () {
      expect(EmailRegisterValidator.isValidEmailRegister("emailsemarroba.com"),
          false);
    });
    test('[Caixa-Preta] Sem usuario antes do @', () {
      expect(EmailRegisterValidator.isValidEmailRegister("@teste.com"), false);
    });
    test('[Caixa-Preta] Sem domínio depois do @', () {
      expect(EmailRegisterValidator.isValidEmailRegister("testeemail@.com"),
          false);
    });
    test('[Caixa-Preta] Letra com acento (Í)', () {
      expect(
          EmailRegisterValidator.isValidEmailRegister("testeemail@gmaíl.com"),
          false);
    });
    test('[Caixa-Preta] Não aceita TDLs > 4 e < 2', () {
      expect(
          EmailRegisterValidator.isValidEmailRegister(
              "teste.email_123@gmail.com.online"),
          false);
    });
  });
}
