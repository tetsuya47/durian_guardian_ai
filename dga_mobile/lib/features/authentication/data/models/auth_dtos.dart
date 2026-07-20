class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) {
    return LoginRequestDto(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }
}

class LoginResponseDto {
  final String accessToken;
  final String tokenType;
  final String refreshToken;
  final int? expiresIn; // in seconds
  final String? email;
  final String? fullName;

  const LoginResponseDto({
    required this.accessToken,
    required this.tokenType,
    required this.refreshToken,
    this.expiresIn,
    this.email,
    this.fullName,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: json['expires_in'] as int?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'email': email,
      'full_name': fullName,
    };
  }
}

class ForgotPasswordRequestDto {
  final String email;

  const ForgotPasswordRequestDto({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }

  factory ForgotPasswordRequestDto.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordRequestDto(
      email: json['email'] as String,
    );
  }
}

class UserOutDto {
  final String id;
  final String userCode;
  final String fullName;
  final String email;
  final String role;
  final String createdAt;

  const UserOutDto({
    required this.id,
    required this.userCode,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserOutDto.fromJson(Map<String, dynamic> json) {
    return UserOutDto(
      id: json['id'] as String? ?? '',
      userCode: json['user_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_code': userCode,
      'full_name': fullName,
      'email': email,
      'role': role,
      'created_at': createdAt,
    };
  }
}

class TokenRefreshRequestDto {
  final String refreshToken;

  const TokenRefreshRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }

  factory TokenRefreshRequestDto.fromJson(Map<String, dynamic> json) {
    return TokenRefreshRequestDto(
      refreshToken: json['refresh_token'] as String,
    );
  }
}

class RegisterRequestDto {
  final String fullName;
  final String email;
  final String password;

  const RegisterRequestDto({
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'password': password,
    };
  }
}
