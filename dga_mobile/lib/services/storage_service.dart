import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  // Thường SharedPreferences sẽ được khởi tạo trong main và ghi đè (override) trong ProviderScope.
  // Ở đây chúng ta khai báo skeleton và cho phép khởi tạo động.
  throw UnimplementedError('SharedPreferences must be initialized first in main');
});

class StorageService {
  final SharedPreferences _sharedPreferences;
  final FlutterSecureStorage _secureStorage;

  StorageService(this._sharedPreferences, this._secureStorage);

  // SharedPreferences Methods
  Future<bool> setString(String key, String value) async {
    return await _sharedPreferences.setString(key, value);
  }

  String? getString(String key) {
    return _sharedPreferences.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _sharedPreferences.setBool(key, value);
  }

  bool? getBool(String key) {
    return _sharedPreferences.getBool(key);
  }

  Future<bool> remove(String key) async {
    return await _sharedPreferences.remove(key);
  }

  Future<bool> clear() async {
    return await _sharedPreferences.clear();
  }

  // Secure Storage Methods
  Future<void> writeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }
}
