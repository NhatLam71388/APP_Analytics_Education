import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/student_academic.dart';
import '../../services/student_api_service.dart';
import '../../services/teacher_api_service.dart';

class OverallGPACard extends StatefulWidget {
  final StudentAcademic studentData;
  final Animation<double>? animation;
  final String? masv; // Optional: nếu có thì load từ teacher APIs

  const OverallGPACard({
    super.key,
    required this.studentData,
    this.animation,
    this.masv,
  });

  @override
  State<OverallGPACard> createState() => _OverallGPACardState();
}

class _OverallGPACardState extends State<OverallGPACard> {
  OverallGPAResponse? _overallGPA;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOverallGPA();
  }

  Future<void> _loadOverallGPA() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Sử dụng teacher API nếu có masv, ngược lại dùng student API
      final overallGPA = widget.masv != null
          ? await TeacherApiService.getOverallGPAByMasv(widget.masv!)
          : await StudentApiService.getOverallGPA();
      
      if (!mounted) return;
      
      setState(() {
        _overallGPA = overallGPA;
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

  MaterialColor _getXepLoaiColor(String xepLoai) {
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

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ studentData
    if (_errorMessage != null || _overallGPA == null) {
      if (widget.studentData.semesters.isEmpty) {
        return const SizedBox.shrink();
      }
      return _buildFromStudentData();
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

  Widget _buildFromStudentData() {
    final overallGPA = widget.studentData.calculateOverallGPA();
    final xepLoai = widget.studentData.getOverallXepLoai();
    return _buildContent(overallGPA, xepLoai);
  }

  Widget _buildFromAPI() {
    final overallGPA = _overallGPA!.gpaToanKhoa;
    final xepLoai = _overallGPA!.loaiHocLucToanKhoa;
    return _buildContent(overallGPA, xepLoai);
  }

  Widget _buildContent(double overallGPA, String xepLoai) {
    final color = _getXepLoaiColor(xepLoai);

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
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        color.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 25,
                        spreadRadius: 3,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: -5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.rotate(
                            angle: (1 - value) * 0.3,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.shade400,
                              color.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.assessment,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final clampedValue = value.clamp(0.0, 1.0);
                          return Opacity(
                            opacity: clampedValue,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - clampedValue), 0),
                              child: child,
                            ),
                          );
                        },
                        child: const Text(
                          'GPA Tổng Kết Toàn Khóa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Biểu đồ tròn - center, nhỏ gọn với animation mạnh
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: overallGPA / 10),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.elasticOut,
                        builder: (context, scaleValue, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * scaleValue),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: 100,
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: value * 10,
                                  color: color,
                                  title: (value * 10).toStringAsFixed(2),
                                  radius: 42,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 10 - (value * 10),
                                  color: Colors.grey.shade300,
                                  title: '',
                                  radius: 42,
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 32,
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // Thông tin bên dưới
                Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: overallGPA),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutBack,
                          builder: (context, fadeValue, child) {
                            final clampedValue = fadeValue.clamp(0.0, 1.0);
                            return Opacity(
                              opacity: clampedValue,
                              child: Transform.scale(
                                scale: 0.9 + (0.1 * clampedValue),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Điểm TB: ${value.toStringAsFixed(2)}/10',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: color.shade700,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        final clampedValue = value.clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: 0.7 + (0.3 * clampedValue),
                          child: Transform.rotate(
                            angle: (1 - clampedValue) * 0.1,
                            child: Opacity(
                              opacity: clampedValue,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.shade400, color.shade600, color.shade700],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, rotateValue, child) {
                                  return Transform.rotate(
                                    angle: rotateValue * 2 * 3.14159,
                                    child: child,
                                  );
                                },
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Xếp loại: $xepLoai',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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

