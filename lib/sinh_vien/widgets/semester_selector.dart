import 'package:flutter/material.dart';
import '../../models/semester.dart';
import '../../models/student_academic.dart';
import '../../services/student_api_service.dart';
import '../../widgets/salomon_tab_bar_wrapper.dart';
import '../semester_detail_screen.dart';

class SemesterSelector extends StatefulWidget {
  final List<Semester> semesters;
  final String? selectedSemester;
  final ValueChanged<String?>? onChanged;
  final StudentAcademic? studentData;
  final Animation<double>? animation;

  const SemesterSelector({
    super.key,
    required this.semesters,
    this.selectedSemester,
    this.onChanged,
    this.studentData,
    this.animation,
  });

  @override
  State<SemesterSelector> createState() => _SemesterSelectorState();
}

class _SemesterSelectorState extends State<SemesterSelector> {
  Map<String, int> _subjectCounts = {}; // Key: "TenNamHoc_TenHocKy", Value: số lượng môn
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectCounts();
  }

  Future<void> _loadSubjectCounts() async {
    try {
      final allSubjectDetails = await StudentApiService.getSubjectDetails();
      
      if (!mounted) return;
      
      // Normalize năm học để so sánh (xử lý cả "2023 - 2024" và "2023-2024")
      String normalizeNamHoc(String namHocStr) {
        return namHocStr.replaceAll(' ', '').trim();
      }
      
      // Tạo map để lưu số lượng môn học cho mỗi học kỳ
      final Map<String, int> counts = {};
      
      for (var semester in widget.semesters) {
        final namHoc = _extractNamHoc(semester);
        final hocKy = _extractHocKy(semester);
        final key = '${namHoc}_${hocKy}';
        final normalizedNamHoc = normalizeNamHoc(namHoc);
        
        // Debug log
        debugPrint('🔍 SemesterSelector - Tìm kiếm số môn học cho:');
        debugPrint('  - Semester: HK${semester.hocKySo} - ${semester.namHoc}-${semester.namHoc + 1}');
        debugPrint('  - Extracted namHoc: $namHoc');
        debugPrint('  - Extracted hocKy: $hocKy');
        debugPrint('  - Normalized namHoc: $normalizedNamHoc');
        
        // Filter theo học kỳ và năm học
        final filtered = allSubjectDetails.where((detail) {
          final normalizedDetailHocKy = _normalizeHocKy(detail.tenHocKy);
          final normalizedHocKy = _normalizeHocKy(hocKy);
          final normalizedDetailNamHoc = normalizeNamHoc(detail.tenNamHoc);
          return normalizedDetailNamHoc == normalizedNamHoc && normalizedDetailHocKy == normalizedHocKy;
        }).toList();
        
        debugPrint('  - Tìm thấy ${filtered.length} môn học');
        if (filtered.isEmpty) {
          debugPrint('  - API data sample:');
          if (allSubjectDetails.isNotEmpty) {
            final sample = allSubjectDetails.first;
            debugPrint('    Sample: ${sample.tenNamHoc} / ${sample.tenHocKy}');
          }
        }
        
        counts[key] = filtered.length;
      }
      
      setState(() {
        _subjectCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('❌ SemesterSelector - Lỗi khi load số môn học: $e');
      
      setState(() {
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

  // Extract năm học từ semester
  String _extractNamHoc(Semester semester) {
    // semester.hocKy có thể là "HK1 - 2024 - 2025" hoặc "2024-2025-1"
    final parts = semester.hocKy.split('-');
    if (parts.length >= 3) {
      // Tìm năm học (2 số liên tiếp)
      for (int i = 0; i < parts.length - 1; i++) {
        final year1 = int.tryParse(parts[i].trim());
        final year2 = int.tryParse(parts[i + 1].trim());
        if (year1 != null && year2 != null && year2 == year1 + 1) {
          return '${year1}-${year2}';
        }
      }
    }
    // Fallback: dùng namHoc từ semester
    return '${semester.namHoc}-${semester.namHoc + 1}';
  }

  // Extract học kỳ từ semester
  String _extractHocKy(Semester semester) {
    return 'HK${semester.hocKySo}';
  }

  // Lấy số lượng môn học cho một semester
  int _getSubjectCount(Semester semester) {
    final namHoc = _extractNamHoc(semester);
    final hocKy = _extractHocKy(semester);
    final key = '${namHoc}_${hocKy}';
    return _subjectCounts[key] ?? semester.subjects.length; // Fallback về dữ liệu từ semester nếu chưa có
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: widget.animation != null
            ? Tween<Offset>(
                begin: const Offset(-0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: widget.animation!,
                curve: Curves.easeOutCubic,
              ))
            : const AlwaysStoppedAnimation(Offset.zero),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            final clampedValue = value.clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.94 + (0.06 * clampedValue),
              child: Opacity(
                opacity: clampedValue,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.rotate(
                            angle: (1 - value) * 0.3,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade100,
                              Colors.blue.shade200,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            final clampedValue = value.clamp(0.0, 1.0);
                            return Opacity(
                              opacity: clampedValue,
                              child: Transform.translate(
                                offset: Offset(10 * (1 - clampedValue), 0),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Danh sách học kỳ',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tổng: ${widget.semesters.length} học kỳ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: widget.semesters.asMap().entries.map((entry) {
                    final index = entry.key;
                    final semester = entry.value;
                    final subjectCount = _getSubjectCount(semester);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < widget.semesters.length - 1 ? 12 : 0,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 80)),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          final clampedValue = value.clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: 0.95 + (0.05 * clampedValue),
                            child: Opacity(
                              opacity: clampedValue,
                              child: child,
                            ),
                          );
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (widget.studentData != null) {
                                final parentContext = context;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (newContext) => wrapWithSalomonTabBar(
                                      parentContext,
                                      SemesterDetailScreen(
                                        studentData: widget.studentData!,
                                        semester: semester,
                                      ),
                                    ),
                                  ),
                                );
                              } else if (widget.onChanged != null) {
                                widget.onChanged!(semester.hocKy);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.blue.shade100.withValues(alpha: 0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.shade200.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.calendar_month,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'HK${semester.hocKySo} - ${semester.namHoc} - ${semester.namHoc + 1}',
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isLoading 
                                            ? 'Đang tải...'
                                            : '$subjectCount môn học',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.blue.shade600,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
