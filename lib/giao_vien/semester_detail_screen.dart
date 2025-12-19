import 'package:flutter/material.dart';
import '../models/teacher_advisor.dart';
import '../models/class_model.dart';
import '../widgets/salomon_tab_bar_provider.dart';
import '../widgets/salomon_tab_bar_wrapper.dart';
import 'class_detail_screen.dart';
import 'widgets/students_count_chart.dart';
import 'widgets/gender_chart.dart';
import 'widgets/pass_fail_donut_chart.dart';
import 'widgets/conduct_gpa_scatter_chart.dart';
import 'widgets/student_gpa_conduct_scatter_chart.dart';
import 'widgets/gender_pie_chart.dart';
import 'widgets/subject_fail_rate_card.dart';
import 'widgets/class_overall_gpa_chart.dart';
import 'widgets/subject_gpa_by_semester_chart.dart';
import 'widgets/pass_fail_rate_by_semester_chart.dart';
import 'widgets/class_list_widget.dart';
import 'widgets/subject_pass_rate_chart.dart';
import '../services/teacher_api_service.dart';

class SemesterDetailScreen extends StatefulWidget {
  final TeacherAdvisor teacherData;
  final ClassSemesterData semester;

  const SemesterDetailScreen({
    super.key,
    required this.teacherData,
    required this.semester,
  });

  @override
  State<SemesterDetailScreen> createState() => _SemesterDetailScreenState();
}

