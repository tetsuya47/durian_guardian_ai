import '../../../../core/network/result.dart';
import '../entities/profile_entities.dart';

abstract class ProfileRepository {
  Future<Result<UserProfileEntity>> getUserProfile();
  Future<Result<UserProfileEntity>> updateUserProfile(String fullName, String email, String phoneNumber);
}
