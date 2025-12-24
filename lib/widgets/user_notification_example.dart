// File này chỉ để minh họa cách sử dụng UserNotification
// Bạn có thể xóa file này sau khi đã hiểu cách sử dụng

import 'package:flutter/material.dart';
import 'user_notification.dart';

class UserNotificationExample extends StatelessWidget {
  const UserNotificationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ví dụ thông báo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Thông báo lỗi
                UserNotification.showError(
                  context,
                  message: 'Lỗi kết nối: Đăng nhập thất bại',
                  actionLabel: 'Thử lại',
                  onAction: () {
                    // Xử lý khi nhấn "Thử lại"
                    print('Người dùng nhấn Thử lại');
                  },
                );
              },
              child: const Text('Thông báo Lỗi'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Thông báo thành công
                UserNotification.showSuccess(
                  context,
                  message: 'Đăng nhập thành công!',
                );
              },
              child: const Text('Thông báo Thành công'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Thông báo cảnh báo
                UserNotification.showWarning(
                  context,
                  message: 'Vui lòng kiểm tra lại thông tin đăng nhập',
                );
              },
              child: const Text('Thông báo Cảnh báo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Thông báo thông tin
                UserNotification.showInfo(
                  context,
                  message: 'Hệ thống đang bảo trì, vui lòng quay lại sau',
                );
              },
              child: const Text('Thông báo Thông tin'),
            ),
          ],
        ),
      ),
    );
  }
}

/*
CÁCH SỬ DỤNG:

1. Thông báo lỗi đơn giản:
   UserNotification.showError(
     context,
     message: 'Lỗi kết nối: Đăng nhập thất bại',
   );

2. Thông báo lỗi với nút hành động:
   UserNotification.showError(
     context,
     message: 'Lỗi tải dữ liệu',
     actionLabel: 'Thử lại',
     onAction: () {
       // Xử lý khi nhấn "Thử lại"
       _loadData();
     },
   );

3. Thông báo thành công:
   UserNotification.showSuccess(
     context,
     message: 'Đổi mật khẩu thành công!',
   );

4. Thông báo với thời gian tùy chỉnh:
   UserNotification.showError(
     context,
     message: 'Lỗi kết nối',
     duration: const Duration(seconds: 6),
   );

5. Sử dụng trong try-catch:
   try {
     await someApiCall();
   } catch (e) {
     UserNotification.showError(
       context,
       message: e.toString().replaceAll('Exception: ', ''),
     );
   }
*/








