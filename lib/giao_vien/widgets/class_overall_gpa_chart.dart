import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class ClassOverallGPAChart extends StatelessWidget {
  final List<ClassModel> classes;
  final TeacherAdvisor? teacherData;
  final Animation<double>? animation;

  const ClassOverallGPAChart({
    super.key,
    required this.classes,
    this.teacherData,
    this.animation,
  });

  List<ClassOverallGPAResponse> _getFilteredData() {
    if (teacherData?.classOverallGPAs == null || 
        teacherData!.classOverallGPAs!.isEmpty) {
      return [];
    }

    final classNames = classes.map((c) => c.tenLop).toSet();
    final classMaLops = classes.map((c) => c.maLop).toSet();

    return teacherData!.classOverallGPAs!.where((item) {
      return classNames.contains(item.tenLop) || 
             classMaLops.contains(item.tenLop) ||
             classNames.any((name) => item.tenLop.trim() == name.trim()) ||
             classMaLops.any((maLop) => item.tenLop.trim() == maLop.trim());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();

    if (filteredData.isEmpty) {
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
                        Colors.purple.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.purple.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu GPA',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Sắp xếp theo GPA giảm dần
    filteredData.sort((a, b) => b.gpa.compareTo(a.gpa));

    // Tính maxY để hiển thị
    double maxY = 10.0;
    if (filteredData.isNotEmpty) {
      final maxGPA = filteredData.map((e) => e.gpa).reduce((a, b) => a > b ? a : b);
      maxY = (maxGPA * 1.2).ceil().toDouble().clamp(5.0, 10.0);
    }

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
                        Colors.purple.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.purple.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
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
                                    Colors.purple.shade400,
                                    Colors.purple.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school,
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
                                'GPA Trung Bình Các Lớp',
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
                        height: 280,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: SizedBox(
                            width: (filteredData.length * 50.0).clamp(300.0, double.infinity).toDouble(),
                            height: 220,
                            child: Builder(
                              builder: (context) {
                                return BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxY,
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) => Colors.purple.shade700,
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: const EdgeInsets.all(12),
                                        tooltipMargin: 8,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          final data = filteredData[groupIndex];
                                          return BarTooltipItem(
                                            '${data.tenLop}\nGPA: ${data.gpa.toStringAsFixed(2)}',
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
                                          interval: filteredData.length > 10 ? 2 : 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() < filteredData.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: SizedBox(
                                                  height: 200,
                                                  width: 50,
                                                  child: RotatedBox(
                                                    quarterTurns: 3,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        filteredData[value.toInt()].tenLop,
                                                        style: TextStyle(
                                                          color: Colors.grey.shade700,
                                                          fontSize: filteredData.length > 15 ? 9 : 11,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                          reservedSize: filteredData.length > 15 ? 100 : 80,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 25,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 2),
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
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.shade200,
                                          strokeWidth: 1,
                                          dashArray: [5, 5],
                                        );
                                      },
                                    ),
                                    barGroups: filteredData.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final data = entry.value;
                                      final gpa = data.gpa;
                                      
                                      // Màu sắc gradient dựa trên GPA (giữ nguyên màu)
                                      Color barColor;
                                      if (gpa >= 8.0) {
                                        barColor = Colors.green.shade600;
                                      } else if (gpa >= 6.5) {
                                        barColor = Colors.blue.shade600;
                                      } else if (gpa >= 5.0) {
                                        barColor = Colors.orange.shade600;
                                      } else {
                                        barColor = Colors.red.shade600;
                                      }

                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: gpa,
                                            color: barColor,
                                            width: 30,
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
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

