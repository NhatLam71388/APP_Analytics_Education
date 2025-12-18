# Cấu trúc dự án

## Thư mục chính

### `auth/`
Chứa các màn hình và logic xác thực:
- `login_screen.dart` - Màn hình đăng nhập
- `register_screen.dart` - Màn hình đăng ký

### `models/`
Chứa các model dữ liệu:
- `user.dart` - Model thông tin người dùng
- `auth_response.dart` - Model response từ API đăng nhập/đăng ký
- `register_request.dart` - Model request đăng ký

### `services/`
Chứa các service xử lý logic:
- `api_service.dart` - Service gọi API (register, login, refresh, logout)
- `auth_service.dart` - Service quản lý token và trạng thái đăng nhập

### `sinh_vien/`
Chứa các màn hình dành cho sinh viên:
- `sinh_vien_home.dart` - Trang chủ sinh viên

### `giao_vien/`
Chứa các màn hình dành cho giáo viên:
- `giao_vien_home.dart` - Trang chủ giáo viên

### `admin/`
Chứa các màn hình dành cho admin:
- `admin_home.dart` - Trang chủ admin

## API Endpoints

Base URL: `https://ef8ff1b4c87c.ngrok-free.app`

- `POST /auth/register` - Đăng ký tài khoản mới
- `POST /auth/login` - Đăng nhập
- `POST /auth/refresh` - Làm mới token
- `POST /auth/logout` - Đăng xuất

## Cách sử dụng

1. Chạy `flutter pub get` để cài đặt dependencies
2. Chạy `flutter run` để khởi động ứng dụng
3. Ứng dụng sẽ tự động kiểm tra trạng thái đăng nhập và điều hướng đến màn hình phù hợp



















