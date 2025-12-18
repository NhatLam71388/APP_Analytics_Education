import 'package:flutter/material.dart';
import '../models/teacher_advisor.dart';
import '../models/class_model.dart';
import '../widgets/salomon_tab_bar_provider.dart';
import 'widgets/gpa_trend_chart.dart';
import 'widgets/gpa_by_semester_year_chart.dart';
import 'widgets/subject_fail_rate_card.dart';
import 'widgets/gpa_comparison_chart.dart';
import 'widgets/academic_level_pie_chart.dart';
import 'widgets/subject_grade_distribution_pie_chart.dart';
import 'widgets/subject_pass_fail_rate_pie_chart.dart';
import 'widgets/subject_gpa_chart.dart';
import 'widgets/overall_gpa_chart.dart';
import '../services/teacher_api_service.dart';
import 'widgets/pass_fail_donut_chart.dart';
import 'widgets/conduct_gpa_scatter_chart.dart';
import 'widgets/gender_pie_chart.dart';
import 'widgets/student_list_widget.dart';

class ClassDetailScreen extends StatefulWidget {
  final TeacherAdvisor teacherData;
  final ClassModel classModel;
  final ClassSemesterData semester;

  const ClassDetailScreen({
    super.key,
    required this.teacherData,
    required this.classModel,
    required this.semester,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animations = List.generate(
      15,
      (index) {
        final start = (index * 0.08).clamp(0.0, 1.0);
        final end = (0.5 + (index * 0.05)).clamp(0.0, 1.0);
        return CurvedAnimation(
          parent: _mainAnimationController,
          curve: Interval(
            start,
            end > start ? end : 1.0,
            curve: Curves.easeOutCubic,
          ),
        );
      },
    );

    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBarProvider = SalomonTabBarProvider.findInAncestors(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.classModel.tenLop,
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 18
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.grey.shade50,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Phân bố giới tính (Tổng số sinh viên, Nam, Nữ) - từ API So-Luong-Sinh-Vien-Nam-Nu-Theo-Lop
                Builder(
                  builder: (context) {
                    // Ưu tiên lấy dữ liệu từ API
                    int maleCount = 0;
                    int femaleCount = 0;
                    int totalStudents = 0;
                    
                    if (widget.teacherData.genderCountByClass != null) {
                      // Debug: In ra các key có sẵn và giá trị cần tìm
                      debugPrint('🔍 Looking for gender data for class:');
                      debugPrint('  - classModel.tenLop: "${widget.classModel.tenLop}"');
                      debugPrint('  - classModel.maLop: "${widget.classModel.maLop}"');
                      debugPrint('  - Available keys in genderCountByClass: ${widget.teacherData.genderCountByClass!.keys.toList()}');
                      
                      // Thử tìm với tenLop
                      var genderCount = widget.teacherData.genderCountByClass![widget.classModel.tenLop];
                      
                      // Nếu không tìm thấy, thử với maLop
                      if (genderCount == null) {
                        genderCount = widget.teacherData.genderCountByClass![widget.classModel.maLop];
                      }
                      
                      // Nếu vẫn không tìm thấy, thử tìm với trim và case insensitive
                      if (genderCount == null && widget.teacherData.genderCountByClass!.isNotEmpty) {
                        final tenLopTrimmed = widget.classModel.tenLop.trim();
                        final maLopTrimmed = widget.classModel.maLop.trim();
                        
                        for (var entry in widget.teacherData.genderCountByClass!.entries) {
                          final keyTrimmed = entry.key.trim();
                          if (keyTrimmed == tenLopTrimmed || keyTrimmed == maLopTrimmed) {
                            genderCount = entry.value;
                            debugPrint('✅ Found match with trimmed key: "$keyTrimmed"');
                            break;
                          }
                        }
                      }
                      
                      if (genderCount != null) {
                        maleCount = genderCount.soNam;
                        femaleCount = genderCount.soNu;
                        totalStudents = maleCount + femaleCount;
                        debugPrint('✅ Using API data: Nam=$maleCount, Nữ=$femaleCount, Tổng=$totalStudents');
                      } else {
                        debugPrint('⚠️ No API data found, will use fallback data');
                      }
                    }
                    
                    // Fallback: dùng dữ liệu từ ClassModel nếu không có từ API
                    if (totalStudents == 0) {
                      final semesterData = widget.classModel.semesterData.firstWhere(
                        (s) => s.hocKy == widget.semester.hocKy,
                        orElse: () => widget.classModel.semesterData.first,
                      );
                      totalStudents = semesterData.totalStudents ?? widget.classModel.totalStudents;
                      maleCount = semesterData.maleCount ?? widget.classModel.maleCount;
                      femaleCount = semesterData.femaleCount ?? widget.classModel.femaleCount;
                    }
                    
                    return GenderPieChart(
                      totalStudents: totalStudents,
                      maleCount: maleCount,
                      femaleCount: femaleCount,
                      animation: _animations[0],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. Danh sách sinh viên
                StudentListWidget(
                  classModel: widget.classModel,
                  semester: widget.semester,
                  animation: _animations[1],
                ),
                const SizedBox(height: 16),

                // 3. GPA toàn khóa (từ API GPA-Trung-Binh-Theo-Lop-Toan-Khoa)
                OverallGPAChart(
                  selectedClass: widget.classModel,
                  animation: _animations[2],
                  teacherData: widget.teacherData,
                ),
                const SizedBox(height: 16),

                // 4. Xu hướng GPA trong lớp đó (từ API Xu-Huong-GPA-Trung-Binh-Theo-Lop)
                GPATrendChart(
                  classes: [widget.classModel],
                  gpaTrendByClass: widget.teacherData.gpaTrendByClass,
                  animation: _animations[3],
                ),
                const SizedBox(height: 16),

                // 5. GPA trung bình các môn (từ API GPA-Trung-Binh-Theo-Lop-Mon-Hoc-Hoc-Ky-Nam-Hoc)
                SubjectGPAChart(
                  selectedClass: widget.classModel,
                  animation: _animations[4],
                  teacherData: widget.teacherData,
                ),
                const SizedBox(height: 16),

                // 6. GPA theo học kỳ năm học (từ API GPA-Trung-Binh-Theo-Lop-Mon-Hoc-Hoc-Ky-Nam-Hoc)
                GPABySemesterYearChart(
                  selectedClass: widget.classModel,
                  animation: _animations[5],
                  teacherData: widget.teacherData,
                ),
                const SizedBox(height: 16),

                // 7. Tương quan điểm rèn luyện và GPA trong lớp đó
                // ConductGPAScatterChart(
                //   classes: [widget.classModel],
                //   animation: _animations[5],
                // ),
                // const SizedBox(height: 16),

                // 8. Môn học rớt nhiều nhất (theo lớp)
                SubjectFailRateCard(
                  title: 'Môn học rớt nhiều nhất',
                  subjectName: _getMostFrequentSubjectByClassHigh(
                    widget.teacherData.subjectFailRateHighs,
                    widget.classModel,
                  ),
                  icon: Icons.trending_down,
                  color: Colors.red,
                  animation: _animations[6],
                ),
                const SizedBox(height: 12),

                // 8b. Môn học rớt thấp nhất (theo lớp)
                SubjectFailRateCard(
                  title: 'Môn học rớt thấp nhất',
                  subjectName: _getMostFrequentSubjectByClassLow(
                    widget.teacherData.subjectFailRateLows,
                    widget.classModel,
                  ),
                  icon: Icons.trending_up,
                  color: Colors.green,
                  animation: _animations[7],
                ),
                const SizedBox(height: 16),

                // 9. Điểm trung bình môn so với GPA toàn khóa (từ API Diem-Trung-Binh-Mon-So-Voi-GPA-Toan-Khoa)
                GPAComparisonChart(
                  selectedClass: widget.classModel,
                  animation: _animations[8],
                  teacherData: widget.teacherData,
                ),
                const SizedBox(height: 16),

                // 10. Tỷ lệ phần trăm học lực theo lớp học kỳ (từ API Ty-Le-Phan-Tram-Hoc-Luc-Theo-Lop-Hoc-Ky)
                AcademicLevelPieChart(
                  selectedClass: widget.classModel,
                  animation: _animations[9],
                  teacherData: widget.teacherData,
                ),
                const SizedBox(height: 16),

                // 11. Tỷ lệ phần trăm xếp loại theo môn (từ API Ty-Le-Phan-Tram-Loai-Theo-Mon-Hoc-Lop)
                SubjectGradeDistributionPieChart(
                  selectedClass: widget.classModel,
                  animation: _animations[10],
                  teacherData: widget.teacherData,
                ),
                const SizedBox(height: 16),

                // 12. Tỷ lệ phần trăm qua/rớt môn (từ API Ty-Le-Phan-Tram-Qua-Rot-Mon-Theo-Lop-Hoc-Ky-Nam-Hoc)
                SubjectPassFailRatePieChart(
                  selectedClass: widget.classModel,
                  animation: _animations[11],
                  teacherData: widget.teacherData,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: tabBarProvider != null
          ? tabBarProvider.buildSalomonBottomBar(context)
          : null,
    );
  }

  // Helper method để tìm môn học xuất hiện nhiều nhất trong danh sách (lọc theo lớp) - High
  String _getMostFrequentSubjectByClassHigh(
    List<SubjectFailRateHighResponse>? subjectList,
    ClassModel classModel,
  ) {
    if (subjectList == null || subjectList.isEmpty) {
      return '';
    }

    // Lọc theo lớp (thử cả tenLop và maLop)
    final filteredSubjects = <String>[];
    for (var item in subjectList) {
      if (item.tenLop == classModel.tenLop || 
          item.tenLop == classModel.maLop ||
          item.tenLop.trim() == classModel.tenLop.trim() ||
          item.tenLop.trim() == classModel.maLop.trim()) {
        if (item.tenMonHoc.isNotEmpty) {
          filteredSubjects.add(item.tenMonHoc);
        }
      }
    }

    if (filteredSubjects.isEmpty) {
      return '';
    }

    // Đếm tần suất xuất hiện của mỗi môn học
    final frequencyMap = <String, int>{};
    for (var subject in filteredSubjects) {
      frequencyMap[subject] = (frequencyMap[subject] ?? 0) + 1;
    }

    // Tìm môn học xuất hiện nhiều nhất
    String? mostFrequentSubject;
    int maxCount = 0;
    frequencyMap.forEach((subject, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentSubject = subject;
      }
    });

    return mostFrequentSubject ?? '';
  }

  // Helper method để tìm môn học xuất hiện nhiều nhất trong danh sách (lọc theo lớp) - Low
  String _getMostFrequentSubjectByClassLow(
    List<SubjectFailRateLowResponse>? subjectList,
    ClassModel classModel,
  ) {
    if (subjectList == null || subjectList.isEmpty) {
      return '';
    }

    // Lọc theo lớp (thử cả tenLop và maLop)
    final filteredSubjects = <String>[];
    for (var item in subjectList) {
      if (item.tenLop == classModel.tenLop || 
          item.tenLop == classModel.maLop ||
          item.tenLop.trim() == classModel.tenLop.trim() ||
          item.tenLop.trim() == classModel.maLop.trim()) {
        if (item.tenMonHoc.isNotEmpty) {
          filteredSubjects.add(item.tenMonHoc);
        }
      }
    }

    if (filteredSubjects.isEmpty) {
      return '';
    }

    // Đếm tần suất xuất hiện của mỗi môn học
    final frequencyMap = <String, int>{};
    for (var subject in filteredSubjects) {
      frequencyMap[subject] = (frequencyMap[subject] ?? 0) + 1;
    }

    // Tìm môn học xuất hiện nhiều nhất
    String? mostFrequentSubject;
    int maxCount = 0;
    frequencyMap.forEach((subject, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentSubject = subject;
      }
    });

    return mostFrequentSubject ?? '';
  }
}

