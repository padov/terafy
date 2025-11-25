import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordService {
  // Gera hash SHA-256 da senha (em produção, use bcrypt ou argon2)
  // Para produção, considere usar: https://pub.dev/packages/argon2
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verifica se a senha corresponde ao hash
  static bool verifyPassword(String password, String hash) {
    final passwordHash = hashPassword(password);
    return passwordHash == hash;
  }
}
