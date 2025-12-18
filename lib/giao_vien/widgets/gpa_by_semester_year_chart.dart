import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';

class GPABySemesterYearChart extends StatelessWidget {
  final ClassModel selectedClass;
  final Animation<double>? animation;
  final TeacherAdvisor? teacherData; // Để lấy dữ liệu từ API

  const GPABySemesterYearChart({
    super.key,
    required this.selectedClass,
    this.animation,
    this.teacherData,
  });

  // Helper method để normalize hocKy
  String _normalizeHocKy(String hocKy) {
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    return hocKy;
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ API nếu có, lọc theo lớp
    final chartData = <Map<String, dynamic>>[];
    
    if (teacherData?.subjectGPAsByClass != null) {
      // Lọc dữ liệu theo lớp (thử cả tenLop và maLop)
      final filteredData = teacherData!.subjectGPAsByClass!.where((item) {
        return item.tenLop == selectedClass.tenLop || 
               item.tenLop == selectedClass.maLop ||
               item.tenLop.trim() == selectedClass.tenLop.trim() ||
               item.tenLop.trim() == selectedClass.maLop.trim();
      }).toList();
      
      // Nhóm dữ liệu theo học kỳ và năm học, tính GPA trung bình
      final Map<String, List<double>> gpaBySemesterYear = {};
      
      for (var item in filteredData) {
        final normalizedHocKy = _normalizeHocKy(item.maHocKy);
        final key = '${item.tenNamHoc} - $normalizedHocKy';
        gpaBySemesterYear.putIfAbsent(key, () => []).add(item.gpa);
      }
      
      // Tính GPA trung bình cho mỗi học kỳ/năm học
      for (var entry in gpaBySemesterYear.entries) {
        final parts = entry.key.split(' - ');
        final namHoc = parts[0];
        final hocKy = parts.length > 1 ? parts[1] : '';
        final avgGPA = entry.value.reduce((a, b) => a + b) / entry.value.length;
        
        chartData.add({
          'key': entry.key,
          'namHoc': namHoc,
          'hocKy': hocKy,
          'gpa': avgGPA,
        });
      }
    }
    
    // Fallback: dùng dữ liệu từ ClassModel nếu không có từ API
    if (chartData.isEmpty) {
      final semesterDataList = selectedClass.semesterData;
      
      for (var semester in semesterDataList) {
        // Tạo key từ năm học và học kỳ
        final parts = semester.hocKy.split('-');
        String namHoc = '';
        String hocKy = '';
        
        if (parts.length >= 3) {
          namHoc = '${parts[1]}-${parts[2]}';
          hocKy = parts[0];
        } else if (parts.length == 2) {
          hocKy = parts[0];
          namHoc = '${semester.namHoc}-${semester.namHoc + 1}';
        } else {
          hocKy = semester.hocKy;
          namHoc = '${semester.namHoc}-${semester.namHoc + 1}';
        }
        
        chartData.add({
          'key': '$namHoc - $hocKy',
          'namHoc': namHoc,
          'hocKy': hocKy,
          'gpa': semester.gpa,
        });
      }
    }
    
    // Sắp xếp theo năm học và học kỳ
    chartData.sort((a, b) {
      final namHocCompare = a['namHoc'].toString().compareTo(b['namHoc'].toString());
      if (namHocCompare != 0) return namHocCompare;
      return a['hocKy'].toString().compareTo(b['hocKy'].toString());
    });

    return FadeTransition(
      opacity: animation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: animation != null
            ? Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation!,
                curve: Curves.easeOutCubic,
              ))
            : const AlwaysStoppedAnimation(Offset.zero),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (context, scaleValue, child) {
            final clampedValue = scaleValue.clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.95 + (0.05 * clampedValue),
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
                        Colors.indigo.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.indigo.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.3),
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
                              final clampedValue = value.clamp(0.0, 1.0);
                              return Transform.scale(
                                scale: clampedValue,
                                child: Transform.rotate(
                                  angle: (1 - clampedValue) * 0.3,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.indigo.shade400,
                                    Colors.indigo.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withValues(alpha: 0.4),
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
                                'GPA theo học kỳ năm học',
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
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: SizedBox(
                            width: (chartData.length * 60.0).clamp(300.0, double.infinity).toDouble(),
                            height: 220,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 10.0,
                                minY: 0.0,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => Colors.indigo.shade700,
                                    tooltipRoundedRadius: 8,
                                    tooltipPadding: const EdgeInsets.all(12),
                                    tooltipMargin: 8,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final data = chartData[groupIndex];
                                      return BarTooltipItem(
                                        '${data['key']}\nGPA: ${rod.toY.toStringAsFixed(2)}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 70,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() < chartData.length) {
                                          final data = chartData[value.toInt()];
                                          // Parse namHoc để lấy năm bắt đầu
                                          final namHocStr = data['namHoc'].toString();
                                          String namHoc = namHocStr;
                                          
                                          // Nếu format là "2024-2025", chuyển thành "2024 - 2025"
                                          if (namHocStr.contains('-') && !namHocStr.contains(' - ')) {
                                            final parts = namHocStr.split('-');
                                            if (parts.length >= 2) {
                                              namHoc = '${parts[0]} - ${parts[1]}';
                                            }
                                          }
                                          
                                          final hocKy = data['hocKy'].toString();
                                          
                                          return RotatedBox(
                                            quarterTurns: -45,
                                            child: Text(
                                              '$namHoc\n$hocKy',
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
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: 2,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Text(
                                            value.toInt().toString(),
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
                                  horizontalInterval: 2,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    );
                                  },
                                ),
                                barGroups: chartData.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final data = entry.value;
                                  final gpa = data['gpa'] as double;
                                  
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: gpa,
                                        color: Colors.indigo.shade600,
                                        width: 30,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
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

