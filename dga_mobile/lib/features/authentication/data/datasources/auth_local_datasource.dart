import '../../../../core/constants/storage_keys.dart';
import '../../../../services/storage_service.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> deleteRefreshToken();
  Future<void> saveUserEmail(String email);
  Future<String?> getUserEmail();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StorageService _storageService;

  const AuthLocalDataSourceImpl(this._storageService);

  @override
  Future<void> saveToken(String token) async {
    await _storageService.writeSecure(StorageKeys.token, token);
  }

  @override
  Future<String?> getToken() async {
    return await _storageService.readSecure(StorageKeys.token);
  }

  @override
  Future<void> deleteToken() async {
    await _storageService.deleteSecure(StorageKeys.token);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await _storageService.writeSecure(StorageKeys.refreshToken, token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _storageService.readSecure(StorageKeys.refreshToken);
  }

  @override
  Future<void> deleteRefreshToken() async {
    await _storageService.deleteSecure(StorageKeys.refreshToken);
  }

  @override
  Future<void> saveUserEmail(String email) async {
    await _storageService.setString('remembered_user_email', email);
  }

  @override
  Future<String?> getUserEmail() async {
    return _storageService.getString('remembered_user_email');
  }

  @override
  Future<void> clearSession() async {
    await _storageService.deleteSecure(StorageKeys.token);
    await _storageService.deleteSecure(StorageKeys.refreshToken);
  }
}
