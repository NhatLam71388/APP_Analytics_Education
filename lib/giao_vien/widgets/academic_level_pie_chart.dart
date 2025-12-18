import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class AcademicLevelPieChart extends StatefulWidget {
  final ClassModel selectedClass;
  final Animation<double>? animation;
  final TeacherAdvisor? teacherData;

  const AcademicLevelPieChart({
    super.key,
    required this.selectedClass,
    this.animation,
    this.teacherData,
  });

  @override
  State<AcademicLevelPieChart> createState() => _AcademicLevelPieChartState();
}

class _AcademicLevelPieChartState extends State<AcademicLevelPieChart> {
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
    if (widget.teacherData?.academicLevelsByClass != null && mounted) {
      // Lọc dữ liệu theo lớp
      final classData = widget.teacherData!.academicLevelsByClass!.where((item) {
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

  ClassAcademicLevelResponse? _getSelectedData() {
    if (widget.teacherData?.academicLevelsByClass == null || 
        widget.teacherData!.academicLevelsByClass!.isEmpty ||
        selectedNamHoc == null || 
        selectedHocKy == null) {
      return null;
    }

    // Lọc dữ liệu theo lớp trước
    final classData = widget.teacherData!.academicLevelsByClass!.where((item) {
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
    if (widget.teacherData?.academicLevelsByClass == null) {
      return [];
    }
    
    final classData = widget.teacherData!.academicLevelsByClass!.where((item) {
      return item.tenLop == widget.selectedClass.tenLop || 
             item.tenLop == widget.selectedClass.maLop ||
             item.tenLop.trim() == widget.selectedClass.tenLop.trim() ||
             item.tenLop.trim() == widget.selectedClass.maLop.trim();
    }).toList();
    
    return classData.map((e) => e.tenNamHoc).toSet().toList()..sort();
  }

  List<String> _getAvailableHocKy(String? namHoc) {
    if (widget.teacherData?.academicLevelsByClass == null || namHoc == null) {
      return [];
    }
    
    final classData = widget.teacherData!.academicLevelsByClass!.where((item) {
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
    final xuatSac = (selectedData?.tlXuatSac ?? 0.0) * 100;
    final gioi = (selectedData?.tlGioi ?? 0.0) * 100;
    final kha = (selectedData?.tlKha ?? 0.0) * 100;
    final trungBinh = (selectedData?.tlTb ?? 0.0) * 100;
    final yeu = (selectedData?.tlYeu ?? 0.0) * 100;
    final kem = (selectedData?.tlKem ?? 0.0) * 100;

    // Tạo danh sách sections cho pie chart (chỉ hiển thị các mức có giá trị > 0)
    final sections = <PieChartSectionData>[];
    
    if (xuatSac > 0) {
      sections.add(PieChartSectionData(
        value: xuatSac,
        title: '${xuatSac.toStringAsFixed(1)}%',
        color: Colors.purple.shade600,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (gioi > 0) {
      sections.add(PieChartSectionData(
        value: gioi,
        title: '${gioi.toStringAsFixed(1)}%',
        color: Colors.green.shade600,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (kha > 0) {
      sections.add(PieChartSectionData(
        value: kha,
        title: '${kha.toStringAsFixed(1)}%',
        color: Colors.blue.shade600,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (trungBinh > 0) {
      sections.add(PieChartSectionData(
        value: trungBinh,
        title: '${trungBinh.toStringAsFixed(1)}%',
        color: Colors.orange.shade600,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (yeu > 0) {
      sections.add(PieChartSectionData(
        value: yeu,
        title: '${yeu.toStringAsFixed(1)}%',
        color: Colors.red.shade400,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (kem > 0) {
      sections.add(PieChartSectionData(
        value: kem,
        title: '${kem.toStringAsFixed(1)}%',
        color: Colors.red.shade800,
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
                        Colors.deepPurple.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.deepPurple.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
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
                                    Colors.deepPurple.shade400,
                                    Colors.deepPurple.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withValues(alpha: 0.4),
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
                                'Tỷ lệ phần trăm học lực theo lớp học kỳ',
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
                      
                      // Legend với layout tùy chỉnh
                      _buildCustomLegend(xuatSac, gioi, kha, trungBinh, yeu, kem),
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

  Widget _buildCustomLegend(
    double xuatSac,
    double gioi,
    double kha,
    double trungBinh,
    double yeu,
    double kem,
  ) {
    // Tạo danh sách các legend items có giá trị > 0
    final legendItems = <Widget>[];
    
    if (xuatSac > 0) {
      legendItems.add(_buildLegendItem(Colors.purple, 'Xuất sắc', xuatSac));
    }
    if (gioi > 0) {
      legendItems.add(_buildLegendItem(Colors.green, 'Giỏi', gioi));
    }
    if (kha > 0) {
      legendItems.add(_buildLegendItem(Colors.blue, 'Khá', kha));
    }
    if (trungBinh > 0) {
      legendItems.add(_buildLegendItem(Colors.orange, 'Trung bình', trungBinh));
    }
    if (yeu > 0) {
      legendItems.add(_buildLegendItem(Colors.red.shade400, 'Yếu', yeu));
    }
    if (kem > 0) {
      legendItems.add(_buildLegendItem(Colors.red.shade800, 'Kém', kem));
    }

    final itemCount = legendItems.length;

    // Xử lý layout theo số lượng phần tử
    if (itemCount == 0) {
      return const SizedBox.shrink();
    } else if (itemCount == 1) {
      // 1 phần tử: 1 dòng, căn giữa
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [legendItems[0]],
      );
    } else if (itemCount == 2) {
      // 2 phần tử: 1 dòng, dàn đều ra 2 bên
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          legendItems[0],
          legendItems[1],
        ],
      );
    } else if (itemCount == 3) {
      // 3 phần tử: 2 dòng, dòng đầu 2 phần tử dàn đều, dòng thứ 2 1 phần tử căn giữa
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              legendItems[0],
              legendItems[1],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [legendItems[2]],
          ),
        ],
      );
    } else {
      // 4+ phần tử: sử dụng Wrap như cũ
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: legendItems,
      );
    }
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
}

