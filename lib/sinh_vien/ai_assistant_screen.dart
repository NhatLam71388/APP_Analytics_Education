import 'dart:ui';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/chatbot_api_service.dart';
import '../models/chatbot_response.dart';
import '../services/xunfei_ist_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? mdxGenerated;
  final String? model;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.mdxGenerated,
    this.model,
  });
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isTtsEnabled = true; // Mặc định bật TTS
  bool _isRecording = false; // Trạng thái ghi âm

  late FlutterTts _flutterTts;
  late AudioRecorder _audioRecorder;
  late XunfeiISTService _xunfeiService;
  StreamSubscription<String>? _textSubscription;
  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<List<int>>? _audioStreamSubscription;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    // Thêm welcome message sau khi services đã được khởi tạo
    final welcomeText = 'Xin chào! Tôi là trợ lý AI của bạn. Tôi có thể giúp gì cho bạn?';
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      
      // Phát âm welcome message sau khi TTS đã được khởi tạo
      // Đợi một chút để đảm bảo TTS đã sẵn sàng
      Future.delayed(const Duration(milliseconds: 800)).then((_) {
        if (mounted) {
          _speak(welcomeText);
        }
      });
    }
  }

  Future<void> _initializeServices() async {
    // Khởi tạo TTS và Speech-to-Text
    await _initTts();
    _initSpeechToText();
  }

  Future<void> _initTts() async {
    try {
      debugPrint('TTS: Initializing with flutter_tts ^4.2.3...');
      _flutterTts = FlutterTts();
      
      // Xử lý khi hoàn thành phát âm
      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS: Speech completed');
      });
      
      // Xử lý lỗi
      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTS Error Handler: $msg");
      });
      
      // BẮT BUỘC: Phải gọi setLanguage("vi-VN") trước khi speak
      // Theo tài liệu flutter_tts ^4.2.3 cho tiếng Việt
      debugPrint('TTS: Setting language to vi-VN...');
      await _flutterTts.setLanguage("vi-VN");
      debugPrint('TTS: Language set to vi-VN successfully');
      
      // Cấu hình TTS
      await _flutterTts.setSpeechRate(0.5); // Tốc độ nói (0.0 - 1.0)
      await _flutterTts.setVolume(1.0); // Âm lượng (0.0 - 1.0)
      await _flutterTts.setPitch(1.0); // Cao độ (0.5 - 2.0)
      
      debugPrint('TTS: Initialization completed successfully');
    } catch (e) {
      debugPrint('TTS: Initialization error: $e');
      // Thử fallback với en-US nếu vi-VN không có
      try {
        debugPrint('TTS: Trying fallback to en-US...');
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        debugPrint('TTS: Fallback to en-US successful');
      } catch (e2) {
        debugPrint('TTS: Fallback also failed: $e2');
      }
    }
  }

  Future<void> _initSpeechToText() async {
    _audioRecorder = AudioRecorder();
    _xunfeiService = XunfeiISTService();
    
    // Lắng nghe text được nhận dạng
    _textSubscription = _xunfeiService.textStream.listen((text) {
      if (mounted) {
        setState(() {
          _messageController.text += text;
        });
      }
    });
    
    // Lắng nghe trạng thái
    _statusSubscription = _xunfeiService.statusStream.listen((status) {
      debugPrint('Xunfei Status: $status');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _typingController.dispose();
    _flutterTts.stop();
    _audioRecorder.dispose();
    _textSubscription?.cancel();
    _statusSubscription?.cancel();
    _audioStreamSubscription?.cancel();
    _xunfeiService.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (!_isTtsEnabled) {
      debugPrint('TTS: Disabled, skipping speech');
      return;
    }
    
    if (text.isEmpty) {
      debugPrint('TTS: Empty text, skipping speech');
      return;
    }
    
    try {
      debugPrint('TTS: Speaking text: $text');
      // Với flutter_tts ^4.2.3, chỉ cần gọi speak() sau khi đã setLanguage
      final result = await _flutterTts.speak(text);
      
      if (result == 1) {
        debugPrint('TTS: speak() called successfully');
      } else {
        debugPrint('TTS: speak() returned error code: $result');
      }
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("Error stopping TTS: $e");
    }
  }

  /// Bắt đầu ghi âm và nhận dạng giọng nói
  Future<void> _startRecording() async {
    // Kiểm tra quyền microphone
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần quyền truy cập microphone để sử dụng tính năng này'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Kết nối Xunfei service
      await _xunfeiService.connect();
      
      // Bắt đầu ghi âm với stream
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      setState(() {
        _isRecording = true;
      });

      // Lắng nghe audio stream và gửi đến Xunfei
      _audioStreamSubscription = stream.listen(
        (data) {
          if (_isRecording && _xunfeiService.isConnected) {
            try {
              _xunfeiService.sendAudioData(Uint8List.fromList(data));
            } catch (e) {
              debugPrint('Error sending audio data: $e');
            }
          }
        },
        onError: (error) {
          debugPrint('Error in audio stream: $error');
          if (mounted) {
            setState(() {
              _isRecording = false;
            });
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi bắt đầu ghi âm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// Dừng ghi âm và nhận dạng
  Future<void> _stopRecording() async {
    try {
      // Hủy subscription audio stream
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      // Gửi frame cuối cùng
      _xunfeiService.sendFinalFrame();
      
      // Đợi một chút trước khi ngắt kết nối để nhận kết quả cuối cùng
      await Future.delayed(const Duration(milliseconds: 1000));
      
      await _xunfeiService.disconnect();

      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final question = _messageController.text.trim();
    if (question.isEmpty || _isLoading) return;

    // Thêm câu hỏi của user vào danh sách
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
      _errorMessage = null;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      final response = await ChatbotApiService.askChatBot(question: question);

      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          text: response.answer,
          isUser: false,
          timestamp: DateTime.now(),
          mdxGenerated: response.mdxGenerated,
          model: response.model,
        ));
        _isLoading = false;
      });

      // Scroll to bottom after response
      _scrollToBottom();
      
      // Phát âm thanh response từ AI
      _speak(response.answer);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _messages.add(ChatMessage(
          text: 'Xin lỗi, đã có lỗi xảy ra: $_errorMessage',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50.withValues(alpha: 0.3),
              Colors.blue.shade50.withValues(alpha: 0.2),
              const Color(0xFFF5F7FA),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.teal.shade500,
                          Colors.teal.shade700,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trợ lý AI',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hỗ trợ học tập thông minh',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Nút bật/tắt TTS
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _isTtsEnabled = !_isTtsEnabled;
                                if (!_isTtsEnabled) {
                                  _stopSpeaking();
                                }
                              });
                            },
                            tooltip: _isTtsEnabled ? 'Tắt giọng nói' : 'Bật giọng nói',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Messages
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              // Loading indicator
                              return _buildTypingIndicator();
                            }
                            return _buildMessageBubble(_messages[index], index);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Input Area
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Nút microphone
                          Container(
                            decoration: BoxDecoration(
                              color: _isRecording 
                                  ? Colors.red.shade500 
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: _isRecording ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isRecording ? _stopRecording : _startRecording,
                                borderRadius: BorderRadius.circular(26),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(14),
                                  child: _isRecording
                                      ? const Icon(
                                          Icons.mic,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : Icon(
                                          Icons.mic_none,
                                          color: Colors.grey.shade700,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 120),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Nhập câu hỏi của bạn...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 15),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.teal.shade500,
                                  Colors.teal.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _sendMessage,
                                borderRadius: BorderRadius.circular(26),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(14),
                                  child: _isLoading
                                      ? LoadingAnimationWidget.staggeredDotsWave(
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade400,
                      Colors.teal.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: message.isUser
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.teal.shade500,
                            Colors.teal.shade600,
                          ],
                        )
                      : null,
                  color: message.isUser ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(message.isUser ? 24 : 8),
                    bottomRight: Radius.circular(message.isUser ? 8 : 24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: message.isUser
                          ? Colors.teal.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: message.isUser ? Colors.white : Colors.grey.shade800,
                        height: 1.6,
                        fontWeight: message.isUser ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    if (message.model != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (message.isUser
                                  ? Colors.teal.shade700
                                  : Colors.grey.shade100)
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology_rounded,
                              size: 12,
                              color: message.isUser
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              message.model!,
                              style: TextStyle(
                                fontSize: 11,
                                color: message.isUser
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _typingController,
            builder: (context, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade400,
                      Colors.teal.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(
                        alpha: 0.3 + (0.2 * (0.5 + 0.5 * (1 - _typingController.value))),
                      ),
                      blurRadius: 12,
                      spreadRadius: 2 * (0.5 + 0.5 * (1 - _typingController.value)),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _typingController,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final animationValue = (_typingController.value + delay) % 1.0;
                        final opacity = (animationValue < 0.5)
                            ? 0.3 + (animationValue * 1.4)
                            : 1.0 - ((animationValue - 0.5) * 1.4);
                        final scale = 0.8 + (animationValue < 0.5 ? animationValue * 0.4 : (1 - animationValue) * 0.4);

                        return Container(
                          margin: EdgeInsets.only(
                            right: index < 2 ? 6 : 0,
                          ),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade600.withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                          transform: Matrix4.identity()..scale(scale),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI đang suy nghĩ...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
