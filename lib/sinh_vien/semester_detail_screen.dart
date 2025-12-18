import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../models/student_academic.dart';
import '../models/semester.dart';
import '../services/student_api_service.dart';
import '../widgets/salomon_tab_bar_provider.dart';
import 'widgets/scores_table.dart';
import 'widgets/highest_lowest_scores.dart';
import 'widgets/subject_comparison_chart.dart';
import 'widgets/subject_grade_distribution_chart.dart';
import 'widgets/conduct_score_card.dart';
import 'widgets/semester_credit_card.dart';

class SemesterDetailScreen extends StatefulWidget {
  final StudentAcademic studentData;
  final Semester semester;

  const SemesterDetailScreen({
    super.key,
    required this.studentData,
    required this.semester,
  });

  @override
  State<SemesterDetailScreen> createState() => _SemesterDetailScreenState();
}

class _SemesterDetailScreenState extends State<SemesterDetailScreen>
    with TickerProviderStateMixin {
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
      8,
      (index) => CurvedAnimation(
        parent: _mainAnimationController,
        curve: Interval(
          index * 0.08,
          (0.6 + (index * 0.04)).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBarProvider = SalomonTabBarProvider.findInAncestors(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue.shade700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'HK${widget.semester.hocKySo} - ${widget.semester.namHoc} - ${widget.semester.namHoc + 1}',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
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
                // 2. GPA tổng kết của học kỳ đó
                _SemesterGPACard(
                  semester: widget.semester,
                  animation: _animations[1],
                ),
                const SizedBox(height: 16),

                // 2.5. Số tín chỉ của học kỳ
                SemesterCreditCard(
                  semester: widget.semester,
                  animation: _animations[1],
                ),
                const SizedBox(height: 16),

                // 8. Điểm rèn luyện
                ConductScoreCard(
                  semester: widget.semester,
                  animation: _animations[7],
                ),
                const SizedBox(height: 16),

                // 3. Tỷ lệ đậu môn học của kỳ đó
                _SemesterPassRateChart(
                  semester: widget.semester,
                  animation: _animations[2],
                ),
                const SizedBox(height: 16),

                // 4. Chi tiết điểm
                ScoresTable(
                  semester: widget.semester,
                  animation: _animations[3],
                ),
                const SizedBox(height: 16),

                // 5. Điểm cao nhất và thấp nhất của kỳ đó
                HighestLowestScores(
                  studentData: widget.studentData,
                  semester: widget.semester,
                  animation: _animations[4],
                ),
                const SizedBox(height: 16),

                // 6. So sánh điểm với lớp
                SubjectComparisonChart(
                  studentData: widget.studentData,
                  selectedSemester: widget.semester,
                  animation: _animations[5],
                ),
                const SizedBox(height: 16),

                // 7. Tỷ lệ môn đạt loại giỏi, yếu, khá, trung bình theo kỳ
                _SemesterGradeDistributionChart(
                  semester: widget.semester,
                  animation: _animations[6],
                ),
                const SizedBox(height: 16),


                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: tabBarProvider != null
          ? tabBarProvider.buildSalomonBottomBar(context)
          : null,
    );
  }
}

// Widget hiển thị GPA của học kỳ
class _SemesterGPACard extends StatefulWidget {
  final Semester semester;
  final Animation<double>? animation;

  const _SemesterGPACard({
    required this.semester,
    this.animation,
  });

  @override
  State<_SemesterGPACard> createState() => _SemesterGPACardState();
}

class _SemesterGPACardState extends State<_SemesterGPACard> {
  SemesterGPAResponse? _semesterGPA;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSemesterGPA();
  }

  Future<void> _loadSemesterGPA() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allSemesterGPAs = await StudentApiService.getSemesterGPA();
      
      if (!mounted) return;
      
      // Debug: In ra để kiểm tra
      debugPrint('🔍 _SemesterGPACard - Tìm kiếm GPA cho học kỳ:');
      debugPrint('  - Semester hocKy: ${widget.semester.hocKy}');
      debugPrint('  - Semester namHoc: ${widget.semester.namHoc}');
      debugPrint('  - Semester hocKySo: ${widget.semester.hocKySo}');
      debugPrint('  - Extracted namHoc: ${_extractNamHoc()}');
      debugPrint('  - Extracted hocKy: ${_extractHocKy()}');
      debugPrint('  - Tổng số GPA từ API: ${allSemesterGPAs.length}');
      for (var gpa in allSemesterGPAs) {
        debugPrint('    - API: ${gpa.tenNamHoc} / ${gpa.tenHocKy} / GPA: ${gpa.gpaHocKy}');
      }
      
      // Tìm đúng học kỳ
      final matchedGPA = _findMatchingSemester(allSemesterGPAs);
      
      if (matchedGPA != null) {
        debugPrint('✅ Tìm thấy matching GPA: ${matchedGPA.gpaHocKy}');
      } else {
        debugPrint('⚠️ Không tìm thấy matching GPA, sẽ fallback về semester data');
      }
      
      setState(() {
        _semesterGPA = matchedGPA;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // Helper method để normalize hocKy
  String _normalizeHocKy(String hocKy) {
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    // Nếu không có prefix HK, thêm vào
    if (!hocKy.toUpperCase().startsWith('HK')) {
      final numberMatch = RegExp(r'\d+').firstMatch(hocKy);
      if (numberMatch != null) {
        return 'HK${numberMatch.group(0)}';
      }
    }
    return hocKy.toUpperCase();
  }

  // Extract năm học từ semester
  String _extractNamHoc() {
    // semester.hocKy có thể là "HK1 - 2024 - 2025" hoặc "2024-2025-1"
    final parts = widget.semester.hocKy.split('-');
    if (parts.length >= 3) {
      // Tìm năm học (2 số liên tiếp)
      for (int i = 0; i < parts.length - 1; i++) {
        final year1 = int.tryParse(parts[i].trim());
        final year2 = int.tryParse(parts[i + 1].trim());
        if (year1 != null && year2 != null && year2 == year1 + 1) {
          return '${year1}-${year2}';
        }
      }
    }
    // Fallback: dùng namHoc từ semester
    return '${widget.semester.namHoc}-${widget.semester.namHoc + 1}';
  }

  // Extract học kỳ từ semester
  String _extractHocKy() {
    return 'HK${widget.semester.hocKySo}';
  }

  SemesterGPAResponse? _findMatchingSemester(List<SemesterGPAResponse> allGPAs) {
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = _normalizeHocKy(hocKy);

    // Normalize năm học để so sánh (xử lý cả "2023 - 2024" và "2023-2024")
    String normalizeNamHoc(String namHocStr) {
      return namHocStr.replaceAll(' ', '').trim();
    }

    final normalizedNamHoc = normalizeNamHoc(namHoc);

    for (var gpa in allGPAs) {
      final normalizedItemHocKy = _normalizeHocKy(gpa.tenHocKy);
      final normalizedGpaNamHoc = normalizeNamHoc(gpa.tenNamHoc);
      if (normalizedGpaNamHoc == normalizedNamHoc && normalizedItemHocKy == normalizedHocKy) {
        return gpa;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ semester
    if (_errorMessage != null || _semesterGPA == null) {
      return _buildFromSemester();
    }

    // Sử dụng dữ liệu từ API
    return _buildFromAPI();
  }

  Widget _buildLoadingWidget() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue.shade600,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildFromSemester() {
    final gpa = widget.semester.calculateGPA();
    final xepLoai = widget.semester.getXepLoai();
    return _buildContent(gpa, xepLoai);
  }

  Widget _buildFromAPI() {
    final gpa = _semesterGPA!.gpaHocKy;
    final xepLoai = _semesterGPA!.loaiHocLuc;
    return _buildContent(gpa, xepLoai);
  }

  Widget _buildContent(double gpa, String xepLoai) {

    return FadeTransition(
      opacity: widget.animation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: widget.animation != null
            ? Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: widget.animation!,
                curve: Curves.easeOutCubic,
              ))
            : const AlwaysStoppedAnimation(Offset.zero),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (context, scaleValue, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * scaleValue),
              child: child,
            );
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade100.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.9),
                      Colors.blue.shade50.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 25,
                      spreadRadius: 3,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'GPA Tổng Kết Học Kỳ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: gpa),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            value.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              letterSpacing: 1.2,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getXepLoaiColor(xepLoai).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          xepLoai,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getXepLoaiColor(xepLoai),
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
    );
  }

  Color _getXepLoaiColor(String xepLoai) {
    switch (xepLoai) {
      case 'Xuất sắc':
        return Colors.purple;
      case 'Giỏi':
        return Colors.green;
      case 'Khá':
        return Colors.blue;
      case 'Trung bình':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

// Widget hiển thị tỷ lệ đậu của học kỳ
class _SemesterPassRateChart extends StatefulWidget {
  final Semester semester;
  final Animation<double>? animation;

  const _SemesterPassRateChart({
    required this.semester,
    this.animation,
  });

  @override
  State<_SemesterPassRateChart> createState() => _SemesterPassRateChartState();
}

class _SemesterPassRateChartState extends State<_SemesterPassRateChart> {
  PassRateBySemesterResponse? _passRate;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPassRate();
  }

  Future<void> _loadPassRate() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allPassRates = await StudentApiService.getPassRateBySemester();
      
      if (!mounted) return;
      
      // Tìm đúng học kỳ
      final matchedPassRate = _findMatchingSemester(allPassRates);
      
      setState(() {
        _passRate = matchedPassRate;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // Helper method để normalize hocKy
  String _normalizeHocKy(String hocKy) {
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    // Nếu không có prefix HK, thêm vào
    if (!hocKy.toUpperCase().startsWith('HK')) {
      final numberMatch = RegExp(r'\d+').firstMatch(hocKy);
      if (numberMatch != null) {
        return 'HK${numberMatch.group(0)}';
      }
    }
    return hocKy.toUpperCase();
  }

  // Extract năm học từ semester
  String _extractNamHoc() {
    // semester.hocKy có thể là "HK1 - 2024 - 2025" hoặc "2024-2025-1"
    final parts = widget.semester.hocKy.split('-');
    if (parts.length >= 3) {
      // Tìm năm học (2 số liên tiếp)
      for (int i = 0; i < parts.length - 1; i++) {
        final year1 = int.tryParse(parts[i].trim());
        final year2 = int.tryParse(parts[i + 1].trim());
        if (year1 != null && year2 != null && year2 == year1 + 1) {
          return '${year1}-${year2}';
        }
      }
    }
    // Fallback: dùng namHoc từ semester
    return '${widget.semester.namHoc}-${widget.semester.namHoc + 1}';
  }

  // Extract học kỳ từ semester
  String _extractHocKy() {
    return 'HK${widget.semester.hocKySo}';
  }

  PassRateBySemesterResponse? _findMatchingSemester(List<PassRateBySemesterResponse> allPassRates) {
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = _normalizeHocKy(hocKy);

    for (var passRate in allPassRates) {
      final normalizedItemHocKy = _normalizeHocKy(passRate.tenHocKy);
      if (passRate.tenNamHoc == namHoc && normalizedItemHocKy == normalizedHocKy) {
        return passRate;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ semester
    if (_errorMessage != null || _passRate == null) {
      return _buildFromSemester();
    }

    // Sử dụng dữ liệu từ API
    return _buildFromAPI();
  }

  Widget _buildLoadingWidget() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue.shade600,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildFromSemester() {
    final passRate = widget.semester.calculatePassRate();
    final passedSubjects = widget.semester.subjects.where((s) => s.isPassed).length;
    final totalSubjects = widget.semester.subjects.length;
    return _buildContent(passRate, passedSubjects, totalSubjects);
  }

  Widget _buildFromAPI() {
    final passRate = _passRate!.tyLeQuaMon * 100; // Convert từ 0-1 sang 0-100
    final passedSubjects = _passRate!.soMonDau;
    final totalSubjects = _passRate!.tongMon;
    return _buildContent(passRate, passedSubjects, totalSubjects);
  }

  Widget _buildContent(double passRate, int passedSubjects, int totalSubjects) {

    return FadeTransition(
      opacity: widget.animation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: widget.animation != null
            ? Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: widget.animation!,
                curve: Curves.easeOutCubic,
              ))
            : const AlwaysStoppedAnimation(Offset.zero),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade100.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tỷ Lệ Đậu Môn Học',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: passRate),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '${value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          letterSpacing: 1.2,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '$passedSubjects / $totalSubjects môn đậu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget hiển thị tỷ lệ môn đạt loại theo học kỳ
class _SemesterGradeDistributionChart extends StatefulWidget {
  final Semester semester;
  final Animation<double>? animation;

  const _SemesterGradeDistributionChart({
    required this.semester,
    this.animation,
  });

  @override
  State<_SemesterGradeDistributionChart> createState() => _SemesterGradeDistributionChartState();
}

class _SemesterGradeDistributionChartState extends State<_SemesterGradeDistributionChart> {
  SubjectGradeRateResponse? _gradeRate;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGradeRate();
  }

  Future<void> _loadGradeRate() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allGradeRates = await StudentApiService.getSubjectGradeRate();
      
      if (!mounted) return;
      
      // Tìm đúng học kỳ
      final matchedRate = _findMatchingSemester(allGradeRates);
      
      setState(() {
        _gradeRate = matchedRate;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // Helper method để normalize hocKy
  String _normalizeHocKy(String hocKy) {
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    // Nếu không có prefix HK, thêm vào
    if (!hocKy.toUpperCase().startsWith('HK')) {
      final numberMatch = RegExp(r'\d+').firstMatch(hocKy);
      if (numberMatch != null) {
        return 'HK${numberMatch.group(0)}';
      }
    }
    return hocKy.toUpperCase();
  }

  // Extract năm học từ semester - trả về format có khoảng trắng để match với API
  String _extractNamHoc() {
    // semester.hocKy có thể là "HK1 - 2024 - 2025" hoặc "2024-2025-1"
    final parts = widget.semester.hocKy.split('-');
    if (parts.length >= 3) {
      // Tìm năm học (2 số liên tiếp)
      for (int i = 0; i < parts.length - 1; i++) {
        final year1 = int.tryParse(parts[i].trim());
        final year2 = int.tryParse(parts[i + 1].trim());
        if (year1 != null && year2 != null && year2 == year1 + 1) {
          // Trả về format có khoảng trắng để match với API: "2022 - 2023"
          return '$year1 - $year2';
        }
      }
    }
    // Fallback: dùng namHoc từ semester - format có khoảng trắng
    return '${widget.semester.namHoc} - ${widget.semester.namHoc + 1}';
  }

  // Extract học kỳ từ semester
  String _extractHocKy() {
    return 'HK${widget.semester.hocKySo}';
  }

  // Normalize năm học để so sánh (xử lý cả format có và không có khoảng trắng)
  String _normalizeNamHoc(String namHoc) {
    // Loại bỏ khoảng trắng thừa và normalize
    return namHoc.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  SubjectGradeRateResponse? _findMatchingSemester(List<SubjectGradeRateResponse> allRates) {
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = _normalizeHocKy(hocKy);
    final normalizedNamHoc = _normalizeNamHoc(namHoc);

    for (var rate in allRates) {
      final normalizedItemHocKy = _normalizeHocKy(rate.tenHocKy);
      final normalizedItemNamHoc = _normalizeNamHoc(rate.tenNamHoc);
      
      // So sánh cả năm học và học kỳ đã được normalize
      if (normalizedItemNamHoc == normalizedNamHoc && normalizedItemHocKy == normalizedHocKy) {
        return rate;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ semester
    if (_errorMessage != null || _gradeRate == null) {
      return _buildFromSemester();
    }

    // Sử dụng dữ liệu từ API
    return _buildFromAPI();
  }

  Widget _buildLoadingWidget() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue.shade600,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildFromSemester() {
    // Fallback về widget cũ
    return SubjectGradeDistributionChart(
      studentData: StudentAcademic(
        maSinhVien: '',
        hoTen: '',
        lop: '',
        khuVuc: '',
        semesters: [widget.semester],
      ),
      animation: widget.animation,
    );
  }

  Widget _buildFromAPI() {
    // Sử dụng dữ liệu từ API cho học kỳ cụ thể
    return SubjectGradeDistributionChart(
      studentData: StudentAcademic(
        maSinhVien: '',
        hoTen: '',
        lop: '',
        khuVuc: '',
        semesters: [widget.semester],
      ),
      animation: widget.animation,
      gradeRate: _gradeRate, // Truyền gradeRate cụ thể
    );
  }
}

