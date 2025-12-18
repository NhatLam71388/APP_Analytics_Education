import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/student_data_service.dart';
import '../services/cache_service.dart';
import '../models/student_academic.dart';
import '../auth/login_screen.dart';
import 'widgets/student_info_card.dart';
import 'widgets/semester_selector.dart';
import 'widgets/gpa_trend_chart.dart';
import 'widgets/overall_gpa_card.dart';
import 'widgets/subject_grade_distribution_chart.dart';
import 'widgets/highest_lowest_scores_overall.dart';
import 'widgets/conduct_score_chart.dart';
import 'widgets/subject_grade_distribution_chart.dart';
import 'widgets/total_credit_card.dart';

class SinhVienHome extends StatefulWidget {
  final String? masv; // Optional: nếu có thì load từ teacher APIs

  const SinhVienHome({super.key, this.masv});

  @override
  State<SinhVienHome> createState() => _SinhVienHomeState();
}

class _SinhVienHomeState extends State<SinhVienHome>
    with TickerProviderStateMixin {
  StudentAcademic? studentData;
  String? selectedSemester;
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

    // Tạo các animations với delay khác nhau và smoother curves
    _animations = List.generate(
      8,
      (index) => CurvedAnimation(
        parent: _mainAnimationController,
        curve: Interval(
          index * 0.08,
          0.6 + (index * 0.04),
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

      // Đợi một chút để đảm bảo access token đã sẵn sàng (nếu vừa mới đăng nhập)
      await Future.delayed(const Duration(milliseconds: 500));

      // Kiểm tra lại access token trước khi load
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        // Nếu không có token, đợi thêm một chút (có thể đang trong quá trình lưu)
        await Future.delayed(const Duration(milliseconds: 300));
        final retryLoggedIn = await AuthService.isLoggedIn();
        if (!retryLoggedIn) {
          // Vẫn không có token sau khi retry - quay về login
          await AuthService.clearAuthData();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return;
        }
      }

      // Thử load từ cache trước (nếu không force refresh)
      StudentAcademic? cachedData;
      if (!forceRefresh) {
        cachedData = await CacheService.getStudentData(masv: widget.masv);
        if (cachedData != null && mounted) {
          // Hiển thị dữ liệu từ cache ngay lập tức
          setState(() {
            studentData = cachedData;
            if (studentData!.semesters.isNotEmpty) {
              selectedSemester = studentData!.semesters.first.hocKy;
            }
            _isLoading = false;
          });
          _mainAnimationController.forward();
        }
      }

      // Load data từ API (luôn luôn để cập nhật cache)
      try {
      final data = widget.masv != null
          ? await StudentDataService.loadStudentDataByMasv(widget.masv!)
          : await StudentDataService.loadStudentData();
      
        // Lưu vào cache
        await CacheService.saveStudentData(data, masv: widget.masv);
        
      if (!mounted) return;
      
        // Cập nhật UI với dữ liệu mới từ API
      setState(() {
        studentData = data;
        if (studentData!.semesters.isNotEmpty) {
          selectedSemester = studentData!.semesters.first.hocKy;
        }
        _isLoading = false;
      });

      // Bắt đầu animations sau khi data đã load
      _mainAnimationController.forward();
      } catch (apiError) {
        // Nếu API fail nhưng có cache, vẫn hiển thị cache
        if (cachedData != null && mounted) {
          setState(() {
            _isLoading = false;
          });
          // Hiển thị thông báo rằng đang dùng dữ liệu cache
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang hiển thị dữ liệu đã lưu. Không thể tải dữ liệu mới.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        // Nếu không có cache, throw error để xử lý ở catch bên ngoài
        rethrow;
      }
    } catch (e) {
      if (!mounted) return;
      
      // Kiểm tra nếu lỗi là 401 (Unauthorized) - token không hợp lệ hoặc hết hạn
      final errorMessage = e.toString();
      if (errorMessage.contains('401') || 
          errorMessage.contains('hết hạn') ||
          (errorMessage.contains('access token') && !errorMessage.contains('404'))) {
        // Chỉ logout khi thực sự là lỗi authentication (401)
        await AuthService.clearAuthData();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      
      // Với lỗi 404 hoặc các lỗi khác - hiển thị error message thay vì logout
      // (404 có thể là do dữ liệu chưa có, không phải lỗi authentication)
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        String displayMessage = errorMessage.replaceAll('Exception: ', '');
        if (errorMessage.contains('404')) {
          displayMessage = 'Không tìm thấy dữ liệu. Vui lòng thử lại sau.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $displayMessage'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _loadData();
              },
            ),
          ),
        );
      }
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
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.blue.shade600,
              size: 50,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || studentData == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
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
                    backgroundColor: Colors.blue,
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
              Colors.blue.shade50,
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
                // 1. Thông tin sinh viên
                StudentInfoCard(
                  studentData: studentData!,
                  animation: _animations[0],
                  onLogout: widget.masv != null ? null : _handleLogout,
                  isTeacherView: widget.masv != null,
                ),
                const SizedBox(height: 16),

                // Thông báo nếu thiếu dữ liệu
                if (studentData!.semesters.isEmpty || 
                    studentData!.semesters.every((s) => s.subjects.isEmpty))
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông báo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Một số dữ liệu chưa có sẵn. Vui lòng thử lại sau hoặc liên hệ quản trị viên.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Danh sách học kỳ (click để xem chi tiết)
                if (studentData!.semesters.isNotEmpty)
                  SemesterSelector(
                    semesters: studentData!.semesters,
                    selectedSemester: selectedSemester,
                    studentData: studentData!,
                    animation: _animations[1],
                  ),
                if (studentData!.semesters.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có dữ liệu học kỳ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // 3. Xu hướng GPA theo học kỳ
                GPATrendChart(
                  studentData: studentData!,
                  selectedSemester: null, // Hiển thị tất cả kỳ
                  animation: _animations[2],
                  masv: widget.masv,
                ),
                const SizedBox(height: 16),

                // 3.5. Tổng số tín chỉ
                TotalCreditCard(
                  animation: _animations[2],
                ),
                const SizedBox(height: 16),

                // 4. GPA tổng kết toàn khóa
                OverallGPACard(
                  studentData: studentData!,
                  animation: _animations[3],
                  masv: widget.masv,
                ),
                const SizedBox(height: 16),

                // 6. Điểm cao nhất, điểm thấp nhất (tổng hợp)
                HighestLowestScoresOverall(
                  studentData: studentData!,
                  animation: _animations[5],
                  masv: widget.masv,
                ),
                const SizedBox(height: 16),

                // 7. Điểm rèn luyện theo học kỳ
                ConductScoreChart(
                  studentData: studentData!,
                  animation: _animations[6],
                ),
                const SizedBox(height: 16),

                // 8. Tỷ lệ môn đạt loại giỏi, khá, trung bình, yếu (tổng hợp)
                SubjectGradeDistributionChart(
                  studentData: studentData!,
                  animation: _animations[7],
                  masv: widget.masv,
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
