import '../models/profile_dtos.dart';

abstract class ProfileLocalDataSource {
  Future<void> saveUserProfile(UserProfileResponseDto profile);
  Future<UserProfileResponseDto?> getCachedUserProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  const ProfileLocalDataSourceImpl();

  @override
  Future<void> saveUserProfile(UserProfileResponseDto profile) => throw UnimplementedError();

  @override
  Future<UserProfileResponseDto?> getCachedUserProfile() => throw UnimplementedError();
}
