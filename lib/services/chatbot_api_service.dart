import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/chatbot_response.dart';

class ChatbotApiService {
  static const String baseUrl = ApiService.baseUrl;

  // Helper method to get headers with auth token
  static Future<Map<String, String>> getHeaders() async {
    final accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Không có access token. Vui lòng đăng nhập lại.');
    }

    final cleanToken = accessToken.trim();
    final headers = ApiService.getHeaders(accessToken: cleanToken);
    headers['ngrok-skip-browser-warning'] = 'true';

    return headers;
  }

  // POST /chatbot/ask_chat_bot
  static Future<ChatbotResponse> askChatBot({
    required String question,
    String sessionId = 'default',
  }) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        Uri.parse('$baseUrl/chatbot/ask_chat_bot'),
        headers: headers,
        body: jsonEncode({
          'question': question,
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ChatbotResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }
}






