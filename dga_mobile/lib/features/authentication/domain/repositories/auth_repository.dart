import '../../../../core/network/result.dart';
import '../entities/auth_entities.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> login(String email, String password);
  Future<Result<UserEntity>> register(String fullName, String email, String password);
  Future<Result<void>> forgotPassword(String email);
  Future<Result<UserEntity>> getMe();
  Future<Result<void>> logout();
  Future<Result<bool>> checkAutoLogin();
}
