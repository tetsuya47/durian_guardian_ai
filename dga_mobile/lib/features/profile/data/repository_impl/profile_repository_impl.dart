import '../../../../core/network/result.dart';
import '../../../../core/errors/failure.dart' as err;
import '../../domain/entities/profile_entities.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<UserProfileEntity>> getUserProfile() async {
    try {
      final dto = await _remoteDataSource.getUserProfile();
      return Success(dto.toDomain());
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }

  @override
  Future<Result<UserProfileEntity>> updateUserProfile(
      String fullName, String email, String phoneNumber) async {
    try {
      final dto = await _remoteDataSource.updateUserProfile(fullName, email, phoneNumber);
      return Success(dto.toDomain());
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }
}
