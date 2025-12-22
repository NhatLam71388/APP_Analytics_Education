import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class XunfeiISTService {
  // API credentials từ hình ảnh
  static const String appId = 'ga86e7f6';
  static const String apiKey = 'ac78cc24dda8c3c77f9c12ad18ff6011';
  static const String apiSecret = 'b1068fbc01b03c3eccad1d34b4a96c8a';
  static const String host = 'ist-api-sg.xf-yun.com';
  static const String path = '/v2/ist';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<String> _textController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  bool _isConnected = false;
  bool _isRecording = false;

  // Stream để lắng nghe text được nhận dạng
  Stream<String> get textStream => _textController.stream;
  
  // Stream để lắng nghe trạng thái
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;

  /// Chuyển đổi DateTime sang RFC1123 format (GMT)
  String _toRFC1123(DateTime dateTime) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final utc = dateTime.toUtc();
    final weekday = weekdays[utc.weekday - 1];
    final month = months[utc.month - 1];
    final day = utc.day.toString().padLeft(2, '0');
    final year = utc.year.toString();
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    
    return '$weekday, $day $month $year $hour:$minute:$second GMT';
  }

  /// Tạo authorization parameters
  Map<String, String> _generateAuthParams() {
    final now = DateTime.now().toUtc();
    // Sử dụng RFC1123 format (GMT) thay vì ISO-8601
    final date = _toRFC1123(now);

    // Tạo signature với format đúng
    // host: <host>
    // date: <RFC1123 GMT>
    // GET <path> HTTP/1.1
    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';
    final key = utf8.encode(apiSecret);
    final bytes = utf8.encode(signatureOrigin);
    final hmacSha256 = Hmac(sha256, key);
    final signature = base64Encode(hmacSha256.convert(bytes).bytes);

    // Tạo authorization
    final authorizationOrigin = 'api_key="$apiKey", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';
    final authorization = base64Encode(utf8.encode(authorizationOrigin));

    debugPrint('Date (RFC1123): $date');
    debugPrint('Signature origin: $signatureOrigin');
    debugPrint('Signature: $signature');

    return {
      'authorization': authorization,
      'date': date,
      'host': host,
    };
  }

  /// Kết nối WebSocket
  Future<void> connect() async {
    if (_isConnected) {
      return;
    }

    try {
      final params = _generateAuthParams();
      
      // URL encode các parameters thủ công để đảm bảo format đúng
      final authEncoded = Uri.encodeComponent(params['authorization']!);
      final dateEncoded = Uri.encodeComponent(params['date']!);
      final hostEncoded = Uri.encodeComponent(params['host']!);
      
      // Tạo WebSocket URI - không chỉ định port (dùng default)
      // Giống Python code: wss://ist-api-sg.xf-yun.com/v2/ist (không có port)
      final wsUri = Uri(
        scheme: 'wss',
        host: host,
        port: null, // Không chỉ định port, dùng default
        path: path,
        queryParameters: {
          'authorization': params['authorization']!, // Không encode lại vì queryParameters tự encode
          'date': params['date']!,
          'host': params['host']!,
        },
      );
      
      debugPrint('Connecting to WebSocket: $wsUri');
      debugPrint('URI scheme: ${wsUri.scheme}, host: ${wsUri.host}, port: ${wsUri.port}, path: ${wsUri.path}');
      debugPrint('Query params: ${wsUri.queryParameters}');
      debugPrint('Authorization (raw): ${params['authorization']}');
      
      // Sử dụng WebSocketChannel.connect với URI đã parse
      _channel = WebSocketChannel.connect(wsUri);

      // Đợi một chút để kết nối được thiết lập
      await Future.delayed(const Duration(milliseconds: 300));
      
      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
          // Chỉ set connected = true sau khi nhận được message đầu tiên từ server
          if (!_isConnected) {
            _isConnected = true;
            _statusController.add('Đã kết nối thành công');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _statusController.add('Lỗi kết nối: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _statusController.add('Kết nối đã đóng');
          _isConnected = false;
        },
        cancelOnError: false,
      );

      // Gửi message khởi tạo ngay sau khi kết nối
      // Không set _isConnected = true ở đây, đợi response từ server
      _sendInitMessage();
      
      // Đợi một chút để xem có lỗi không
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Nếu không có lỗi, coi như đã kết nối
      if (!_isConnected) {
        _isConnected = true;
        _statusController.add('Đã kết nối');
      }
    } catch (e) {
      debugPrint('Connection error: $e');
      _statusController.add('Lỗi khi kết nối: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Gửi message khởi tạo
  void _sendInitMessage() {
    final initMessage = {
      'common': {
        'app_id': appId,
      },
        'business': {
          'language': 'vi_vn', // Tiếng Việt - giống Python code
          'domain': 'ist_open', // Domain đúng theo Python code
          'accent': 'mandarin',
        },
      'data': {
        'status': 0, // 0: first frame, 1: continue, 2: last frame
        'format': 'audio/L16;rate=16000', // PCM 16bit 16kHz
        'encoding': 'raw',
        'audio': '',
      },
    };

    debugPrint('Sending init message: ${jsonEncode(initMessage)}');
    _channel?.sink.add(jsonEncode(initMessage));
  }

  /// Xử lý message nhận được
  void _handleMessage(dynamic message) {
    try {
      debugPrint('Received message: $message');
      final data = jsonDecode(message.toString());
      
      // Kiểm tra lỗi từ server
      if (data['code'] != null && data['code'] != 0) {
        final errorMsg = data['message'] ?? data['desc'] ?? 'Unknown error';
        debugPrint('Server error: code=${data['code']}, message=$errorMsg');
        _statusController.add('Lỗi từ server: $errorMsg');
        _isConnected = false;
        return;
      }

      // Nếu có sid, có nghĩa là kết nối thành công
      if (data['sid'] != null) {
        debugPrint('Connection established with sid: ${data['sid']}');
        if (!_isConnected) {
          _isConnected = true;
          _statusController.add('Đã kết nối thành công');
        }
      }

      if (data['data'] != null) {
        final dataObj = data['data'];
        final result = dataObj['result'];
        
        if (result != null) {
          final ws = result['ws'];
          if (ws != null) {
            String fullText = '';
            for (var item in ws) {
              final cw = item['cw'];
              if (cw != null) {
                for (var word in cw) {
                  fullText += word['w'] ?? '';
                }
              }
            }
            
            if (fullText.isNotEmpty) {
              debugPrint('Recognized text: $fullText');
              _textController.add(fullText);
            }
          }
        }

        // Kiểm tra status
        final status = dataObj['status'];
        if (status == 2) {
          // Kết thúc nhận dạng
          _statusController.add('Hoàn thành nhận dạng');
        }
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
      _statusController.add('Lỗi xử lý message: $e');
    }
  }

  /// Gửi audio data
  void sendAudioData(Uint8List audioData) {
    if (!_isConnected || _channel == null) {
      return;
    }

    try {
      // Chuyển đổi audio data thành base64
      final audioBase64 = base64Encode(audioData);

      final message = {
        'data': {
          'status': 1, // 1: continue frame
          'format': 'audio/L16;rate=16000',
          'encoding': 'raw',
          'audio': audioBase64,
        },
      };

      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      _statusController.add('Lỗi gửi audio: $e');
    }
  }

  /// Gửi frame cuối cùng
  void sendFinalFrame() {
    if (!_isConnected || _channel == null) {
      return;
    }

    try {
      final message = {
        'data': {
          'status': 2, // 2: last frame
          'format': 'audio/L16;rate=16000',
          'encoding': 'raw',
          'audio': '',
        },
      };

      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      _statusController.add('Lỗi gửi frame cuối: $e');
    }
  }

  /// Ngắt kết nối
  Future<void> disconnect() async {
    if (_channel != null) {
      await _subscription?.cancel();
      await _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _isRecording = false;
  }

  /// Đóng service
  void dispose() {
    disconnect();
    _textController.close();
    _statusController.close();
  }
}

