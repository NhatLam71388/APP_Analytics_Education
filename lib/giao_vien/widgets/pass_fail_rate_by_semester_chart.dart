import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class PassFailRateBySemesterChart extends StatelessWidget {
  final List<ClassModel> classes;
  final ClassSemesterData semester;
  final TeacherAdvisor? teacherData;
  final Animation<double>? animation;

  const PassFailRateBySemesterChart({
    super.key,
    required this.classes,
    required this.semester,
    this.teacherData,
    this.animation,
  });

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

  // Extract năm học và học kỳ từ semester.hocKy
  String? _extractNamHoc() {
    final parts = semester.hocKy.split('-');
    if (parts.length >= 3) {
      return '${parts[1]}-${parts[2]}';
    }
    return '${semester.namHoc}-${semester.namHoc + 1}';
  }

  String? _extractHocKy() {
    final parts = semester.hocKy.split('-');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return semester.hocKy;
  }

  // Helper method để normalize tenNamHoc (loại bỏ khoảng trắng)
  String _normalizeNamHoc(String namHoc) {
    return namHoc.replaceAll(' ', '').trim();
  }

  List<SubjectPassFailRateBySemesterResponse> _getFilteredData() {
    if (teacherData?.subjectPassFailRatesBySemester == null || 
        teacherData!.subjectPassFailRatesBySemester!.isEmpty) {
      return [];
    }

    // Nếu không có lớp nào, trả về rỗng
    if (classes.isEmpty) {
      return [];
    }

    final classNames = classes.map((c) => c.tenLop).toSet();
    final classMaLops = classes.map((c) => c.maLop).toSet();
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = hocKy != null ? _normalizeHocKy(hocKy) : null;
    final normalizedNamHoc = namHoc != null ? _normalizeNamHoc(namHoc) : null;

    return teacherData!.subjectPassFailRatesBySemester!.where((item) {
      // Kiểm tra lớp
      final matchesClass = classNames.contains(item.tenLop) || 
                          classMaLops.contains(item.tenLop) ||
                          classNames.any((name) => item.tenLop.trim() == name.trim()) ||
                          classMaLops.any((maLop) => item.tenLop.trim() == maLop.trim());
      
      if (!matchesClass) return false;

      // Kiểm tra năm học (normalize để loại bỏ khoảng trắng)
      if (normalizedNamHoc != null) {
        final normalizedItemNamHoc = _normalizeNamHoc(item.tenNamHoc);
        if (normalizedItemNamHoc != normalizedNamHoc) {
          return false;
        }
      }

      // Kiểm tra học kỳ
      if (normalizedHocKy != null) {
        final normalizedItemHocKy = _normalizeHocKy(item.tenHocKy);
        if (normalizedItemHocKy != normalizedHocKy) {
          return false;
        }
      }

      return true;
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
                        Colors.amber.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.amber.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu tỷ lệ qua/rớt',
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

    // Sắp xếp theo tên lớp
    filteredData.sort((a, b) => a.tenLop.compareTo(b.tenLop));

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
                        Colors.amber.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.amber.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
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
                                    Colors.amber.shade400,
                                    Colors.amber.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.4),
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
                                'Tỷ Lệ Phần Trăm Qua/Rớt Môn',
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
                        height: 280, // Tăng height để có đủ không gian cho chart, tooltip và label cao nhất
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none, // Không clip để tooltip có thể hiển thị ngoài container
                          child: SizedBox(
                            width: (filteredData.length * 50.0).clamp(300.0, double.infinity).toDouble(),
                            height: 220, // Tăng height để chart hiển thị đầy đủ, có thêm không gian cho tooltip
                            child: Builder(
                              builder: (context) {
                                if (filteredData.isEmpty) {
                                  return const Center(child: Text('Chưa có dữ liệu'));
                                }
                                
                                return BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: 100.0, // Tỷ lệ phần trăm
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) => Colors.amber.shade700,
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: const EdgeInsets.all(12),
                                        tooltipMargin: 8, // Thêm margin để tooltip không bị cắt
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          final data = filteredData[group.x.toInt()];
                                          final tyLeDau = ((data.tyLeDau ?? 0.0) * 100);
                                          final tyLeRot = ((data.tyLeRot ?? 0.0) * 100);
                                          return BarTooltipItem(
                                            '${data.tenLop}\nĐậu: ${tyLeDau.toStringAsFixed(1)}%\nRớt: ${tyLeRot.toStringAsFixed(1)}%',
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
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: filteredData.length > 10 ? 2 : 1,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() < filteredData.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: SizedBox(
                                                height: 200, // Tăng chiều cao để chữ không bị rớt dòng (sau khi xoay sẽ là chiều rộng của text)
                                                width: 50, // Chiều rộng (sau khi xoay sẽ là chiều cao của text)
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
                                        reservedSize: filteredData.length > 15 ? 100 : 80, // Tăng reservedSize để phù hợp với chiều cao mới (height: 200)
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30, // Tăng reservedSize để "100%" hiển thị trên một dòng
                                        interval: 20, // Hiển thị mỗi 20%
                                        getTitlesWidget: (value, meta) {
                                          final intValue = value.toInt();
                                          
                                          // Hiển thị các giá trị: 0, 20, 40, 60, 80, 100
                                          if (intValue >= 0 && intValue <= 100 && intValue % 20 == 0) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 2),
                                              child: Text(
                                                '${intValue}%',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
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
                                    barGroups: filteredData.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final data = entry.value;
                                      
                                      // Tính tỷ lệ phần trăm
                                      final tyLeDau = ((data.tyLeDau ?? 0.0) * 100).clamp(0.0, 100.0);
                                      final tyLeRot = ((data.tyLeRot ?? 0.0) * 100).clamp(0.0, 100.0);
                                      
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          // Cột đỏ (rớt) - từ 0 lên trên đến tyLeRot
                                          BarChartRodData(
                                            fromY: 0,
                                            toY: tyLeRot,
                                            color: tyLeRot > 0 ? Colors.red.shade600 : Colors.transparent,
                                            width: 20,
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                          ),
                                          // Cột xanh (đậu) - từ 0 lên trên đến tyLeDau
                                          BarChartRodData(
                                            fromY: 0,
                                            toY: tyLeDau,
                                            color: Colors.green.shade600,
                                            width: 20,
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(4),
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(Colors.green, 'Đậu'),
                          const SizedBox(width: 20),
                          _buildLegendItem(Colors.red, 'Rớt'),
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

  Widget _buildLegendItem(Color color, String label) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clampedValue,
          child: Transform.scale(
            scale: 0.8 + (0.2 * clampedValue),
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

