import '../../../../core/network/result.dart';
import '../../../../core/errors/failure.dart' as err;
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_dtos.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  const AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Result<UserEntity>> login(String email, String password) async {
    try {
      final responseDto = await _remoteDataSource.login(
        LoginRequestDto(email: email, password: password),
      );

      await _localDataSource.saveToken(responseDto.accessToken);
      await _localDataSource.saveRefreshToken(responseDto.refreshToken);
      await _localDataSource.saveUserEmail(email);

      final userDto = await _remoteDataSource.getMe();
      final userEntity = _mapDtoToEntity(userDto);

      return Success(userEntity);
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }

  @override
  Future<Result<UserEntity>> register(String fullName, String email, String password) async {
    try {
      // Register creates the account on backend
      await _remoteDataSource.register(
        RegisterRequestDto(fullName: fullName, email: email, password: password),
      );

      // Auto-login after registration
      final loginDto = await _remoteDataSource.login(
        LoginRequestDto(email: email, password: password),
      );

      await _localDataSource.saveToken(loginDto.accessToken);
      await _localDataSource.saveRefreshToken(loginDto.refreshToken);
      await _localDataSource.saveUserEmail(email);

      final userDto = await _remoteDataSource.getMe();
      final userEntity = _mapDtoToEntity(userDto);

      return Success(userEntity);
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(ForgotPasswordRequestDto(email: email));
      return const Success(null);
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }

  @override
  Future<Result<UserEntity>> getMe() async {
    try {
      final userDto = await _remoteDataSource.getMe();
      final userEntity = _mapDtoToEntity(userDto);
      return Success(userEntity);
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Notify backend if possible (revokes token)
      await _remoteDataSource.logout();
    } catch (_) {
      // Suppress backend logout errors to ensure local logout still completes
    } finally {
      await _localDataSource.clearSession();
    }
    return const Success(null);
  }

  @override
  Future<Result<bool>> checkAutoLogin() async {
    try {
      final token = await _localDataSource.getToken();
      final refreshToken = await _localDataSource.getRefreshToken();
      if (token == null || token.isEmpty || refreshToken == null || refreshToken.isEmpty) {
        return const Success(false);
      }

      // Verify session by calling /auth/me
      await _remoteDataSource.getMe();
      return const Success(true);
    } catch (_) {
      // If /auth/me fails (e.g. token expired, network offline), return false
      return const Success(false);
    }
  }

  UserEntity _mapDtoToEntity(UserOutDto dto) {
    // Translate backend roles to friendly Vietnamese labels for UI
    String uiRole = 'Nông dân';
    switch (dto.role) {
      case 'enterprise_admin':
      case 'Admin':
        uiRole = 'Quản trị viên';
        break;
      case 'farm_manager':
      case 'Farm Manager':
      case 'Company Manager':
        uiRole = 'Quản lý';
        break;
      case 'field_technician':
      case 'Inspector':
        uiRole = 'Kỹ thuật viên';
        break;
      case 'farmer':
      case 'Technician':
      default:
        uiRole = 'Nông dân';
        break;
    }

    return UserEntity(
      fullName: dto.fullName,
      email: dto.email,
      role: uiRole,
      phoneNumber: '', // Not in UserOut backend schema, default empty
      workUnit: '', // Not in UserOut backend schema, default empty
      address: '', // Not in UserOut backend schema, default empty
      dob: '', // Not in UserOut backend schema, default empty
      gender: '', // Not in UserOut backend schema, default empty
      farmInfo: null, // Separated feature - resolved dynamically
    );
  }
}
