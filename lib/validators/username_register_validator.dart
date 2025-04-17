class UsernameRegisterValidator {
  static bool isValidUsernameRegister(String username) {
    if (username.length < 2) return false;
    if (!username.contains(RegExp(r'^[A-Za-zÀ-ÿ\s]+$'))) return false;
    return true;
  }
}
