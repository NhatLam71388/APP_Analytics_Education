import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/class_model.dart';
import '../../services/teacher_api_service.dart';

// Custom painter để vẽ các chấm với màu khác nhau cho từng lớp
class _MultiColorScatterPainter extends CustomPainter {
  final Map<String, List<ScatterSpot>> classScatterData;
  final Map<String, Color> classColors;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double chartWidth;
  final double chartHeight;
  final double leftPadding;
  final double bottomPadding;

  _MultiColorScatterPainter({
    required this.classScatterData,
    required this.classColors,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.chartWidth,
    required this.chartHeight,
    required this.leftPadding,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ các chấm cho từng lớp với màu tương ứng
    for (final entry in classScatterData.entries) {
      final spots = entry.value;
      final color = classColors[entry.key]!;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (final spot in spots) {
        // Tính toán vị trí x, y trong chart area
        final x = leftPadding + ((spot.x - minX) / (maxX - minX)) * chartWidth;
        final y = (size.height - bottomPadding) - ((spot.y - minY) / (maxY - minY)) * chartHeight;
        
        canvas.drawCircle(
          Offset(x, y),
          6,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MultiColorScatterPainter oldDelegate) {
    return oldDelegate.classScatterData != classScatterData || 
           oldDelegate.classColors != classColors;
  }
}


class StudentGPAConductScatterChart extends StatefulWidget {
  final List<ClassModel> classes;
  final ClassSemesterData semester;
  final Animation<double>? animation;

  const StudentGPAConductScatterChart({
    super.key,
    required this.classes,
    required this.semester,
    this.animation,
  });

  @override
  State<StudentGPAConductScatterChart> createState() => _StudentGPAConductScatterChartState();
}

class _StudentGPAConductScatterChartState extends State<StudentGPAConductScatterChart> {
  List<StudentGPAConductCorrelationResponse>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allData = await TeacherApiService.getStudentGPAConductCorrelation();

      if (!mounted) return;

      // Lọc dữ liệu theo lớp, học kỳ và năm học
      final filteredData = _filterData(allData);

      setState(() {
        _data = filteredData;
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

  String _normalizeHocKy(String hocKy) {
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    if (!hocKy.toUpperCase().startsWith('HK')) {
      final numberMatch = RegExp(r'\d+').firstMatch(hocKy);
      if (numberMatch != null) {
        return 'HK${numberMatch.group(0)}';
      }
    }
    return hocKy.toUpperCase();
  }

  String _normalizeNamHoc(String namHoc) {
    return namHoc.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _extractNamHoc() {
    final parts = widget.semester.hocKy.split('-');
    if (parts.length >= 3) {
      for (int i = 0; i < parts.length - 1; i++) {
        final year1 = int.tryParse(parts[i].trim());
        final year2 = int.tryParse(parts[i + 1].trim());
        if (year1 != null && year2 != null && year2 == year1 + 1) {
          return '$year1 - $year2';
        }
      }
    }
    return '${widget.semester.namHoc} - ${widget.semester.namHoc + 1}';
  }

  String _extractHocKy() {
    return 'HK${widget.semester.hocKySo}';
  }

  List<StudentGPAConductCorrelationResponse> _filterData(
    List<StudentGPAConductCorrelationResponse> allData,
  ) {
    final classNames = widget.classes.map((c) => c.tenLop).toSet();
    final classMaLops = widget.classes.map((c) => c.maLop).toSet();
    final normalizedTargetHocKy = _normalizeHocKy(_extractHocKy());
    final normalizedTargetNamHoc = _normalizeNamHoc(_extractNamHoc());

    return allData.where((item) {
      final matchesClass = classNames.contains(item.tenLop) ||
          classMaLops.contains(item.tenLop) ||
          classNames.any((name) => item.tenLop.trim() == name.trim()) ||
          classMaLops.any((maLop) => item.tenLop.trim() == maLop.trim());

      if (!matchesClass) return false;

      final normalizedItemHocKy = _normalizeHocKy(item.tenHocKy);
      final normalizedItemNamHoc = _normalizeNamHoc(item.tenNamHoc);

      return normalizedItemNamHoc == normalizedTargetNamHoc &&
          normalizedItemHocKy == normalizedTargetHocKy;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.lime.shade600,
              size: 50,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? 'Không thể tải dữ liệu',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_data == null || _data!.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Center(
            child: Text(
              'Chưa có dữ liệu tương quan ĐRL và GPA',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    // Nhóm dữ liệu theo lớp
    final dataByClass = <String, List<StudentGPAConductCorrelationResponse>>{};
    for (var item in _data!) {
      if (!dataByClass.containsKey(item.tenLop)) {
        dataByClass[item.tenLop] = [];
      }
      dataByClass[item.tenLop]!.add(item);
    }

    // Tạo danh sách màu cho các lớp
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
    ];

    // Tạo scatter spots cho mỗi lớp với màu tương ứng
    // Lưu trữ thông tin màu cho mỗi spot
    final classScatterData = <String, List<ScatterSpot>>{};
    final classColors = <String, Color>{};
    final spotColors = <ScatterSpot, Color>{};
    
    final classList = dataByClass.keys.toList();
    for (int i = 0; i < classList.length; i++) {
      final className = classList[i];
      final classData = dataByClass[className]!;
      final color = colors[i % colors.length];
      
      classColors[className] = color;
      final spots = classData.map((item) {
        final spot = ScatterSpot(item.drl, item.gpa);
        spotColors[spot] = color;
        return spot;
      }).toList();
      classScatterData[className] = spots;
    }

    final maxConduct = _data!.map((item) => item.drl).reduce((a, b) => a > b ? a : b);
    final minConduct = _data!.map((item) => item.drl).reduce((a, b) => a < b ? a : b);

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
                        Colors.lime.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.lime.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.lime.withValues(alpha: 0.3),
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
                                    Colors.lime.shade400,
                                    Colors.lime.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.lime.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.scatter_plot,
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
                                'Tương quan điểm rèn luyện và GPA',
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
                        child: Stack(
                          children: [
                            // Chart chính với grid và titles (không có spots)
                            ScatterChart(
                              ScatterChartData(
                                scatterSpots: [],
                                minX: (minConduct * 0.95).clamp(0.0, double.infinity),
                                maxX: (maxConduct * 1.05),
                                minY: 0.0,
                                maxY: 10.0,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  drawHorizontalLine: true,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 45,
                                      interval: 2,
                                      getTitlesWidget: (value, meta) {
                                        // Chỉ hiển thị các giá trị: 0, 2, 4, 6, 8, 10
                                        if (value == 0 || value == 2 || value == 4 || value == 6 || value == 8 || value == 10) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              value.toStringAsFixed(0),
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
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: 10,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
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
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                scatterTouchData: ScatterTouchData(
                                  enabled: false,
                                ),
                              ),
                            ),
                            // Các chấm với màu khác nhau cho từng lớp sử dụng CustomPainter
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Tính toán kích thước thực tế của chart area
                                // Trừ đi reserved space cho titles: left 45, bottom 40
                                final chartWidth = constraints.maxWidth - 45;
                                final chartHeight = constraints.maxHeight - 40;
                                
                                return CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: _MultiColorScatterPainter(
                                    classScatterData: classScatterData,
                                    classColors: classColors,
                                    minX: (minConduct * 0.95).clamp(0.0, double.infinity),
                                    maxX: (maxConduct * 1.05),
                                    minY: 0.0,
                                    maxY: 10.0,
                                    chartWidth: chartWidth,
                                    chartHeight: chartHeight,
                                    leftPadding: 45,
                                    bottomPadding: 40,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Legend cho các lớp
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: classList.asMap().entries.map((entry) {
                            final classIndex = entry.key;
                            final className = entry.value;
                            final color = classColors[className]!;
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  className,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Trục X: Điểm rèn luyện',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            'Trục Y: GPA',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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

