import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _userInfoKey = 'user_info';

  // Save authentication data
  static Future<void> saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Đảm bảo token không có khoảng trắng thừa
    final cleanAccessToken = authResponse.accessToken.trim();
    final cleanRefreshToken = authResponse.refreshToken.trim();
    final cleanTokenType = authResponse.tokenType.trim();
    
    await prefs.setString(_accessTokenKey, cleanAccessToken);
    await prefs.setString(_refreshTokenKey, cleanRefreshToken);
    await prefs.setString(_tokenTypeKey, cleanTokenType);
    
    if (authResponse.userInfo != null) {
      await prefs.setString(_userInfoKey, 
        '${authResponse.userInfo!.maNguoiDung}|${authResponse.userInfo!.username}|${authResponse.userInfo!.loaiNguoiDung}|${authResponse.userInfo!.hoTen}');
    }
    
    // Verify token đã được lưu
    final savedToken = prefs.getString(_accessTokenKey);
    if (savedToken == null || savedToken.isEmpty) {
      throw Exception('Lỗi: Không thể lưu access token');
    }
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get token type
  static Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey);
  }

  // Get user info
  static Future<User?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(_userInfoKey);
    
    if (userInfoString != null) {
      final parts = userInfoString.split('|');
      if (parts.length == 4) {
        return User(
          maNguoiDung: int.tryParse(parts[0]) ?? 0,
          username: parts[1],
          loaiNguoiDung: parts[2],
          hoTen: parts[3],
        );
      }
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // Clear authentication data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_userInfoKey);
  }
}





