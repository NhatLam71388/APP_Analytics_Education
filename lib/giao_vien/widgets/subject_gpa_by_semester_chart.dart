import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class SubjectGPABySemesterChart extends StatefulWidget {
  final List<ClassModel> classes;
  final ClassSemesterData semester;
  final TeacherAdvisor? teacherData;
  final Animation<double>? animation;

  const SubjectGPABySemesterChart({
    super.key,
    required this.classes,
    required this.semester,
    this.teacherData,
    this.animation,
  });

  @override
  State<SubjectGPABySemesterChart> createState() => _SubjectGPABySemesterChartState();
}

class _SubjectGPABySemesterChartState extends State<SubjectGPABySemesterChart> {
  String? selectedMonHoc;

  @override
  void initState() {
    super.initState();
    // Tự động chọn môn học đầu tiên nếu có dữ liệu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSelection();
      }
    });
  }

  void _initializeSelection() {
    if (widget.teacherData?.subjectGPAsByClass != null && mounted) {
      final filteredData = _getFilteredDataBySemester();
      if (filteredData.isNotEmpty && mounted) {
        final subjects = filteredData.map((e) => e.tenMonHoc).toSet().toList()..sort();
        if (subjects.isNotEmpty) {
          setState(() {
            selectedMonHoc = subjects.first;
          });
        }
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
      // Trim để loại bỏ khoảng trắng
      return '${parts[1].trim()}-${parts[2].trim()}';
    }
    // Fallback: dùng từ semester.namHoc
    return '${widget.semester.namHoc}-${widget.semester.namHoc + 1}';
  }

  String? _extractHocKy() {
    final parts = widget.semester.hocKy.split('-');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return widget.semester.hocKy.trim();
  }

  // Helper method để normalize tenNamHoc (loại bỏ khoảng trắng)
  String _normalizeNamHoc(String namHoc) {
    return namHoc.replaceAll(' ', '').trim();
  }

  List<ClassSubjectGPAResponse> _getFilteredDataBySemester() {
    if (widget.teacherData?.subjectGPAsByClass == null || 
        widget.teacherData!.subjectGPAsByClass!.isEmpty) {
      debugPrint('🔍 SubjectGPABySemesterChart: subjectGPAsByClass is null or empty');
      return [];
    }

    // Nếu không có lớp nào, trả về rỗng
    if (widget.classes.isEmpty) {
      debugPrint('🔍 SubjectGPABySemesterChart: classes is empty');
      return [];
    }

    final classNames = widget.classes.map((c) => c.tenLop).toSet();
    final classMaLops = widget.classes.map((c) => c.maLop).toSet();
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = hocKy != null ? _normalizeHocKy(hocKy) : null;
    final normalizedNamHoc = namHoc != null ? _normalizeNamHoc(namHoc) : null;

    debugPrint('🔍 SubjectGPABySemesterChart: Looking for data with:');
    debugPrint('   - semester.hocKy: ${widget.semester.hocKy}');
    debugPrint('   - namHoc: $namHoc (normalized: $normalizedNamHoc)');
    debugPrint('   - hocKy: $hocKy (normalized: $normalizedHocKy)');
    debugPrint('   - classNames: $classNames');
    debugPrint('   - Total items in subjectGPAsByClass: ${widget.teacherData!.subjectGPAsByClass!.length}');
    
    // Log một vài items đầu tiên để xem format thực tế
    final sampleItems = widget.teacherData!.subjectGPAsByClass!.take(3).toList();
    for (var item in sampleItems) {
      debugPrint('   - Sample item: tenLop="${item.tenLop}", tenNamHoc="${item.tenNamHoc}", maHocKy="${item.maHocKy}"');
    }
    
    // Tìm tất cả các năm học và học kỳ có trong dữ liệu cho các lớp này
    final availableData = widget.teacherData!.subjectGPAsByClass!
        .where((item) => classNames.contains(item.tenLop))
        .map((item) => '${item.tenNamHoc}-${item.maHocKy}')
        .toSet();
    debugPrint('   - Available data for these classes: $availableData');

    final filtered = widget.teacherData!.subjectGPAsByClass!.where((item) {
      // Kiểm tra lớp
      final matchesClass = classNames.contains(item.tenLop) || 
                          classMaLops.contains(item.tenLop) ||
                          classNames.any((name) => item.tenLop.trim() == name.trim()) ||
                          classMaLops.any((maLop) => item.tenLop.trim() == maLop.trim());
      
      if (!matchesClass) {
        return false;
      }

      // Kiểm tra năm học (normalize để loại bỏ khoảng trắng)
      if (normalizedNamHoc != null) {
        final normalizedItemNamHoc = _normalizeNamHoc(item.tenNamHoc);
        if (normalizedItemNamHoc != normalizedNamHoc) {
          debugPrint('   ❌ Item "${item.tenLop}" không match namHoc: "$normalizedItemNamHoc" vs "$normalizedNamHoc"');
          return false;
        }
      }

      // Kiểm tra học kỳ
      if (normalizedHocKy != null) {
        final normalizedItemHocKy = _normalizeHocKy(item.maHocKy);
        if (normalizedItemHocKy != normalizedHocKy) {
          debugPrint('   ❌ Item "${item.tenLop}" không match hocKy: "$normalizedItemHocKy" vs "$normalizedHocKy"');
          return false;
        }
      }

      debugPrint('   ✅ Item "${item.tenLop}" match: namHoc="${item.tenNamHoc}", maHocKy="${item.maHocKy}"');
      return true;
    }).toList();

    debugPrint('   - Filtered data count: ${filtered.length}');
    return filtered;
  }

  List<ClassSubjectGPAResponse> _getFilteredDataBySubject() {
    if (selectedMonHoc == null) {
      return [];
    }

    final semesterData = _getFilteredDataBySemester();
    return semesterData.where((item) => item.tenMonHoc == selectedMonHoc).toList();
  }

  List<String> _getAvailableMonHoc() {
    final semesterData = _getFilteredDataBySemester();
    return semesterData.map((e) => e.tenMonHoc).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final availableMonHoc = _getAvailableMonHoc();
    final filteredData = _getFilteredDataBySubject();

    if (availableMonHoc.isEmpty) {
      // Kiểm tra xem có dữ liệu tổng thể không
      final hasData = widget.teacherData?.subjectGPAsByClass != null && 
                      widget.teacherData!.subjectGPAsByClass!.isNotEmpty;
      final hasClasses = widget.classes.isNotEmpty;
      
      String message = 'Chưa có dữ liệu GPA môn học';
      if (hasData && hasClasses) {
        message = 'Chưa có dữ liệu GPA môn học cho học kỳ này';
      } else if (!hasData) {
        message = 'Chưa có dữ liệu GPA môn học từ API';
      } else if (!hasClasses) {
        message = 'Chưa có lớp nào trong học kỳ này';
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
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

    // Sắp xếp theo GPA giảm dần
    filteredData.sort((a, b) => b.gpa.compareTo(a.gpa));

    // Tính maxY để hiển thị
    double maxY = 10.0;
    if (filteredData.isNotEmpty) {
      final maxGPA = filteredData.map((e) => e.gpa).reduce((a, b) => a > b ? a : b);
      maxY = (maxGPA * 1.2).ceil().toDouble().clamp(10.0, 10.0);
    }

    // Tìm tên lớp dài nhất để tính reservedSize
    String longestClassName = '';
    if (filteredData.isNotEmpty) {
      longestClassName = filteredData.map((e) => e.tenLop).reduce((a, b) => a.length > b.length ? a : b);
    }
    final reservedSizeForBottom = (longestClassName.length * 7.0 + 20).clamp(60.0, 120.0);

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
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.book,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GPA Trung Bình Môn Học',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Theo lớp và môn học',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Combobox chọn môn học
                      DropdownButtonFormField<String>(
                        value: selectedMonHoc,
                        decoration: InputDecoration(
                          labelText: 'Chọn môn học',
                          labelStyle: TextStyle(color: Colors.grey.shade700),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        isExpanded: true,
                        items: availableMonHoc.map((monHoc) {
                          return DropdownMenuItem<String>(
                            value: monHoc,
                            child: Text(
                              monHoc,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return availableMonHoc.map((monHoc) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                monHoc,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              selectedMonHoc = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      if (filteredData.isNotEmpty)
                        SizedBox(
                          height: 350,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            child: SizedBox(
                              width: (filteredData.length * 80.0).clamp(400.0, double.infinity).toDouble(),
                              height: 350,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceBetween,
                                  maxY: maxY,
                                  minY: 0,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (group) => Colors.teal.shade600,
                                      tooltipRoundedRadius: 8,
                                      tooltipPadding: const EdgeInsets.all(8),
                                      tooltipMargin: 8,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final data = filteredData[group.x.toInt()];
                                        return BarTooltipItem(
                                          '${data.tenLop}\nGPA: ${data.gpa.toStringAsFixed(2)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
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
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() >= 0 && value.toInt() < filteredData.length) {
                                            final className = filteredData[value.toInt()].tenLop;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: RotatedBox(
                                                quarterTurns: 3,
                                                child: SizedBox(
                                                  width: longestClassName.length * 7.0 + 10,
                                                  child: Text(
                                                    className,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                        reservedSize: reservedSizeForBottom,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50,
                                        getTitlesWidget: (value, meta) {
                                          if (value % 1 == 0) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
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
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.shade300,
                                        strokeWidth: 1,
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
                                    final gpa = data.gpa;
                                    
                                    // Màu sắc gradient dựa trên GPA
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
                                          width: 40,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(4),
                                            topRight: Radius.circular(4),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (selectedMonHoc != null)
                        Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Text(
                            'Không có dữ liệu cho môn học này',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
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









