import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/validators/password_register_validator.dart';

void main() {
  group('Validação de Senha - Register', () {
    test('[Caixa-Preta] Senha Valida', () {
      expect(
          PasswordRegisterValidator.isSecurePassWordRegister("Testesenha1234"),
          true);
    });
    test('[Caixa-Preta] Senha com menos de 8', () {
      expect(
          PasswordRegisterValidator.isSecurePassWordRegister("Teste1"), false);
    });
    test('[Caixa-Preta] Senha sem letra maiuscula', () {
      expect(PasswordRegisterValidator.isSecurePassWordRegister("teste1234"),
          false);
    });
  });
}