class _SemesterDetailScreenState extends State<SemesterDetailScreen>
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
      16, // Tăng lên 16 để có đủ cho widget tỷ lệ sinh viên đậu theo môn
      (index) => CurvedAnimation(
        parent: _mainAnimationController,
        curve: Interval(
          (index * 0.07).clamp(0.0, 1.0),
          (0.6 + (index * 0.03)).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    super.dispose();
  }

  // Lấy danh sách các lớp có dữ liệu trong kỳ này
  List<ClassModel> getClassesInSemester() {
    // Normalize hocKy từ semester để so sánh
    final targetHocKy = widget.semester.hocKy;
    final targetParts = targetHocKy.split('-');
    if (targetParts.length < 3) {
      return [];
    }
    final targetHocKySo = targetParts[0]; // "HK2"
    final targetNamHoc = '${targetParts[1]}-${targetParts[2]}'; // "2022-2023"
    
    // Tìm các lớp có semesterData match với học kỳ này
    var matchedClasses = widget.teacherData.classes.where((classItem) {
      return classItem.semesterData.any((s) {
        // So sánh trực tiếp
        if (s.hocKy == targetHocKy) return true;
        
        // So sánh bằng cách parse và so sánh từng phần
        final sParts = s.hocKy.split('-');
        if (sParts.length < 3) return false;
        final sHocKySo = sParts[0];
        final sNamHoc = '${sParts[1]}-${sParts[2]}';
        
        // Normalize năm học (loại bỏ khoảng trắng)
        final normalizedTargetNamHoc = targetNamHoc.replaceAll(' ', '');
        final normalizedSNamHoc = sNamHoc.replaceAll(' ', '');
        
        return sHocKySo == targetHocKySo && normalizedSNamHoc == normalizedTargetNamHoc;
      });
    }).toList();
    
    // Nếu không tìm thấy, thử tìm từ teacherAdvisorBySemesters
    if (matchedClasses.isEmpty && widget.teacherData.teacherAdvisorBySemesters != null) {
      final normalizedTargetNamHoc = targetNamHoc.replaceAll(' ', '');
      final classNamesFromAdvisor = widget.teacherData.teacherAdvisorBySemesters!
          .where((advisor) {
            final normalizedAdvisorNamHoc = advisor.tenNamHoc.replaceAll(' ', '');
            // Normalize hocKy để so sánh
            String normalizedAdvisorHocKy = advisor.tenHocKy;
            if (advisor.tenHocKy.contains('_')) {
              final parts = advisor.tenHocKy.split('_');
              if (parts.length > 1) {
                normalizedAdvisorHocKy = 'HK${parts[1]}';
              }
            }
            return normalizedAdvisorNamHoc == normalizedTargetNamHoc && 
                   normalizedAdvisorHocKy == targetHocKySo;
          })
          .map((advisor) => advisor.tenLop)
          .toSet();
      
      // Lấy các lớp từ classNames
      matchedClasses = widget.teacherData.classes
          .where((classItem) => classNamesFromAdvisor.contains(classItem.tenLop))
          .toList();
    }
    
    return matchedClasses;
  }

  // Tính tổng số sinh viên trong kỳ (từ dữ liệu kỳ của từng lớp)
  int getTotalStudentsInSemester() {
    return getClassesInSemester().fold(0, (sum, classItem) {
      final semesterData = classItem.semesterData.firstWhere(
        (s) => s.hocKy == widget.semester.hocKy,
        orElse: () => classItem.semesterData.first,
      );
      return sum + (semesterData.totalStudents ?? classItem.totalStudents);
    });
  }

  // Tính tổng số sinh viên nam/nữ trong kỳ từ API So-Luong-Sinh-Vien-Nam-Nu-Theo-Lop
  int getMaleCountInSemester() {
    final classesInSemester = getClassesInSemester();
    final classNames = classesInSemester.map((c) => c.tenLop).toList();
    
    // Ưu tiên lấy từ API
    if (widget.teacherData.genderCountByClass != null) {
      final totalFromAPI = widget.teacherData.getTotalMaleFromAPI(classNames);
      if (totalFromAPI > 0) {
        return totalFromAPI;
      }
    }
    
    // Fallback: tính từ dữ liệu kỳ của từng lớp
    return classesInSemester.fold(0, (sum, classItem) {
      final semesterData = classItem.semesterData.firstWhere(
        (s) => s.hocKy == widget.semester.hocKy,
        orElse: () => classItem.semesterData.first,
      );
      return sum + (semesterData.maleCount ?? classItem.maleCount);
    });
  }

  int getFemaleCountInSemester() {
    final classesInSemester = getClassesInSemester();
    final classNames = classesInSemester.map((c) => c.tenLop).toList();
    
    // Ưu tiên lấy từ API
    if (widget.teacherData.genderCountByClass != null) {
      final totalFromAPI = widget.teacherData.getTotalFemaleFromAPI(classNames);
      if (totalFromAPI > 0) {
        return totalFromAPI;
      }
    }
    
    // Fallback: tính từ dữ liệu kỳ của từng lớp
    return classesInSemester.fold(0, (sum, classItem) {
      final semesterData = classItem.semesterData.firstWhere(
        (s) => s.hocKy == widget.semester.hocKy,
        orElse: () => classItem.semesterData.first,
      );
      return sum + (semesterData.femaleCount ?? classItem.femaleCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesInSemester = getClassesInSemester();
    final totalStudents = getTotalStudentsInSemester();
    final maleCount = getMaleCountInSemester();
    final femaleCount = getFemaleCountInSemester();
    final tabBarProvider = SalomonTabBarProvider.findInAncestors(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'HK${widget.semester.hocKySo} - ${widget.semester.namHoc} - ${widget.semester.namHoc + 1}',
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
                // 1. Phân bố giới tính (pie chart)
                GenderPieChart(
                  totalStudents: totalStudents,
                  maleCount: maleCount,
                  femaleCount: femaleCount,
                  animation: _animations[0],
                ),
                const SizedBox(height: 16),

                // 2. Tỷ lệ sinh viên đậu theo từng môn
                SubjectPassRateChart(
                  classes: classesInSemester,
                  semester: widget.semester,
                  maleCount: maleCount,
                  femaleCount: femaleCount,
                  animation: _animations[1],
                ),
                const SizedBox(height: 16),

                // 3. Danh sách các lớp trong kỳ
                ClassListWidget(
                  classes: classesInSemester,
                  semester: widget.semester,
                  teacherData: widget.teacherData,
                  animation: _animations[2],
                ),
                const SizedBox(height: 16),

                // 4. Số lượng sinh viên theo lớp
                StudentsCountChart(
                  classes: classesInSemester,
                  animation: _animations[3],
                ),
                const SizedBox(height: 16),

                // 5. Phân bố giới tính
                GenderChart(
                  classes: classesInSemester,
                  genderCountByClass: widget.teacherData.genderCountByClass,
                  animation: _animations[4],
                ),
                const SizedBox(height: 16),

                // 6. Tỷ lệ qua/rớt
                PassFailDonutChart(
                  classes: classesInSemester,
                  semester: widget.semester,
                  teacherData: widget.teacherData,
                  animation: _animations[6],
                ),
                const SizedBox(height: 16),

                // 7. Tương quan điểm rèn luyện và GPA
                StudentGPAConductScatterChart(
                  classes: classesInSemester,
                  semester: widget.semester,
                  animation: _animations[7],
                ),
                const SizedBox(height: 16),

                // 8. Môn học có tỷ lệ rớt cao nhất
                SubjectFailRateCard(
                  title: 'Môn học rớt nhiều nhất',
                  subjectName: _getMostFrequentSubjectBySemesterHigh(
                    widget.teacherData.subjectFailRateHighs,
                    classesInSemester,
                  ),
                  icon: Icons.trending_down,
                  color: Colors.red,
                  animation: _animations[8],
                ),
                const SizedBox(height: 12),
                // 8b. Môn học có tỷ lệ rớt thấp nhất
                SubjectFailRateCard(
                  title: 'Môn học rớt thấp nhất',
                  subjectName: _getMostFrequentSubjectBySemesterLow(
                    widget.teacherData.subjectFailRateLows,
                    classesInSemester,
                  ),
                  icon: Icons.trending_up,
                  color: Colors.green,
                  animation: _animations[8],
                ),
                const SizedBox(height: 16),

                // 9. GPA tổng thể theo lớp
                ClassOverallGPAChart(
                  classes: classesInSemester,
                  animation: _animations[9],
                  teacherData: widget.teacherData,
                ),
                const SizedBox(height: 16),

                // 10. GPA môn học theo học kỳ
                SubjectGPABySemesterChart(
                  classes: classesInSemester,
                  semester: widget.semester,
                  teacherData: widget.teacherData,
                  animation: _animations[10],
                ),
                const SizedBox(height: 16),

                // 11. Tỷ lệ qua/rớt môn theo học kỳ
                PassFailRateBySemesterChart(
                  classes: classesInSemester,
                  semester: widget.semester,
                  teacherData: widget.teacherData,
                  animation: _animations[11],
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

  // Helper method để tìm môn học xuất hiện nhiều nhất trong danh sách (lọc theo các lớp trong kỳ) - High
  String _getMostFrequentSubjectBySemesterHigh(
    List<SubjectFailRateHighResponse>? subjectList,
    List<ClassModel> classes,
  ) {
    if (subjectList == null || subjectList.isEmpty || classes.isEmpty) {
      return 'Chưa có dữ liệu';
    }

    // Lọc theo các lớp trong kỳ
    final filteredSubjects = <String>[];
    final classNames = classes.map((c) => c.tenLop).toSet();
    final classMaLops = classes.map((c) => c.maLop).toSet();

    for (var item in subjectList) {
      if (classNames.contains(item.tenLop) || 
          classNames.contains(item.tenLop.trim()) ||
          classMaLops.contains(item.tenLop) ||
          classMaLops.contains(item.tenLop.trim())) {
        if (item.tenMonHoc.isNotEmpty) {
          filteredSubjects.add(item.tenMonHoc);
        }
      }
    }

    if (filteredSubjects.isEmpty) {
      return 'Chưa có dữ liệu';
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

    return mostFrequentSubject ?? 'Chưa có dữ liệu';
  }

  // Helper method để tìm môn học xuất hiện nhiều nhất trong danh sách (lọc theo các lớp trong kỳ) - Low
  String _getMostFrequentSubjectBySemesterLow(
    List<SubjectFailRateLowResponse>? subjectList,
    List<ClassModel> classes,
  ) {
    if (subjectList == null || subjectList.isEmpty || classes.isEmpty) {
      return 'Chưa có dữ liệu';
    }

    // Lọc theo các lớp trong kỳ
    final filteredSubjects = <String>[];
    final classNames = classes.map((c) => c.tenLop).toSet();
    final classMaLops = classes.map((c) => c.maLop).toSet();

    for (var item in subjectList) {
      if (classNames.contains(item.tenLop) || 
          classNames.contains(item.tenLop.trim()) ||
          classMaLops.contains(item.tenLop) ||
          classMaLops.contains(item.tenLop.trim())) {
        if (item.tenMonHoc.isNotEmpty) {
          filteredSubjects.add(item.tenMonHoc);
        }
      }
    }

    if (filteredSubjects.isEmpty) {
      return 'Chưa có dữ liệu';
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

    return mostFrequentSubject ?? 'Chưa có dữ liệu';
  }
}
