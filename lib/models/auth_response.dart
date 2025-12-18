import 'user.dart';

class AuthResponse {
  final String? message;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final User? userInfo;

  AuthResponse({
    this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    this.userInfo,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      userInfo: json['user_info'] != null
          ? User.fromJson(json['user_info'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'user_info': userInfo?.toJson(),
    };
  }
}



















