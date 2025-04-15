import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/validators/password_login_validator.dart';

void main() {
  group('Validação de Senha - Login', () {
    test('[Caixa-Preta] Senha Valida', () {
      expect(
          PasswordLoginValidator.isSecurePassWordLogin("Testesenha1234"), true);
    });
    test('[Caixa-Preta] Senha com menos de 8', () {
      expect(PasswordLoginValidator.isSecurePassWordLogin("Teste1"), false);
    });
    test('[Caixa-Preta] Senha sem letra maiuscula', () {
      expect(PasswordLoginValidator.isSecurePassWordLogin("teste1234"), false);
    });
  });
}
