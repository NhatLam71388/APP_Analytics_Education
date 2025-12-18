import 'package:flutter/material.dart';
import '../../models/teacher_advisor.dart';
import '../../models/class_model.dart';
import '../../widgets/salomon_tab_bar_wrapper.dart';
import '../../giao_vien/semester_detail_screen.dart';

class SemesterSelector extends StatelessWidget {
  final TeacherAdvisor teacherData;
  final Animation<double>? animation;

  const SemesterSelector({
    super.key,
    required this.teacherData,
    this.animation,
  });

  // Lấy danh sách tất cả các kỳ từ API Giang-Vien-Co-Van-Lop-Hoc-Theo-Ky
  // Lấy trực tiếp từ teacherData.teacherAdvisorBySemesters
  List<ClassSemesterData> getAllSemesters() {
    if (teacherData.teacherAdvisorBySemesters == null || 
        teacherData.teacherAdvisorBySemesters!.isEmpty) {
      return [];
    }

    // Tạo map để loại bỏ trùng lặp dựa trên "Ten Nam Hoc" và "Ten Hoc Ky"
    final Map<String, ClassSemesterData> semesterMap = {};
    
    for (var advisor in teacherData.teacherAdvisorBySemesters!) {
      // Tạo key unique dựa trên "Ten Nam Hoc" và "Ten Hoc Ky"
      final key = '${advisor.tenNamHoc}-${advisor.tenHocKy}';
      
      if (!semesterMap.containsKey(key)) {
        // Parse "Ten Nam Hoc" để lấy năm học đầu tiên
        // Ví dụ: "2022 - 2023" -> 2022
        final namHocParts = advisor.tenNamHoc.split('-');
        final namHoc = int.tryParse(namHocParts[0].trim()) ?? 2022;
        
        // Normalize tenHocKy để đảm bảo format nhất quán (giống teacher_data_service)
        final normalizedHocKy = _normalizeHocKy(advisor.tenHocKy);
        if (normalizedHocKy.isEmpty) continue; // Bỏ qua nếu học kỳ rỗng
        
        // Parse "Ten Hoc Ky" để lấy số học kỳ
        // Ví dụ: "HK2" -> 2, "HK1" -> 1
        final hocKySo = _extractHocKySo(normalizedHocKy);
        
        // Tạo hocKy string theo format: "HK2-2022-2023" (giống teacher_data_service._createHocKyString)
        final parts = advisor.tenNamHoc.split('-');
        String hocKy;
        if (parts.length >= 2) {
          hocKy = '$normalizedHocKy-${parts[0].trim()}-${parts[1].trim()}';
        } else {
          hocKy = '$normalizedHocKy-${advisor.tenNamHoc.trim()}';
        }
        
        // Lấy GPA trung bình từ API (tính trung bình của tất cả các lớp có cùng Ten Nam Hoc + Ten Hoc Ky)
        final averageGPA = teacherData.getAverageGPABySemester(advisor.tenNamHoc, advisor.tenHocKy) ?? 0.0;
        
        // Tạo ClassSemesterData với giá trị từ API
        // (Các thông tin khác sẽ được load từ các API khác khi vào SemesterDetailScreen)
        semesterMap[key] = ClassSemesterData(
          hocKy: hocKy,
          namHoc: namHoc,
          hocKySo: hocKySo,
          gpa: averageGPA, // GPA trung bình từ API
          passRate: 0.0, // Sẽ được load từ API khác
          academicLevels: {}, // Sẽ được load từ API khác
          subjectGPA: {}, // Sẽ được load từ API khác
          subjectPassRate: {}, // Sẽ được load từ API khác
          totalStudents: null, // Không cần "Fact Hoc Tap Count"
          maleCount: null,
          femaleCount: null,
        );
      }
    }
    
    return semesterMap.values.toList()
      ..sort((a, b) {
        if (a.namHoc != b.namHoc) return a.namHoc.compareTo(b.namHoc);
        return a.hocKySo.compareTo(b.hocKySo);
      });
  }

  // Helper method để normalize học kỳ (giống teacher_data_service._normalizeHocKy)
  String _normalizeHocKy(String hocKy) {
    if (hocKy.isEmpty || hocKy.trim().isEmpty) {
      return '';
    }
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    // Nếu đã là format "HK1", "HK2", etc thì giữ nguyên
    return hocKy;
  }

  // Helper method để extract số học kỳ từ "Ten Hoc Ky"
  // Ví dụ: "HK2" -> 2, "HK1" -> 1, "HK_2" -> 2
  int _extractHocKySo(String tenHocKy) {
    // Normalize trước
    final normalized = _normalizeHocKy(tenHocKy);
    // Loại bỏ "HK" và lấy số
    final cleaned = normalized.replaceAll('HK', '').trim();
    return int.tryParse(cleaned) ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final semesters = getAllSemesters();

    return FadeTransition(
      opacity: animation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: animation != null
            ? Tween<Offset>(
                begin: const Offset(-0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation!,
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
                  Colors.green.shade50.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.15),
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
                              Colors.green.shade100,
                              Colors.green.shade200,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.green.shade700,
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
                          'Tổng: ${semesters.length} học kỳ',
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
                  children: semesters.asMap().entries.map((entry) {
                    final index = entry.key;
                    final semester = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < semesters.length - 1 ? 12 : 0,
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
                              final parentContext = context;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (newContext) => wrapWithSalomonTabBar(
                                    parentContext,
                                    SemesterDetailScreen(
                                      teacherData: teacherData,
                                      semester: semester,
                                    ),
                                  ),
                                ),
                              );
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
                                    Colors.green.shade50,
                                    Colors.green.shade100.withValues(alpha: 0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade200.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.15),
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
                                      color: Colors.green.shade600,
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
                                            color: Colors.green.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'GPA: ${semester.gpa.toStringAsFixed(2)}',
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
                                    color: Colors.green.shade600,
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

