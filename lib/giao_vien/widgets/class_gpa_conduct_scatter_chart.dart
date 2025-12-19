import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/class_model.dart';
import '../../services/teacher_api_service.dart';

// Custom painter để vẽ các chấm với 1 màu duy nhất
class _SingleColorScatterPainter extends CustomPainter {
  final List<ScatterSpot> scatterSpots;
  final Color color;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double chartWidth;
  final double chartHeight;
  final double leftPadding;
  final double bottomPadding;

  _SingleColorScatterPainter({
    required this.scatterSpots,
    required this.color,
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
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final spot in scatterSpots) {
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

  @override
  bool shouldRepaint(covariant _SingleColorScatterPainter oldDelegate) {
    return oldDelegate.scatterSpots != scatterSpots || 
           oldDelegate.color != color;
  }
}

class ClassGPAConductScatterChart extends StatefulWidget {
  final ClassModel classModel;
  final Animation<double>? animation;

  const ClassGPAConductScatterChart({
    super.key,
    required this.classModel,
    this.animation,
  });

  @override
  State<ClassGPAConductScatterChart> createState() => _ClassGPAConductScatterChartState();
}

class _ClassGPAConductScatterChartState extends State<ClassGPAConductScatterChart> {
  List<StudentGPAConductCorrelationResponse>? _allData;
  bool _isLoading = true;
  String? _errorMessage;
  
  String? _selectedNamHoc;
  String? _selectedHocKy;
  List<String> _availableNamHoc = [];
  List<String> _availableHocKy = [];

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

      // Lọc dữ liệu chỉ theo lớp (không lọc theo năm học/kỳ)
      final filteredData = allData.where((item) {
        final matchesClass = item.tenLop == widget.classModel.tenLop ||
            item.tenLop == widget.classModel.maLop ||
            item.tenLop.trim() == widget.classModel.tenLop.trim() ||
            item.tenLop.trim() == widget.classModel.maLop.trim();
        return matchesClass;
      }).toList();

      // Lấy danh sách năm học và học kỳ có sẵn
      final namHocSet = <String>{};
      final hocKySet = <String>{};
      
      for (var item in filteredData) {
        namHocSet.add(item.tenNamHoc);
        hocKySet.add(item.tenHocKy);
      }
      
      _availableNamHoc = ['Tất cả', ...namHocSet.toList()..sort()];
      _availableHocKy = ['Tất cả', ...hocKySet.toList()..sort()];

      setState(() {
        _allData = filteredData;
        _selectedNamHoc = _availableNamHoc.isNotEmpty ? _availableNamHoc.first : null;
        _selectedHocKy = _availableHocKy.isNotEmpty ? _availableHocKy.first : null;
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

  List<StudentGPAConductCorrelationResponse> _getFilteredData() {
    if (_allData == null) return [];
    
    if ((_selectedNamHoc == null || _selectedNamHoc == 'Tất cả') &&
        (_selectedHocKy == null || _selectedHocKy == 'Tất cả')) {
      return _allData!;
    }

    return _allData!.where((item) {
      final matchesNamHoc = _selectedNamHoc == null || 
          _selectedNamHoc == 'Tất cả' ||
          _normalizeNamHoc(item.tenNamHoc) == _normalizeNamHoc(_selectedNamHoc!);
      
      final matchesHocKy = _selectedHocKy == null || 
          _selectedHocKy == 'Tất cả' ||
          _normalizeHocKy(item.tenHocKy) == _normalizeHocKy(_selectedHocKy!);
      
      return matchesNamHoc && matchesHocKy;
    }).toList();
  }

  List<String> _getAvailableHocKyForNamHoc(String? namHoc) {
    if (_allData == null || namHoc == null || namHoc == 'Tất cả') {
      return _availableHocKy;
    }
    
    final hocKySet = <String>{};
    for (var item in _allData!) {
      if (_normalizeNamHoc(item.tenNamHoc) == _normalizeNamHoc(namHoc)) {
        hocKySet.add(item.tenHocKy);
      }
    }
    
    return ['Tất cả', ...hocKySet.toList()..sort()];
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
              color: Colors.green.shade600,
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

    final filteredData = _getFilteredData();

    if (filteredData.isEmpty) {
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

    // Tạo scatter spots với 1 màu duy nhất
    final scatterSpots = filteredData.map((item) {
      return ScatterSpot(item.drl, item.gpa);
    }).toList();

    final maxConduct = filteredData.map((item) => item.drl).reduce((a, b) => a > b ? a : b);
    final minConduct = filteredData.map((item) => item.drl).reduce((a, b) => a < b ? a : b);
    final maxGPA = filteredData.map((item) => item.gpa).reduce((a, b) => a > b ? a : b);
    final minGPA = filteredData.map((item) => item.gpa).reduce((a, b) => a < b ? a : b);

    // Màu duy nhất cho tất cả các điểm
    final singleColor = Colors.green.shade600;

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
                        Colors.green.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.green.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
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
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.4),
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
                      
                      // Combobox để chọn năm học và học kỳ
                      if (_availableNamHoc.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedNamHoc,
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
                                items: _availableNamHoc.map((namHoc) {
                                  return DropdownMenuItem(
                                    value: namHoc,
                                    child: Text(namHoc),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && mounted) {
                                    setState(() {
                                      _selectedNamHoc = value;
                                      // Reset học kỳ khi đổi năm học
                                      final newHocKy = _getAvailableHocKyForNamHoc(value);
                                      _selectedHocKy = newHocKy.isNotEmpty ? newHocKy.first : null;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedHocKy,
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
                                items: _getAvailableHocKyForNamHoc(_selectedNamHoc).map((hocKy) {
                                  return DropdownMenuItem(
                                    value: hocKy,
                                    child: Text(hocKy),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null && mounted) {
                                    setState(() {
                                      _selectedHocKy = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      if (_availableNamHoc.isNotEmpty) const SizedBox(height: 20),
                      
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
                            // CustomPainter để vẽ các chấm với 1 màu duy nhất
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Tính toán kích thước thực tế của chart area
                                // Trừ đi reserved space cho titles: left 45, bottom 40
                                final chartWidth = constraints.maxWidth - 45;
                                final chartHeight = constraints.maxHeight - 40;
                                
                                return CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: _SingleColorScatterPainter(
                                    scatterSpots: scatterSpots,
                                    color: singleColor,
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
