import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/class_model.dart';
import '../../models/teacher_advisor.dart';
import '../../services/teacher_api_service.dart';

class PassFailDonutChart extends StatelessWidget {
  final List<ClassModel> classes;
  final ClassSemesterData semester;
  final TeacherAdvisor? teacherData;
  final Animation<double>? animation;

  const PassFailDonutChart({
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

  // Extract năm học và học kỳ từ semester (sử dụng trực tiếp từ ClassSemesterData)
  // Format: semester.namHoc = 2022, semester.hocKySo = 1 -> Ten Nam Hoc: "2022 - 2023", Ten Hoc Ky: "HK1"
  String? _extractTenNamHoc() {
    // Sử dụng trực tiếp từ semester.namHoc thay vì parse từ semester.hocKy
    final result = '${semester.namHoc} - ${semester.namHoc + 1}';
    debugPrint('🔍 _extractTenNamHoc: Using semester.namHoc = ${semester.namHoc}');
    debugPrint('   - Result: "$result"');
    return result;
  }

  String? _extractTenHocKy() {
    // Sử dụng trực tiếp từ semester.hocKySo thay vì parse từ semester.hocKy
    final result = 'HK${semester.hocKySo}';
    debugPrint('🔍 _extractTenHocKy: Using semester.hocKySo = ${semester.hocKySo}');
    debugPrint('   - Result: "$result"');
    return result;
  }

  // Lấy và tính tổng dữ liệu từ API Ty-Le-Phan-Tram-Qua-Rot-Mon-Theo-Lop-Hoc-Ky-Nam-Hoc-mobi
  Map<String, int> _getPassFailData() {
    // Debug: Kiểm tra dữ liệu
    if (teacherData?.classPassFailRates == null) {
      debugPrint('⚠️ PassFailDonutChart: classPassFailRates is null');
      return {'soDau': 0, 'soRot': 0, 'tongLuot': 0};
    }
    
    if (teacherData!.classPassFailRates!.isEmpty) {
      debugPrint('⚠️ PassFailDonutChart: classPassFailRates is empty');
      return {'soDau': 0, 'soRot': 0, 'tongLuot': 0};
    }

    final tenNamHoc = _extractTenNamHoc();
    final tenHocKy = _extractTenHocKy();
    if (tenNamHoc == null || tenHocKy == null) {
      debugPrint('⚠️ PassFailDonutChart: Cannot extract tenNamHoc or tenHocKy from semester.hocKy: ${semester.hocKy}');
      return {'soDau': 0, 'soRot': 0, 'tongLuot': 0};
    }

    final normalizedHocKy = _normalizeHocKy(tenHocKy);
    
    // Debug
    debugPrint('🔍 PassFailDonutChart: Looking for data with:');
    debugPrint('   - tenNamHoc: "$tenNamHoc"');
    debugPrint('   - tenHocKy: "$tenHocKy" (normalized: "$normalizedHocKy")');
    debugPrint('   - Total items in classPassFailRates: ${teacherData!.classPassFailRates!.length}');
    
    // Lấy danh sách tên lớp trong kỳ
    final classNames = classes.map((c) => c.tenLop).toSet();
    final classMaLops = classes.map((c) => c.maLop).toSet();
    
    debugPrint('   - Classes in semester: ${classNames.toList()}');
    debugPrint('   - Class maLops: ${classMaLops.toList()}');

    // Debug: In ra một vài item đầu tiên để kiểm tra format
    if (teacherData!.classPassFailRates!.isNotEmpty) {
      final firstItem = teacherData!.classPassFailRates!.first;
      debugPrint('   - Sample item from API:');
      debugPrint('     * tenLop: "${firstItem.tenLop}"');
      debugPrint('     * tenNamHoc: "${firstItem.tenNamHoc}"');
      debugPrint('     * tenHocKy: "${firstItem.tenHocKy}"');
    }

    // Helper function để normalize Ten Nam Hoc (loại bỏ dấu cách thừa)
    String normalizeNamHoc(String namHoc) {
      // Loại bỏ dấu cách thừa, giữ lại format "2022 - 2023"
      return namHoc.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(' - ', '-').replaceAll('-', ' - ');
    }
    
    // Lọc dữ liệu theo Ten Nam Hoc, Ten Hoc Ky và các lớp trong kỳ
    final filteredData = teacherData!.classPassFailRates!.where((item) {
      final normalizedItemHocKy = _normalizeHocKy(item.tenHocKy);
      
      // So sánh Ten Nam Hoc - normalize cả hai để đảm bảo khớp
      final normalizedItemNamHoc = normalizeNamHoc(item.tenNamHoc);
      final normalizedTargetNamHoc = normalizeNamHoc(tenNamHoc);
      final isMatchingNamHoc = normalizedItemNamHoc == normalizedTargetNamHoc;
      
      final isMatchingHocKy = normalizedItemHocKy == normalizedHocKy;
      final isMatchingSemester = isMatchingNamHoc && isMatchingHocKy;
      
      if (!isMatchingSemester) {
        debugPrint('   ❌ Item "${item.tenLop}" không match:');
        debugPrint('      - tenNamHoc: "${item.tenNamHoc}" (normalized: "$normalizedItemNamHoc") vs "$normalizedTargetNamHoc" -> $isMatchingNamHoc');
        debugPrint('      - tenHocKy: "${item.tenHocKy}" (normalized: "$normalizedItemHocKy") vs "$normalizedHocKy" -> $isMatchingHocKy');
        return false;
      }

      // Kiểm tra xem lớp có trong danh sách classes không
      final itemTenLop = item.tenLop.trim();
      final isMatchingClass = classNames.contains(itemTenLop) ||
             classMaLops.contains(itemTenLop) ||
             classNames.any((cn) => cn.trim() == itemTenLop) ||
             classMaLops.any((cm) => cm.trim() == itemTenLop);

      if (isMatchingClass) {
        debugPrint('   ✅ Item "${item.tenLop}" matched!');
      }

      return isMatchingClass;
    }).toList();

    debugPrint('   - Filtered data count: ${filteredData.length}');
    if (filteredData.isNotEmpty) {
      debugPrint('   - Sample filtered item:');
      debugPrint('     * tenLop: "${filteredData.first.tenLop}"');
      debugPrint('     * soDau: ${filteredData.first.soDau}');
      debugPrint('     * soRot: ${filteredData.first.soRot}');
    }

    // Tính tổng So_Dau và So_Rot
    int totalSoDau = 0;
    int totalSoRot = 0;
    int totalTongLuot = 0;

    for (var item in filteredData) {
      totalSoDau += item.soDau ?? 0;
      totalSoRot += item.soRot ?? 0;
      totalTongLuot += item.tongLuot;
    }

    debugPrint('✅ PassFailDonutChart: Total - soDau: $totalSoDau, soRot: $totalSoRot, tongLuot: $totalTongLuot');

    return {
      'soDau': totalSoDau,
      'soRot': totalSoRot,
      'tongLuot': totalTongLuot,
    };
  }

  @override
  Widget build(BuildContext context) {
    final passFailData = _getPassFailData();
    final soSVDau = passFailData['soDau'] ?? 0;
    final soSVRot = passFailData['soRot'] ?? 0;
    final tongLuot = passFailData['tongLuot'] ?? 0;
    
    // Tính tỷ lệ phần trăm
    double passRate = 0.0;
    double failRate = 0.0;
    
    if (tongLuot > 0) {
      passRate = (soSVDau / tongLuot) * 100;
      failRate = (soSVRot / tongLuot) * 100;
    }

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
                                Icons.donut_large,
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
                              child: Text(
                                'Tỷ lệ đậu/rớt',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final clampedValue = value.clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: 0.8 + (0.2 * clampedValue),
                            child: Opacity(
                              opacity: clampedValue,
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  value: passRate,
                                  title: '${passRate.toStringAsFixed(1)}%',
                                  color: Colors.green.shade600,
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: failRate,
                                  title: '${failRate.toStringAsFixed(1)}%',
                                  color: Colors.red.shade600,
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: _buildLegendItem(Colors.green, 'Đậu', soSVDau),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Center(
                              child: _buildLegendItem(Colors.red, 'Rớt', soSVRot),
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

  Widget _buildLegendItem(Color color, String label, int count) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        final clampedValue = animValue.clamp(0.0, 1.0);
        return Opacity(
          opacity: clampedValue,
          child: Transform.translate(
            offset: Offset(20 * (1 - clampedValue), 0),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count SV',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color is MaterialColor ? color.shade700 : color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

