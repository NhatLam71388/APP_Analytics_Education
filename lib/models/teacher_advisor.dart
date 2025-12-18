import 'class_model.dart';
import '../services/teacher_api_service.dart';

class TeacherAdvisor {
  final String maGiangVien;
  final String hoTen;
  final List<ClassModel> classes;
  final int? soLopPhuTrach; // Từ API So-Lop-Phu-Trach
  final int? totalStudentsFromAPI; // Tổng số sinh viên tính từ API Tong-So-Sinh-Vien-Theo-Lop
  final Map<String, GenderCount>? genderCountByClass; // Map từ tenLop -> GenderCount từ API So-Luong-Sinh-Vien-Nam-Nu-Theo-Lop
  final List<ClassGPATrendResponse>? gpaTrendByClass; // Dữ liệu từ API Xu-Huong-GPA-Trung-Binh-Theo-Lop
  final List<SubjectFailRateHighResponse>? subjectFailRateHighs; // Dữ liệu từ API Mon-Hoc-Ty-Le-Rot-Cao-Nhat-Theo-Lop
  final List<SubjectFailRateLowResponse>? subjectFailRateLows; // Dữ liệu từ API Mon-Hoc-Ty-Le-Rot-Thap-Nhat-Theo-Lop
  final List<ClassAcademicLevelResponse>? academicLevelsByClass; // Dữ liệu từ API Ty-Le-Phan-Tram-Hoc-Luc-Theo-Lop-Hoc-Ky
  final List<ClassSubjectGPAResponse>? subjectGPAsByClass; // Dữ liệu từ API GPA-Trung-Binh-Theo-Lop-Mon-Hoc-Hoc-Ky-Nam-Hoc
  final List<SubjectGPAComparisonResponse>? subjectGPAComparisons; // Dữ liệu từ API Diem-Trung-Binh-Mon-So-Voi-GPA-Toan-Khoa
  final List<SubjectGradeDistributionResponse>? subjectGradeDistributions; // Dữ liệu từ API Ty-Le-Phan-Tram-Loai-Theo-Mon-Hoc-Lop
  final List<SubjectPassFailRateBySemesterResponse>? subjectPassFailRatesBySemester; // Dữ liệu từ API Ty-Le-Phan-Tram-Qua-Rot-Mon-Theo-Lop-Hoc-Ky-Nam-Hoc
  final List<ClassOverallGPAResponse>? classOverallGPAs; // Dữ liệu từ API GPA-Trung-Binh-Theo-Lop-Toan-Khoa
  final List<StudentFailCountBySemesterResponse>? studentFailCountsBySemester; // Dữ liệu từ API so-luong-sinh-vien-rot-mon-tai-hoc-ki-nam-hoc
  final List<ClassPassFailRateResponse>? classPassFailRates; // Dữ liệu từ API Ty-Le-Phan-Tram-Qua-Rot-Mon-Theo-Lop-Hoc-Ky-Nam-Hoc-mobi
  final List<TeacherAdvisorBySemesterResponse>? teacherAdvisorBySemesters; // Dữ liệu từ API Giang-Vien-Co-Van-Lop-Hoc-Theo-Ky
  final Map<String, double>? averageGPABySemester; // GPA trung bình theo Ten Nam Hoc + Ten Hoc Ky (key: "Ten Nam Hoc-Ten Hoc Ky")

  TeacherAdvisor({
    required this.maGiangVien,
    required this.hoTen,
    required this.classes,
    this.soLopPhuTrach,
    this.totalStudentsFromAPI,
    this.genderCountByClass,
    this.gpaTrendByClass,
    this.subjectFailRateHighs,
    this.subjectFailRateLows,
    this.academicLevelsByClass,
    this.subjectGPAsByClass,
    this.subjectGPAComparisons,
    this.subjectGradeDistributions,
    this.subjectPassFailRatesBySemester,
    this.classOverallGPAs,
    this.studentFailCountsBySemester,
    this.classPassFailRates,
    this.teacherAdvisorBySemesters,
    this.averageGPABySemester,
  });
  
  // Tính tổng số nam từ API cho các lớp trong danh sách
  int getTotalMaleFromAPI(List<String> classNames) {
    if (genderCountByClass == null) return 0;
    int total = 0;
    for (var className in classNames) {
      final genderCount = genderCountByClass![className];
      if (genderCount != null) {
        total += genderCount.soNam;
      }
    }
    return total;
  }
  
  // Tính tổng số nữ từ API cho các lớp trong danh sách
  int getTotalFemaleFromAPI(List<String> classNames) {
    if (genderCountByClass == null) return 0;
    int total = 0;
    for (var className in classNames) {
      final genderCount = genderCountByClass![className];
      if (genderCount != null) {
        total += genderCount.soNu;
      }
    }
    return total;
  }

  // Tổng số lớp đang cố vấn - ưu tiên từ API
  int get totalClasses => soLopPhuTrach ?? classes.length;

  // Tổng số sinh viên tất cả các lớp - ưu tiên từ API
  int get totalStudents {
    if (totalStudentsFromAPI != null) {
      return totalStudentsFromAPI!;
    }
    int total = 0;
    for (var classItem in classes) {
      total += classItem.totalStudents;
    }
    return total;
  }

  // Lấy GPA trung bình theo Ten Nam Hoc + Ten Hoc Ky
  // tenNamHoc: "2022 - 2023", tenHocKy: "HK2" hoặc "HK1" hoặc "HK_2"
  double? getAverageGPABySemester(String tenNamHoc, String tenHocKy) {
    if (averageGPABySemester == null) return null;
    
    // Normalize tenHocKy để match với key trong map (giống logic trong teacher_data_service)
    String normalizedHocKy = tenHocKy;
    if (tenHocKy.isEmpty || tenHocKy.trim().isEmpty) {
      return null;
    }
    if (tenHocKy.contains('_')) {
      final parts = tenHocKy.split('_');
      if (parts.length > 1) {
        normalizedHocKy = 'HK${parts[1]}';
      }
    }
    // Nếu đã là format "HK1", "HK2", etc thì giữ nguyên
    
    final key = '$tenNamHoc-$normalizedHocKy';
    return averageGPABySemester![key];
  }
}

class GenderCount {
  final int soNam;
  final int soNu;
  
  GenderCount({
    required this.soNam,
    required this.soNu,
  });
}

