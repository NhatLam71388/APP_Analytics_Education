import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/student_academic.dart';
import '../../models/semester.dart';
import '../../services/student_api_service.dart';
import '../../services/teacher_api_service.dart';

class GPATrendChart extends StatefulWidget {
  final StudentAcademic studentData;
  final Semester? selectedSemester;
  final Animation<double>? animation;
  final String? masv; // Optional: nếu có thì load từ teacher APIs

  const GPATrendChart({
    super.key,
    required this.studentData,
    this.selectedSemester,
    this.animation,
    this.masv,
  });

  @override
  State<GPATrendChart> createState() => _GPATrendChartState();
}

class _GPATrendChartState extends State<GPATrendChart> {
  List<GPATrendResponse>? _gpaTrends;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGPATrends();
  }

  Future<void> _loadGPATrends() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Sử dụng teacher API nếu có masv, ngược lại dùng student API
      final trends = widget.masv != null
          ? await TeacherApiService.getGPATrendByMasv(widget.masv!)
          : await StudentApiService.getGPATrend();
      
      if (!mounted) return;
      
      setState(() {
        _gpaTrends = trends;
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

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading hoặc có lỗi, hiển thị fallback
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null || _gpaTrends == null || _gpaTrends!.isEmpty) {
      // Fallback về dữ liệu từ studentData nếu API không có dữ liệu
      if (widget.studentData.semesters.isEmpty) {
        return const SizedBox.shrink();
      }
      return _buildChartFromStudentData();
    }

    // Sử dụng dữ liệu từ API
    return _buildChartFromAPI();
  }

  Widget _buildLoadingWidget() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        child: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue.shade600,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildChartFromStudentData() {
    final selected = widget.selectedSemester ?? widget.studentData.semesters.first;
    final gpa = selected.calculateGPA();
    final xepLoai = selected.getXepLoai();
    
    return _buildChartContent(
      spots: widget.studentData.semesters.asMap().entries.map((entry) {
        return FlSpot(
          entry.key.toDouble(),
          entry.value.calculateGPA(),
        );
      }).toList(),
      bottomTitles: widget.studentData.semesters.asMap().entries.map((entry) {
        return 'HK${entry.value.hocKySo}';
      }).toList(),
      currentGPA: gpa,
      currentXepLoai: xepLoai,
    );
  }

  Widget _buildChartFromAPI() {
    // Sắp xếp theo năm học và học kỳ
    final sortedTrends = List<GPATrendResponse>.from(_gpaTrends!)
      ..sort((a, b) {
        final yearCompare = a.tenNamHoc.compareTo(b.tenNamHoc);
        if (yearCompare != 0) return yearCompare;
        return a.tenHocKy.compareTo(b.tenHocKy);
      });

    // Tạo spots cho chart
    final spots = sortedTrends.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.gpa,
      );
    }).toList();

    // Tạo labels cho bottom titles
    final bottomTitles = sortedTrends.map((trend) {
      // Format: "2024 - 2025\nHK1"
      final hocKyMatch = RegExp(r'HK(\d+)').firstMatch(trend.tenHocKy);
      final hocKy = hocKyMatch != null ? 'HK${hocKyMatch.group(1)}' : trend.tenHocKy;
      return '${trend.tenNamHoc}\n$hocKy';
    }).toList();

    // Lấy GPA và xếp loại hiện tại (học kỳ cuối cùng)
    final currentTrend = sortedTrends.isNotEmpty ? sortedTrends.last : null;
    final currentGPA = currentTrend?.gpa ?? 0.0;
    final currentXepLoai = _getXepLoaiFromGPA(currentGPA);

    return _buildChartContent(
      spots: spots,
      bottomTitles: bottomTitles,
      currentGPA: currentGPA,
      currentXepLoai: currentXepLoai,
    );
  }

  String _getXepLoaiFromGPA(double gpa) {
    if (gpa >= 9.0) return 'Xuất sắc';
    if (gpa >= 8.0) return 'Giỏi';
    if (gpa >= 7.0) return 'Khá';
    if (gpa >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  Widget _buildChartContent({
    required List<FlSpot> spots,
    required List<String> bottomTitles,
    required double currentGPA,
    required String currentXepLoai,
  }) {
    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }

    // Tạo Set chứa các x values từ spots để kiểm tra nhanh
    final spotXValues = spots.map((spot) => spot.x.toInt()).toSet();

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
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.trending_up,
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
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: const Text(
                          'Xu hướng GPA theo học kỳ',
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
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 0,
                      minY: 0,
                      maxY: 10,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  value.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 70, // Tăng reservedSize để chứa text 2 dòng
                            interval: 1, // Hiển thị mỗi điểm một lần
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              // Chỉ hiển thị nếu có spot tại vị trí này (có dữ liệu)
                              if (spotXValues.contains(index) && index >= 0 && index < bottomTitles.length) {
                                return RotatedBox(
                                  quarterTurns: 45, // Hiển thị theo chiều dọc tự nhiên
                                  child: Text(
                                    bottomTitles[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          left: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.blue.shade600,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 5,
                                color: Colors.blue.shade600,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.shade50,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade50.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.white,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(12),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                touchedSpot.y.toStringAsFixed(2),
                                const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _AnimatedKPICard(
                        label: 'GPA HK hiện tại',
                        value: currentGPA.toStringAsFixed(2),
                        color: Colors.blue,
                        icon: Icons.grade,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnimatedKPICard(
                        label: 'Xếp loại',
                        value: currentXepLoai,
                        color: _getXepLoaiColor(currentXepLoai),
                        icon: Icons.star,
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

class _AnimatedKPICard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _AnimatedKPICard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * animValue),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

