import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class SubjectPassRateChart extends StatefulWidget {
  final List<ClassModel> classes;
  final ClassSemesterData semester;
  final int maleCount; // Số sinh viên nam
  final int femaleCount; // Số sinh viên nữ
  final Animation<double>? animation;

  const SubjectPassRateChart({
    super.key,
    required this.classes,
    required this.semester,
    required this.maleCount,
    required this.femaleCount,
    this.animation,
  });

  @override
  State<SubjectPassRateChart> createState() => _SubjectPassRateChartState();
}

class _SubjectPassRateChartState extends State<SubjectPassRateChart> {
  List<SubjectPassRateResponse> _data = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allData = await TeacherApiService.getStudentPassRateBySubject();
      
      // Lọc dữ liệu theo học kỳ và năm học
      final filteredData = _filterDataBySemester(allData);
      
      // Chỉ lấy những môn có SoSV_Dau > 0
      final dataWithPass = filteredData.where((item) => item.soSV_Dau > 0).toList();
      
      setState(() {
        _data = dataWithPass;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
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

  // Extract năm học và học kỳ từ semester.hocKy
  String? _extractNamHoc() {
    final parts = widget.semester.hocKy.split('-');
    if (parts.length >= 3) {
      return '${parts[1]}-${parts[2]}';
    }
    return '${widget.semester.namHoc}-${widget.semester.namHoc + 1}';
  }

  String? _extractHocKy() {
    final parts = widget.semester.hocKy.split('-');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return widget.semester.hocKy;
  }

  // Helper method để normalize tenNamHoc (loại bỏ khoảng trắng)
  String _normalizeNamHoc(String namHoc) {
    return namHoc.replaceAll(' ', '').trim();
  }

  List<SubjectPassRateResponse> _filterDataBySemester(List<SubjectPassRateResponse> allData) {
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = hocKy != null ? _normalizeHocKy(hocKy) : null;
    final normalizedNamHoc = namHoc != null ? _normalizeNamHoc(namHoc) : null;

    return allData.where((item) {
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
    if (_isLoading) {
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
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null || _data.isEmpty) {
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
                  ),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu tỷ lệ sinh viên đậu',
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

    // Sắp xếp theo số sinh viên đậu giảm dần
    _data.sort((a, b) => b.soSV_Dau.compareTo(a.soSV_Dau));

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
                                'Tỷ Lệ Sinh Viên Đậu Theo Môn',
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
                            width: (_data.length * 50.0).clamp(300.0, double.infinity).toDouble(),
                            height: 220, // Tăng height để chart hiển thị đầy đủ, có thêm không gian cho tooltip
                            child: Builder(
                              builder: (context) {
                                if (_data.isEmpty) {
                                  return const Center(child: Text('Chưa có dữ liệu'));
                                }
                                
                                // Tính maxY dựa trên tỷ lệ phần trăm (100%)
                                final maxY = 100.0;
                                
                                return BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxY,
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) => Colors.teal.shade700,
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: const EdgeInsets.all(12),
                                        tooltipMargin: 8, // Thêm margin để tooltip không bị cắt
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          final data = _data[groupIndex];
                                          final totalStudents = widget.maleCount + widget.femaleCount;
                                          final tyLe = totalStudents > 0
                                              ? (data.soSV_Dau / totalStudents * 100)
                                              : 0.0;
                                          return BarTooltipItem(
                                            '${data.tenMonHoc}\nSố SV đậu: ${data.soSV_Dau}\nTỷ lệ: ${tyLe.toStringAsFixed(1)}%',
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
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() < _data.length) {
                                              final subject = _data[value.toInt()];
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: RotatedBox(
                                                  quarterTurns: 3,
                                                  child: Text(
                                                    subject.tenMonHoc,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                          reservedSize: _data.length > 10 ? 120 : 100,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 35, // Tăng reservedSize để "100%" hiển thị trên một dòng
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
                                    barGroups: _data.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final data = entry.value;
                                      
                                      // Tính tỷ lệ phần trăm dựa trên tổng sinh viên (nam + nữ)
                                      final totalStudents = widget.maleCount + widget.femaleCount;
                                      final tyLe = totalStudents > 0
                                          ? (data.soSV_Dau / totalStudents * 100).clamp(0.0, 100.0)
                                          : 0.0;
                                      
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            fromY: 0,
                                            toY: tyLe,
                                            color: Colors.teal.shade600,
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
