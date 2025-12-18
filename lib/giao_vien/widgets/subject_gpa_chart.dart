import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class SubjectGPAChart extends StatefulWidget {
  final ClassModel selectedClass;
  final Animation<double>? animation;
  final TeacherAdvisor? teacherData;

  const SubjectGPAChart({
    super.key,
    required this.selectedClass,
    this.animation,
    this.teacherData,
  });

  @override
  State<SubjectGPAChart> createState() => _SubjectGPAChartState();
}

class _SubjectGPAChartState extends State<SubjectGPAChart> {
  String? selectedNamHoc;
  String? selectedHocKy;

  @override
  void initState() {
    super.initState();
    // Tự động chọn học kỳ đầu tiên nếu có dữ liệu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSelection();
      }
    });
  }

  void _initializeSelection() {
    if (widget.teacherData?.subjectGPAsByClass != null && mounted) {
      // Lọc dữ liệu theo lớp
      final classData = widget.teacherData!.subjectGPAsByClass!.where((item) {
        return item.tenLop == widget.selectedClass.tenLop || 
               item.tenLop == widget.selectedClass.maLop ||
               item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
               item.tenLop.trim() == widget.selectedClass.maLop.trim();
      }).toList();

      if (classData.isNotEmpty && mounted) {
        final firstItem = classData.first;
        setState(() {
          selectedNamHoc = firstItem.tenNamHoc;
          selectedHocKy = firstItem.maHocKy;
        });
      }
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
    return hocKy;
  }

  List<ClassSubjectGPAResponse> _getFilteredData() {
    if (widget.teacherData?.subjectGPAsByClass == null || 
        widget.teacherData!.subjectGPAsByClass!.isEmpty ||
        selectedNamHoc == null || 
        selectedHocKy == null) {
      return [];
    }

    // Lọc dữ liệu theo lớp trước
    final classData = widget.teacherData!.subjectGPAsByClass!.where((item) {
      return item.tenLop == widget.selectedClass.tenLop || 
             item.tenLop == widget.selectedClass.maLop ||
             item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
             item.tenLop.trim() == widget.selectedClass.maLop.trim();
    }).toList();

    if (classData.isEmpty) {
      return [];
    }

    // Lọc theo năm học và học kỳ
    final normalizedSelectedHocKy = _normalizeHocKy(selectedHocKy!);
    
    return classData.where((item) {
      final normalizedItemHocKy = _normalizeHocKy(item.maHocKy);
      return item.tenNamHoc == selectedNamHoc &&
             normalizedItemHocKy == normalizedSelectedHocKy;
    }).toList();
  }

  List<String> _getAvailableNamHoc() {
    if (widget.teacherData?.subjectGPAsByClass == null) {
      return [];
    }
    
    final classData = widget.teacherData!.subjectGPAsByClass!.where((item) {
      return item.tenLop == widget.selectedClass.tenLop || 
             item.tenLop == widget.selectedClass.maLop ||
             item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
             item.tenLop.trim() == widget.selectedClass.maLop.trim();
    }).toList();
    
    return classData.map((e) => e.tenNamHoc).toSet().toList()..sort();
  }

  List<String> _getAvailableHocKy(String? namHoc) {
    if (widget.teacherData?.subjectGPAsByClass == null || namHoc == null) {
      return [];
    }
    
    final classData = widget.teacherData!.subjectGPAsByClass!.where((item) {
      return (item.tenLop == widget.selectedClass.tenLop || 
              item.tenLop == widget.selectedClass.maLop ||
              item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
              item.tenLop.trim() == widget.selectedClass.maLop.trim()) &&
             item.tenNamHoc == namHoc;
    }).toList();
    
    return classData.map((e) => e.maHocKy).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    final availableNamHoc = _getAvailableNamHoc();
    final availableHocKy = _getAvailableHocKy(selectedNamHoc);

    // Đảm bảo selectedHocKy hợp lệ
    if (selectedHocKy != null && !availableHocKy.contains(selectedHocKy) && availableHocKy.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedHocKy = availableHocKy.first;
          });
        }
      });
    }

    // Sắp xếp theo tên môn học
    filteredData.sort((a, b) => a.tenMonHoc.compareTo(b.tenMonHoc));

    // Tính maxY để hiển thị
    final maxGPA = filteredData.isEmpty 
        ? 10.0 
        : filteredData.map((e) => e.gpa).reduce((a, b) => a > b ? a : b);

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
                        Colors.pink.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.pink.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.3),
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
                                    Colors.pink.shade400,
                                    Colors.pink.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withValues(alpha: 0.4),
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
                                'GPA trung bình các môn',
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
                      
                      // Combobox để chọn năm học và học kỳ
                      if (availableNamHoc.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedNamHoc,
                                decoration: InputDecoration(
                                  labelText: 'Năm học',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.8),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                items: availableNamHoc.map((namHoc) {
                                  return DropdownMenuItem(
                                    value: namHoc,
                                    child: Text(namHoc),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && mounted) {
                                    setState(() {
                                      selectedNamHoc = value;
                                      // Reset học kỳ khi đổi năm học
                                      final newHocKy = _getAvailableHocKy(value);
                                      selectedHocKy = newHocKy.isNotEmpty ? newHocKy.first : null;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: availableHocKy.contains(selectedHocKy) ? selectedHocKy : (availableHocKy.isNotEmpty ? availableHocKy.first : null),
                                decoration: InputDecoration(
                                  labelText: 'Học kỳ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.8),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                items: availableHocKy.map((hocKy) {
                                  return DropdownMenuItem(
                                    value: hocKy,
                                    child: Text(hocKy),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && mounted) {
                                    setState(() {
                                      selectedHocKy = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      if (availableNamHoc.isNotEmpty) const SizedBox(height: 20),
                      
                      // Biểu đồ cột
                      SizedBox(
                        height: 280,
                        child: filteredData.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có dữ liệu',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                child: SizedBox(
                                  width: (filteredData.length * 60.0).clamp(
                                      MediaQuery.of(context).size.width - 40,
                                      double.infinity),
                                  height: 250,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: (maxGPA * 1.2).clamp(5.0, 10.0),
                                      minY: 0,
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (group) =>
                                              Colors.pink.shade700,
                                          tooltipRoundedRadius: 8,
                                          tooltipPadding:
                                              const EdgeInsets.all(12),
                                          tooltipMargin: 8,
                                          getTooltipItem: (group, groupIndex,
                                              rod, rodIndex) {
                                            final item = filteredData[group.x.toInt()];
                                            return BarTooltipItem(
                                              '${item.tenMonHoc}\nGPA: ${item.gpa.toStringAsFixed(2)}',
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
                                              if (value.toInt() < filteredData.length) {
                                                final subject = filteredData[value.toInt()];
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
                                            reservedSize:
                                                filteredData.length > 10 ? 120 : 100,
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            interval: 2,
                                            getTitlesWidget: (value, meta) {
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 4),
                                                child: Text(
                                                  value.toStringAsFixed(0),
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
                                        return BarChartGroupData(
                                          x: entry.key,
                                          barRods: [
                                            BarChartRodData(
                                              toY: entry.value.gpa,
                                              color: Colors.pink.shade600,
                                              width: 25,
                                              borderRadius:
                                                  const BorderRadius.vertical(
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

