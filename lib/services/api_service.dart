import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../models/register_request.dart';

class ApiService {
  static const String baseUrl = 'https://forceless-kit-flyable.ngrok-free.dev';
  
  // Helper method to get headers
  static Map<String, String> getHeaders({String? accessToken}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return headers;
  }

  // POST /auth/register
  static Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw Exception('Validation Error: ${errorData['detail']}');
      } else {
        throw Exception('Đăng ký thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // POST /auth/login
  static Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw Exception('Validation Error: ${errorData['detail']}');
      } else {
        throw Exception('Đăng nhập thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // POST /auth/refresh
  static Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: getHeaders(),
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else {
        throw Exception('Refresh token thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // POST /auth/logout
  static Future<String> logout(
    String accessToken,
    String refreshToken,
    String tokenType,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: getHeaders(accessToken: accessToken),
        body: jsonEncode({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'token_type': tokenType,
        }),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Đăng xuất thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // POST /auth/change-password
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: getHeaders(accessToken: accessToken),
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? 'Đổi mật khẩu thất bại';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }
}
















