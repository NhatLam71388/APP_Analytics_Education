import 'package:flutter/material.dart';

enum NotificationType {
  error,
  success,
  warning,
  info,
}

class UserNotification {
  /// Hiển thị thông báo cho người dùng
  /// 
  /// [context] - BuildContext của widget
  /// [message] - Nội dung thông báo
  /// [type] - Loại thông báo (error, success, warning, info)
  /// [duration] - Thời gian hiển thị (mặc định 4 giây)
  /// [actionLabel] - Nhãn nút hành động (tùy chọn)
  /// [onAction] - Callback khi nhấn nút hành động (tùy chọn)
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.error,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final GlobalKey<_NotificationOverlayState> overlayKey = GlobalKey();
    
    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        key: overlayKey,
        message: message,
        type: type,
        duration: duration ?? const Duration(seconds: 4),
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Tự động xóa sau khi hết thời gian với animation
    Future.delayed(duration ?? const Duration(seconds: 4), () {
      if (overlayEntry.mounted && overlayKey.currentState != null) {
        overlayKey.currentState!.dismiss();
      } else if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Chuyển đổi thông báo lỗi kỹ thuật thành thông báo thân thiện với người dùng
  static String _makeUserFriendlyError(String message) {
    // Loại bỏ các prefix kỹ thuật
    String friendlyMessage = message
        .replaceAll('Exception: ', '')
        .replaceAll('Lỗi kết nối: ', '')
        .replaceAll('Lỗi API: ', '')
        .trim();

    // Chuyển đổi các thông báo lỗi phổ biến
    if (friendlyMessage.contains('401') || 
        friendlyMessage.contains('hết hạn') ||
        friendlyMessage.contains('access token') ||
        friendlyMessage.contains('Phiên đăng nhập')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (friendlyMessage.contains('404') || 
        friendlyMessage.contains('Không tìm thấy')) {
      return 'Không tìm thấy dữ liệu. Vui lòng thử lại sau.';
    }

    if (friendlyMessage.contains('500') || 
        friendlyMessage.contains('Internal Server Error')) {
      return 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.';
    }

    if (friendlyMessage.contains('timeout') || 
        friendlyMessage.contains('TimeoutException') ||
        friendlyMessage.contains('hết thời gian')) {
      return 'Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.';
    }

    if (friendlyMessage.contains('SocketException') || 
        friendlyMessage.contains('Failed host lookup') ||
        friendlyMessage.contains('No Internet') ||
        friendlyMessage.contains('không có kết nối')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
    }

    if (friendlyMessage.contains('Mật khẩu cũ không đúng') ||
        friendlyMessage.contains('old_password')) {
      return 'Mật khẩu cũ không đúng. Vui lòng kiểm tra lại.';
    }

    if (friendlyMessage.contains('Mật khẩu xác nhận') ||
        friendlyMessage.contains('confirm_password')) {
      return 'Mật khẩu xác nhận không khớp. Vui lòng nhập lại.';
    }

    if (friendlyMessage.contains('Đăng nhập thất bại') ||
        friendlyMessage.contains('Sai tên đăng nhập') ||
        friendlyMessage.contains('Sai mật khẩu')) {
      return 'Tên đăng nhập hoặc mật khẩu không đúng. Vui lòng thử lại.';
    }

    if (friendlyMessage.contains('Tài khoản') && 
        friendlyMessage.contains('đã tồn tại')) {
      return 'Tài khoản này đã tồn tại. Vui lòng sử dụng tên đăng nhập khác.';
    }

    // Nếu không khớp với bất kỳ pattern nào, trả về message gốc nhưng đã được làm sạch
    return friendlyMessage;
  }

  /// Hiển thị thông báo lỗi
  static void showError(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final friendlyMessage = _makeUserFriendlyError(message);
    show(
      context,
      message: friendlyMessage,
      type: NotificationType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hiển thị thông báo thành công
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hiển thị thông báo cảnh báo
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hiển thị thông báo thông tin
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _NotificationOverlay extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }
  
  // Public method để có thể gọi từ bên ngoài
  void dismiss() => _dismiss();

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.error:
        return Colors.red.shade600;
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.warning:
        return Colors.orange.shade600;
      case NotificationType.info:
        return Colors.blue.shade600;
    }
  }

  Color _getLightBackgroundColor() {
    switch (widget.type) {
      case NotificationType.error:
        return Colors.red.shade50;
      case NotificationType.success:
        return Colors.green.shade50;
      case NotificationType.warning:
        return Colors.orange.shade50;
      case NotificationType.info:
        return Colors.blue.shade50;
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case NotificationType.error:
        return Colors.red.shade700;
      case NotificationType.success:
        return Colors.green.shade700;
      case NotificationType.warning:
        return Colors.orange.shade700;
      case NotificationType.info:
        return Colors.blue.shade700;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding.top;

    return Positioned(
      top: safePadding + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                margin: EdgeInsets.symmetric(
                  horizontal: mediaQuery.size.width > 500
                      ? (mediaQuery.size.width - 500) / 2
                      : 0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getBackgroundColor(),
                      _getBackgroundColor().withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getBackgroundColor().withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content
                      GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragOffsetX += details.delta.dx;
                          });
                        },
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            _dragOffsetY += details.delta.dy;
                            // Chỉ cho phép vuốt lên (âm)
                            if (_dragOffsetY > 0) _dragOffsetY = 0;
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final threshold = screenWidth * 0.3; // 30% màn hình
                          
                          // Nếu vuốt quá ngưỡng (trái hoặc phải) thì đóng
                          if (_dragOffsetX.abs() > threshold) {
                            _dismiss();
                          } else {
                            // Nếu không đủ thì quay lại vị trí ban đầu
                            setState(() {
                              _dragOffsetX = 0;
                            });
                          }
                        },
                        onVerticalDragEnd: (details) {
                          final threshold = 100.0;
                          
                          // Nếu vuốt lên quá ngưỡng thì đóng
                          if (_dragOffsetY.abs() > threshold) {
                            _dismiss();
                          } else {
                            // Nếu không đủ thì quay lại vị trí ban đầu
                            setState(() {
                              _dragOffsetY = 0;
                            });
                          }
                        },
                        child: Transform.translate(
                          offset: Offset(_dragOffsetX, _dragOffsetY),
                          child: Opacity(
                            opacity: 1.0 - ((_dragOffsetX.abs() + _dragOffsetY.abs()) / 300).clamp(0.0, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon container
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getIcon(),
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Message content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.95),
                                            height: 1.4,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (widget.actionLabel != null && widget.onAction != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10),
                                            child: InkWell(
                                              onTap: () {
                                                widget.onAction?.call();
                                                _dismiss();
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  widget.actionLabel!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

