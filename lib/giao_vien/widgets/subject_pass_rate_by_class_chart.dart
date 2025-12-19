import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/class_model.dart';
import '../../services/teacher_api_service.dart';

class SubjectPassRateByClassChart extends StatefulWidget {
  final ClassModel classModel;
  final Animation<double>? animation;

  const SubjectPassRateByClassChart({
    super.key,
    required this.classModel,
    this.animation,
  });

  @override
  State<SubjectPassRateByClassChart> createState() => _SubjectPassRateByClassChartState();
}

class _SubjectPassRateByClassChartState extends State<SubjectPassRateByClassChart> {
  List<SubjectPassRateByClassResponse>? _allData;
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

      final allData = await TeacherApiService.getSubjectPassRateByClass();

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

  List<SubjectPassRateByClassResponse> _getFilteredData() {
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
              color: Colors.blue.shade600,
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
              'Chưa có dữ liệu tỷ lệ qua môn',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    // Sắp xếp theo tên môn học
    filteredData.sort((a, b) => a.tenMonHoc.compareTo(b.tenMonHoc));

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
                        Colors.blue.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.blue.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
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
                                    Colors.blue.shade400,
                                    Colors.blue.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
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
                                'Tỷ lệ sinh viên đậu theo môn',
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
                      
                      // Biểu đồ cột
                      SizedBox(
                        height: 280,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: (filteredData.length * 80.0).clamp(
                                MediaQuery.of(context).size.width - 40,
                                double.infinity),
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 1.0,
                                minY: 0.0,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipPadding: const EdgeInsets.all(12),
                                    tooltipRoundedRadius: 8,
                                    tooltipMargin: 20,
                                    direction: TooltipDirection.top,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final data = filteredData[groupIndex];
                                      return BarTooltipItem(
                                        '${data.tenMonHoc}\nTỷ lệ: ${(data.tiLe_QuaMon * 100).toStringAsFixed(1)}%\nSV qua: ${data.sv_QuaMon}/${data.tong_SV_Mon}',
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
                                      reservedSize: 38,
                                      interval: 0.2,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Text(
                                            '${(value * 100).toInt()}%',
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
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  drawHorizontalLine: true,
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
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: data.tiLe_QuaMon,
                                        width: 30,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                        color: Colors.blue.shade600,
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: 1.0,
                                          color: Colors.grey.shade100,
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

