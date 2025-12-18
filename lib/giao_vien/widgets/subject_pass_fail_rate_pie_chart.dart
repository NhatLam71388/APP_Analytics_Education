import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class SubjectPassFailRatePieChart extends StatefulWidget {
  final ClassModel selectedClass;
  final Animation<double>? animation;
  final TeacherAdvisor? teacherData;

  const SubjectPassFailRatePieChart({
    super.key,
    required this.selectedClass,
    this.animation,
    this.teacherData,
  });

  @override
  State<SubjectPassFailRatePieChart> createState() => _SubjectPassFailRatePieChartState();
}

class _SubjectPassFailRatePieChartState extends State<SubjectPassFailRatePieChart> {
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
    if (widget.teacherData?.subjectPassFailRatesBySemester != null && mounted) {
      // Lọc dữ liệu theo lớp
      final classData = widget.teacherData!.subjectPassFailRatesBySemester!.where((item) {
        return item.tenLop == widget.selectedClass.tenLop || 
               item.tenLop == widget.selectedClass.maLop ||
               item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
               item.tenLop.trim() == widget.selectedClass.maLop.trim();
      }).toList();

      if (classData.isNotEmpty && mounted) {
        final firstItem = classData.first;
        setState(() {
          selectedNamHoc = firstItem.tenNamHoc;
          selectedHocKy = firstItem.tenHocKy;
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

  SubjectPassFailRateBySemesterResponse? _getSelectedData() {
    if (widget.teacherData?.subjectPassFailRatesBySemester == null || 
        widget.teacherData!.subjectPassFailRatesBySemester!.isEmpty ||
        selectedNamHoc == null || 
        selectedHocKy == null) {
      return null;
    }

    // Lọc dữ liệu theo lớp trước
    final classData = widget.teacherData!.subjectPassFailRatesBySemester!.where((item) {
      return item.tenLop == widget.selectedClass.tenLop || 
             item.tenLop == widget.selectedClass.maLop ||
             item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
             item.tenLop.trim() == widget.selectedClass.maLop.trim();
    }).toList();

    if (classData.isEmpty) {
      return null;
    }

    // Tìm dữ liệu theo lớp, năm học và học kỳ
    final normalizedSelectedHocKy = _normalizeHocKy(selectedHocKy!);
    
    try {
      return classData.firstWhere(
        (item) {
          final normalizedItemHocKy = _normalizeHocKy(item.tenHocKy);
          return item.tenNamHoc == selectedNamHoc &&
                 normalizedItemHocKy == normalizedSelectedHocKy;
        },
        orElse: () => classData.first,
      );
    } catch (e) {
      return null;
    }
  }

  List<String> _getAvailableNamHoc() {
    if (widget.teacherData?.subjectPassFailRatesBySemester == null) {
      return [];
    }
    
    final classData = widget.teacherData!.subjectPassFailRatesBySemester!.where((item) {
      return item.tenLop == widget.selectedClass.tenLop || 
             item.tenLop == widget.selectedClass.maLop ||
             item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
             item.tenLop.trim() == widget.selectedClass.maLop.trim();
    }).toList();
    
    return classData.map((e) => e.tenNamHoc).toSet().toList()..sort();
  }

  List<String> _getAvailableHocKy(String? namHoc) {
    if (widget.teacherData?.subjectPassFailRatesBySemester == null || namHoc == null) {
      return [];
    }
    
    final classData = widget.teacherData!.subjectPassFailRatesBySemester!.where((item) {
      return (item.tenLop == widget.selectedClass.tenLop || 
              item.tenLop == widget.selectedClass.maLop ||
              item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
              item.tenLop.trim() == widget.selectedClass.maLop.trim()) &&
             item.tenNamHoc == namHoc;
    }).toList();
    
    return classData.map((e) => e.tenHocKy).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = _getSelectedData();
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

    // Tính tỷ lệ phần trăm
    final tyLeDau = ((selectedData?.tyLeDau ?? 0.0) * 100);
    final tyLeRot = ((selectedData?.tyLeRot ?? 0.0) * 100);

    // Tạo danh sách sections cho pie chart
    final sections = <PieChartSectionData>[];
    
    if (tyLeDau > 0) {
      sections.add(PieChartSectionData(
        value: tyLeDau,
        title: '${tyLeDau.toStringAsFixed(1)}%',
        color: Colors.green.shade600,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (tyLeRot > 0) {
      sections.add(PieChartSectionData(
        value: tyLeRot,
        title: '${tyLeRot.toStringAsFixed(1)}%',
        color: Colors.red.shade600,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
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
                                Icons.pie_chart,
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
                                'Tỷ lệ phần trăm qua/rớt môn',
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
                      
                      // Biểu đồ tròn
                      SizedBox(
                        width: double.infinity,
                        height: 250,
                        child: sections.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có dữ liệu',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 45,
                                  sections: sections,
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Legend và thông tin chi tiết
                      Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (tyLeDau > 0)
                                _buildLegendItem(Colors.green, 'Qua', tyLeDau),
                              if (tyLeRot > 0)
                                _buildLegendItem(Colors.red, 'Rớt', tyLeRot),
                            ],
                          ),
                          if (selectedData != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem('Số đậu', selectedData.soDau?.toString() ?? '0', Colors.green),
                                _buildInfoItem('Số rớt', selectedData.soRot?.toString() ?? '0', Colors.red),
                                _buildInfoItem('Tổng lượt', selectedData.tongLuot.toString(), Colors.blue),
                              ],
                            ),
                          ],
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

  Widget _buildLegendItem(Color color, String label, double percent) {
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
        mainAxisSize: MainAxisSize.min,
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
            '$label (${percent.toStringAsFixed(1)}%)',
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

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}







