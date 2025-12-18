import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/student_academic.dart';
import '../../services/student_api_service.dart';

class PassRateChart extends StatefulWidget {
  final StudentAcademic studentData;
  final Animation<double>? animation;

  const PassRateChart({
    super.key,
    required this.studentData,
    this.animation,
  });

  @override
  State<PassRateChart> createState() => _PassRateChartState();
}

class _PassRateChartState extends State<PassRateChart> {
  List<PassRateBySemesterResponse>? _passRates;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPassRates();
  }

  Future<void> _loadPassRates() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final passRates = await StudentApiService.getPassRateBySemester();
      
      if (!mounted) return;
      
      setState(() {
        _passRates = passRates;
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

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ studentData
    if (_errorMessage != null || _passRates == null || _passRates!.isEmpty) {
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

  Widget _buildFromStudentData() {
    return _buildContent(
      passRates: widget.studentData.semesters.asMap().entries.map((entry) {
        final passRate = entry.value.calculatePassRate();
        return _PassRateData(
          hocKy: 'HK${entry.value.hocKySo}',
          passRate: passRate,
        );
      }).toList(),
    );
  }

  Widget _buildFromAPI() {
    // Sắp xếp theo năm học và học kỳ
    final sortedPassRates = List<PassRateBySemesterResponse>.from(_passRates!)
      ..sort((a, b) {
        final yearCompare = a.tenNamHoc.compareTo(b.tenNamHoc);
        if (yearCompare != 0) return yearCompare;
        return a.tenHocKy.compareTo(b.tenHocKy);
      });

    // Tạo dữ liệu cho chart
    final passRateData = sortedPassRates.map((rate) {
      // Extract số học kỳ từ "HK1", "HK2", etc.
      final hocKyMatch = RegExp(r'HK(\d+)').firstMatch(rate.tenHocKy);
      final hocKy = hocKyMatch != null ? 'HK${hocKyMatch.group(1)}' : rate.tenHocKy;
      
      return _PassRateData(
        hocKy: hocKy,
        passRate: rate.tyLeQuaMon * 100, // Chuyển từ 0-1 sang 0-100
      );
    }).toList();

    return _buildContent(passRates: passRateData);
  }

  Widget _buildContent({required List<_PassRateData> passRates}) {
    if (passRates.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
                        Colors.orange.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.orange.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
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
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bar_chart,
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
                          'Tỷ Lệ Đậu Môn Học',
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
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.grey.shade800,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < passRates.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    passRates[value.toInt()].hocKy,
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
                            reservedSize: 35,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toInt()}%',
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
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      barGroups: passRates.asMap().entries.map((entry) {
                        final passRate = entry.value.passRate;
                        final color = passRate >= 80
                            ? Colors.green
                            : passRate >= 60
                                ? Colors.orange
                                : Colors.red;
                        
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: passRate,
                              color: color,
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: Colors.grey.shade100,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.green, '≥80%', 'Tốt'),
                    const SizedBox(width: 14),
                    _buildLegendItem(Colors.orange, '60-79%', 'Khá'),
                    const SizedBox(width: 14),
                    _buildLegendItem(Colors.red, '<60%', 'Cần cải thiện'),
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

  Widget _buildLegendItem(Color color, String range, String label) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                range,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper class để lưu dữ liệu pass rate
class _PassRateData {
  final String hocKy;
  final double passRate;

  _PassRateData({
    required this.hocKy,
    required this.passRate,
  });
}

