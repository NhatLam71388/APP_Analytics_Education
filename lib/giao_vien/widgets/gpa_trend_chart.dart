import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../services/teacher_api_service.dart';

class GPATrendChart extends StatelessWidget {
  final List<ClassModel> classes;
  final List<ClassGPATrendResponse>? gpaTrendByClass; // Dữ liệu từ API Xu-Huong-GPA-Trung-Binh-Theo-Lop
  final Animation<double>? animation;

  const GPATrendChart({
    super.key,
    required this.classes,
    this.gpaTrendByClass,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy tất cả các năm học từ API nếu có, nếu không thì lấy từ classes
    final allYears = <String>{};
    if (gpaTrendByClass != null && gpaTrendByClass!.isNotEmpty) {
      // Lấy tất cả các năm học từ API
      for (var trend in gpaTrendByClass!) {
        trend.gpaByYear.forEach((year, gpa) {
          if (gpa != null) {
            allYears.add(year);
          }
        });
      }
    } else {
      // Fallback: lấy từ classes
      for (var classItem in classes) {
        for (var semester in classItem.semesterData) {
          // Extract năm học từ hocKy (ví dụ: "HK1-2023-2024" -> "2023-2024")
          final parts = semester.hocKy.split('-');
          if (parts.length >= 3) {
            allYears.add('${parts[1]}-${parts[2]}');
          }
        }
      }
    }
    final sortedYears = allYears.toList()..sort();

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
                        Colors.teal.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.teal.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
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
                                    Colors.teal.shade400,
                                    Colors.teal.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withValues(alpha: 0.4),
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
                                'Xu hướng GPA',
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
                            width: (sortedYears.length * 60.0 + classes.length * 20.0).clamp(300.0, double.infinity).toDouble(),
                            height: 250,
                            child: LineChart(
                          LineChartData(
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
                                  reservedSize: 50,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 4),
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
                                  reservedSize: 70,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < sortedYears.length) {
                                      final year = sortedYears[value.toInt()];
                                      // Format năm học: "2023-2024" -> "2023 - 2024"
                                      String formattedYear = year;
                                      if (year.contains('-') && !year.contains(' - ')) {
                                        final parts = year.split('-');
                                        if (parts.length >= 2) {
                                          formattedYear = '${parts[0]} - ${parts[1]}';
                                        }
                                      }
                                      
                                      return RotatedBox(
                                        quarterTurns: -45,
                                        child: Text(
                                          formattedYear,
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
                            lineBarsData: classes.asMap().entries.map((entry) {
                              final colors = [
                                Colors.teal.shade600,
                                Colors.blue.shade600,
                                Colors.purple.shade600,
                                Colors.orange.shade600,
                              ];
                              final color = colors[entry.key % colors.length];
                              
                              // Tìm dữ liệu từ API cho lớp này
                              final gpaTrend = gpaTrendByClass?.firstWhere(
                                (t) {
                                  // So sánh với nhiều cách để đảm bảo match
                                  return t.tenLop == entry.value.tenLop ||
                                         t.tenLop == entry.value.maLop ||
                                         t.tenLop.trim() == entry.value.tenLop.trim() ||
                                         t.tenLop.trim() == entry.value.maLop.trim() ||
                                         t.tenLop.trim().toLowerCase() == entry.value.tenLop.trim().toLowerCase() ||
                                         t.tenLop.trim().toLowerCase() == entry.value.maLop.trim().toLowerCase();
                                },
                                orElse: () => ClassGPATrendResponse(tenLop: entry.value.tenLop, gpaByYear: {}),
                              );
                              
                              final spots = sortedYears.asMap().entries.map((yearEntry) {
                                final year = yearEntry.value;
                                double? gpa;
                                
                                // Ưu tiên lấy từ API
                                if (gpaTrend != null && gpaTrend.gpaByYear.containsKey(year)) {
                                  gpa = gpaTrend.gpaByYear[year];
                                } else {
                                  // Fallback: tìm từ semesterData
                                  final semester = entry.value.semesterData.firstWhere(
                                    (s) => s.hocKy.contains(year),
                                    orElse: () => entry.value.semesterData.first,
                                  );
                                  gpa = semester.gpa;
                                }
                                
                                // Nếu gpa là null, không hiển thị điểm đó
                                if (gpa == null) {
                                  return null;
                                }
                                
                                return FlSpot(yearEntry.key.toDouble(), gpa);
                              }).where((spot) => spot != null).cast<FlSpot>().toList(); // Chỉ lấy các điểm có giá trị

                              return LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: color,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 5,
                                      color: color,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: color.withValues(alpha: 0.1),
                                ),
                              );
                            }).toList(),
                            minY: 0.0, // Set minY = 0
                            maxY: 10.0, // Set maxY = 10
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) => Colors.white,
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.all(12),
                                tooltipMargin: 8,
                              ),
                            ),
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



