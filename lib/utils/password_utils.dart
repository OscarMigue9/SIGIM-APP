import 'package:bcrypt/bcrypt.dart';

class PasswordUtils {
  static const int minLength = 8;

  static String hash(String plain) {
    return BCrypt.hashpw(plain, BCrypt.gensalt());
  }

  static bool verify(String plain, String stored) {
    if (isHashed(stored)) {
      return BCrypt.checkpw(plain, stored);
    }
    return plain == stored; // Legacy fallback
  }

  static bool isHashed(String value) => value.startsWith(r'$2');

  static bool meetsPolicy(String password) {
    if (password.length < minLength) return false;
    final hasUpper = password.contains(RegExp(r'[A-ZÁÉÍÓÚÑ]'));
    final hasLower = password.contains(RegExp(r'[a-záéíóúñ]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasSymbol = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
    return hasUpper && hasLower && hasDigit && hasSymbol;
  }

  static String? validate(String password) {
    if (password.length < minLength) {
      return 'Debe tener al menos $minLength caracteres';
    }
    if (!password.contains(RegExp(r'[A-ZÁÉÍÓÚÑ]'))) {
      return 'Debe incluir una mayúscula';
    }
    if (!password.contains(RegExp(r'[a-záéíóúñ]'))) {
      return 'Debe incluir una minúscula';
    }
    if (!password.contains(RegExp(r'\d'))) {
      return 'Debe incluir un número';
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) {
      return 'Debe incluir un símbolo';
    }
    return null;
  }
}