class EmailLoginValidator {
  static bool isValidEmailLogin(String email) {
    if (!email.contains(RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')))
      return false;
    return true;
  }
}
