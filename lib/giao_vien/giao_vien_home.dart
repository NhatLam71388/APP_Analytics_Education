import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../auth/login_screen.dart';
import '../services/teacher_data_service.dart';
import '../services/cache_service.dart';
import '../models/teacher_advisor.dart';
import 'widgets/teacher_info_card.dart';
import 'widgets/kpi_cards.dart';
import 'widgets/semester_selector.dart';

class GiaoVienHome extends StatefulWidget {
  const GiaoVienHome({super.key});

  @override
  State<GiaoVienHome> createState() => _GiaoVienHomeState();
}

class _GiaoVienHomeState extends State<GiaoVienHome>
    with TickerProviderStateMixin {
  TeacherAdvisor? teacherData;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _mainAnimationController;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animations = List.generate(
      3,
      (index) => CurvedAnimation(
        parent: _mainAnimationController,
        curve: Interval(
          index * 0.1,
          0.6 + (index * 0.2),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _loadData();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Đợi một chút để đảm bảo access token đã sẵn sàng
      await Future.delayed(const Duration(milliseconds: 500));

      // Kiểm tra lại access token trước khi load
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        await Future.delayed(const Duration(milliseconds: 300));
        final retryLoggedIn = await AuthService.isLoggedIn();
        if (!retryLoggedIn) {
          if (!mounted) return;
          await AuthService.clearAuthData();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return;
        }
      }

      // Load dữ liệu từ API (luôn luôn để cập nhật cache)
      // Vì TeacherAdvisor phức tạp, ta sẽ luôn load từ API
      // Cache chỉ dùng để hiển thị thông báo nếu có
      final data = await TeacherDataService.loadTeacherData();
      
      // Lưu vào cache
      await CacheService.saveTeacherData(data);
      
      if (!mounted) return;
      setState(() {
        teacherData = data;
        _isLoading = false;
      });

      _mainAnimationController.forward();
    } catch (e) {
      if (!mounted) return;
      
      // Kiểm tra nếu lỗi là 401 (Unauthorized)
      final errorMessage = e.toString();
      if (errorMessage.contains('401') || 
          errorMessage.contains('hết hạn') ||
          (errorMessage.contains('access token') && !errorMessage.contains('404'))) {
        await AuthService.clearAuthData();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      
      // Với lỗi 404 hoặc các lỗi khác - hiển thị error message
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _handleLogout() async {
    final accessToken = await AuthService.getAccessToken();
    final refreshToken = await AuthService.getRefreshToken();
    final tokenType = await AuthService.getTokenType();

    if (accessToken != null && refreshToken != null && tokenType != null) {
      try {
        await ApiService.logout(accessToken, refreshToken, tokenType);
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }

    await AuthService.clearAuthData();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.green,
              size: 50,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || teacherData == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải dữ liệu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage ?? 'Không thể tải dữ liệu',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.grey.shade50,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thông tin giáo viên
                TeacherInfoCard(
                  teacherData: teacherData!,
                  animation: _animations[0],
                  onLogout: _handleLogout,
                ),
                const SizedBox(height: 16),

                // 2. KPI Cards - Tổng số lớp và tổng số sinh viên
                KPICards(
                  teacherData: teacherData!,
                  animation: _animations[1],
                ),
                const SizedBox(height: 16),

                // 3. Danh sách các kỳ
                SemesterSelector(
                  teacherData: teacherData!,
                  animation: _animations[2],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
