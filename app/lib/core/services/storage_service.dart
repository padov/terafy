import 'package:common/common.dart';
import 'package:terafy/core/services/secure_storage_service.dart';

class StorageService {
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<void> saveToken(String token) async {
    AppLogger.func();
    await _secureStorage.saveToken(token);
  }

  Future<String?> getToken() async {
    AppLogger.func();
    return await _secureStorage.getToken();
  }

  Future<void> removeToken() async {
    AppLogger.func();
    await _secureStorage.deleteToken();
  }
}
