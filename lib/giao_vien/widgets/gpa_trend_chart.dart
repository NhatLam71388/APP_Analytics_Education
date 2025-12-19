import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/class_model.dart';
import '../../services/teacher_api_service.dart';

class GPATrendChart extends StatefulWidget {
  final List<ClassModel> classes;
  final Animation<double>? animation;

  const GPATrendChart({
    super.key,
    required this.classes,
    this.animation,
  });

  @override
  State<GPATrendChart> createState() => _GPATrendChartState();
}

class _GPATrendChartState extends State<GPATrendChart> {
  List<ClassSemesterGPAResponse>? _gpaData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGPAData();
  }

  Future<void> _loadGPAData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allData = await TeacherApiService.getClassGPABySemesterAndYear();

      if (!mounted) return;

      // Lọc dữ liệu theo các lớp được chọn
      final filteredData = allData.where((item) {
        return widget.classes.any((classModel) {
          return item.tenLop == classModel.tenLop ||
                 item.tenLop == classModel.maLop ||
                 item.tenLop.trim() == classModel.tenLop.trim() ||
                 item.tenLop.trim() == classModel.maLop.trim();
        });
      }).toList();

      setState(() {
        _gpaData = filteredData;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null || _gpaData == null || _gpaData!.isEmpty) {
      return _buildErrorWidget();
    }

    // Sắp xếp dữ liệu theo năm học và học kỳ
    final sortedData = List<ClassSemesterGPAResponse>.from(_gpaData!)
      ..sort((a, b) {
        final yearCompare = a.tenNamHoc.compareTo(b.tenNamHoc);
        if (yearCompare != 0) return yearCompare;
        return a.maHocKy.compareTo(b.maHocKy);
      });

    // Nhóm dữ liệu theo lớp
    final dataByClass = <String, List<ClassSemesterGPAResponse>>{};
    for (var item in sortedData) {
      if (!dataByClass.containsKey(item.tenLop)) {
        dataByClass[item.tenLop] = [];
      }
      dataByClass[item.tenLop]!.add(item);
    }

    // Tạo danh sách các điểm dữ liệu (semesters) với cả năm học và học kỳ
    final allSemesters = <String>{};
    for (var item in sortedData) {
      allSemesters.add('${item.tenNamHoc}|${item.maHocKy}');
    }
    final sortedSemesters = allSemesters.toList()
      ..sort((a, b) {
        final partsA = a.split('|');
        final partsB = b.split('|');
        final yearCompare = partsA[0].compareTo(partsB[0]);
        if (yearCompare != 0) return yearCompare;
        return partsA[1].compareTo(partsB[1]);
      });

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
                            width: (sortedSemesters.length * 80.0 + widget.classes.length * 20.0).clamp(300.0, double.infinity).toDouble(),
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
                                      interval: 2,
                                      getTitlesWidget: (value, meta) {
                                        // Chỉ hiển thị các giá trị: 0, 2, 4, 6, 8, 10
                                        if (value == 0 || value == 2 || value == 4 || value == 6 || value == 8 || value == 10) {
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
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 100,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() < sortedSemesters.length) {
                                          final semesterKey = sortedSemesters[value.toInt()];
                                          final parts = semesterKey.split('|');
                                          final namHoc = parts[0];
                                          final hocKy = parts[1];
                                          
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: RotatedBox(
                                              quarterTurns: -45,
                                              child: Text(
                                                '$namHoc\n$hocKy',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                lineBarsData: widget.classes.asMap().entries.map((entry) {
                                  final colors = [
                                    Colors.teal.shade600,
                                    Colors.blue.shade600,
                                    Colors.purple.shade600,
                                    Colors.orange.shade600,
                                  ];
                                  final color = colors[entry.key % colors.length];
                                  
                                  // Tìm dữ liệu từ API cho lớp này
                                  final classData = dataByClass[entry.value.tenLop] ?? 
                                                   dataByClass[entry.value.maLop] ??
                                                   [];
                                  
                                  final spots = sortedSemesters.asMap().entries.map((semesterEntry) {
                                    final semesterKey = semesterEntry.value;
                                    final parts = semesterKey.split('|');
                                    final namHoc = parts[0];
                                    final hocKy = parts[1];
                                    
                                    // Tìm dữ liệu GPA cho semester này
                                    final gpaItem = classData.firstWhere(
                                      (item) => item.tenNamHoc == namHoc && item.maHocKy == hocKy,
                                      orElse: () => ClassSemesterGPAResponse(
                                        tenLop: entry.value.tenLop,
                                        tenNamHoc: namHoc,
                                        maHocKy: hocKy,
                                        gpa: 0.0,
                                      ),
                                    );
                                    
                                    return FlSpot(semesterEntry.key.toDouble(), gpaItem.gpa);
                                  }).toList();

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
                                minY: 0.0,
                                maxY: 10.0,
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (touchedSpot) => Colors.white,
                                    tooltipRoundedRadius: 8,
                                    tooltipPadding: const EdgeInsets.all(12),
                                    tooltipMargin: 8,
                                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                      return touchedSpots.map((LineBarSpot touchedSpot) {
                                        final index = touchedSpot.x.toInt();
                                        if (index < sortedSemesters.length) {
                                          final semesterKey = sortedSemesters[index];
                                          final parts = semesterKey.split('|');
                                          final namHoc = parts[0];
                                          final hocKy = parts[1];
                                          
                                          // Tìm lớp tương ứng
                                          final classIndex = touchedSpot.barIndex;
                                          if (classIndex < widget.classes.length) {
                                            final classModel = widget.classes[classIndex];
                                            final classData = dataByClass[classModel.tenLop] ?? 
                                                             dataByClass[classModel.maLop] ??
                                                             [];
                                            final gpaItem = classData.firstWhere(
                                              (item) => item.tenNamHoc == namHoc && item.maHocKy == hocKy,
                                              orElse: () => ClassSemesterGPAResponse(
                                                tenLop: classModel.tenLop,
                                                tenNamHoc: namHoc,
                                                maHocKy: hocKy,
                                                gpa: 0.0,
                                              ),
                                            );
                                            
                                            return LineTooltipItem(
                                              '$namHoc\n$hocKy\nGPA: ${gpaItem.gpa.toStringAsFixed(2)}',
                                              const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            );
                                          }
                                        }
                                        return LineTooltipItem(
                                          'GPA: ${touchedSpot.y.toStringAsFixed(2)}',
                                          const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        );
                                      }).toList();
                                    },
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

  Widget _buildLoadingWidget() {
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
            color: Colors.teal.shade600,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
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
                _errorMessage ?? 'Không thể tải dữ liệu xu hướng GPA.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadGPAData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



