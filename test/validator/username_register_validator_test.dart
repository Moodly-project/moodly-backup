import 'package:flutter_test/flutter_test.dart';
import 'package:moodyr/validators/username_register_validator.dart';

void main() {
  group('Validação de Nome - Register', () {
    test('[Caixa-Preta] Nome Valido', () {
      expect(UsernameRegisterValidator.isValidUsernameRegister("Teste Nóme"),
          true);
    });
    test('[Caixa-Preta] Nome com numero', () {
      expect(UsernameRegisterValidator.isValidUsernameRegister("Teste N0me"),
          false);
    });
    test('[Caixa-Preta] Nome com símbolo', () {
      expect(UsernameRegisterValidator.isValidUsernameRegister("@Teste Nome!"),
          false);
    });
  });
}
