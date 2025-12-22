import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import '../sinh_vien/sinh_vien_main.dart';
import '../giao_vien/giao_vien_main.dart';
import '../admin/admin_home.dart';
import '../components/background.dart';
import '../widgets/user_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await ApiService.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        // Save auth data - ĐẢM BẢO lưu xong trước khi navigate
        await AuthService.saveAuthData(response);

        // Đợi một chút để đảm bảo token đã được lưu vào SharedPreferences
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify token đã được lưu
        final tokenSaved = await AuthService.isLoggedIn();
        if (!tokenSaved) {
          throw Exception('Lỗi lưu thông tin đăng nhập. Vui lòng thử lại.');
        }

        if (!mounted) return;

        // Navigate based on user type
        final userInfo = response.userInfo;
        if (userInfo != null) {
          switch (userInfo.loaiNguoiDung.toLowerCase()) {
            case 'sinhvien':
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SinhVienMain()),
              );
              break;
            case 'giangvien':
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GiaoVienMain()),
              );
              break;
            case 'admin':
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminHome()),
              );
              break;
            default:
              _showError('Loại người dùng không hợp lệ');
              setState(() {
                _isLoading = false;
              });
          }
        } else {
          _showError('Không thể lấy thông tin người dùng');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    // Sử dụng UserNotification thay vì SnackBar
    UserNotification.showError(
      context,
      message: message,
    );
  }

  Future<void> _handleForgotPassword() async {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      _showError('Vui lòng nhập tên đăng nhập (mã số sinh viên/giáo viên)');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.forgotPassword(username);
      
      if (!mounted) return;

      // Hiển thị thông báo thành công với message và hint
      final successMessage = '${result['message']}\n${result['hint']}';
      UserNotification.showSuccess(
        context,
        message: successMessage,
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Background(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: size.height * 0.05),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: const Text(
                    "ĐĂNG NHẬP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2661FA),
                      fontSize: 36
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(height: size.height * 0.05),
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Tên đăng nhập",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: size.height * 0.025),
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: GestureDetector(
                    onTap: _handleForgotPassword,
                    child: const Text(
                      "Quên mật khẩu?",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0XFF2661FA)
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: _isLoading
                      ? Center(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: const Color(0XFF2661FA),
                            size: 40,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(80.0)
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            height: 50.0,
                            width: size.width * 0.5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(80.0),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade600,
                                  Colors.blue.shade700,
                                ]
                              )
                            ),
                            padding: const EdgeInsets.all(0),
                            child: const Text(
                              "ĐĂNG NHẬP",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                ),
                // SizedBox(height: size.height * 0.02),
                // Container(
                //   alignment: Alignment.centerRight,
                //   margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                //   child: GestureDetector(
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(builder: (context) => const RegisterScreen())
                //       );
                //     },
                //     child: const Text(
                //       "Chưa có tài khoản? Đăng ký",
                //       style: TextStyle(
                //         fontSize: 12,
                //         fontWeight: FontWeight.bold,
                //         color: Color(0xFF2661FA)
                //       ),
                //     ),
                //   ),
                // ),
                // SizedBox(height: size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
