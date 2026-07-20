import '../../../../core/network/result.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<Result<UserEntity>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (email.contains('@') && password.length >= 6) {
      const user = UserEntity(
        fullName: 'Nguyễn Văn Nông (Mock)',
        email: 'nongdan@dga.vn',
        role: 'Nông dân',
        phoneNumber: '0987654321',
        workUnit: 'Hợp tác xã Sầu riêng Phong Điền',
        address: 'Phong Điền, Cần Thơ',
        dob: '15/08/1985',
        gender: 'Nam',
        farmInfo: FarmEntity(
          farmName: 'Vườn Sầu Riêng Phong Điền',
          farmCode: 'DGA-FARM-99',
          address: 'Phong Điền, Cần Thơ',
          treeCount: 368,
          joinedDate: '15/05/2024',
        ),
      );
      return const Success(user);
    }
    return const Failure('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin!');
  }

  @override
  Future<Result<UserEntity>> register(String fullName, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return const Failure('Tính năng đăng ký mock chưa khả dụng.');
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    // Giả lập mạng trễ 1.0s
    await Future.delayed(const Duration(milliseconds: 1000));
    if (email.contains('@')) {
      return const Success(null);
    }
    return const Failure('Email không đúng định dạng');
  }

  @override
  Future<Result<UserEntity>> getMe() async {
    return const Success(UserEntity(
      fullName: 'Nguyễn Văn Nông (Mock)',
      email: 'nongdan@dga.vn',
      role: 'Nông dân',
      phoneNumber: '0987654321',
      workUnit: 'Hợp tác xã Sầu riêng Phong Điền',
      address: 'Phong Điền, Cần Thơ',
      dob: '15/08/1985',
      gender: 'Nam',
    ));
  }

  @override
  Future<Result<void>> logout() async {
    return const Success(null);
  }

  @override
  Future<Result<bool>> checkAutoLogin() async {
    return const Success(false);
  }
}
