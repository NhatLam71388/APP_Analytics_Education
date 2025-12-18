import 'student_model.dart';

class ClassModel {
  final String maLop;
  final String tenLop;
  final int namHoc;
  final int khoa;
  final List<StudentModel> students;
  final List<ClassSemesterData> semesterData;
  final int? totalStudentsCount; // Tổng số sinh viên từ API

  ClassModel({
    required this.maLop,
    required this.tenLop,
    required this.namHoc,
    required this.khoa,
    required this.students,
    required this.semesterData,
    this.totalStudentsCount,
  });

  // Tổng số sinh viên - ưu tiên dùng từ API, nếu không có thì dùng students.length
  int get totalStudents => totalStudentsCount ?? students.length;

  // Số sinh viên nam
  int get maleCount => students.where((s) => s.gioiTinh == 'Nam').length;

  // Số sinh viên nữ
  int get femaleCount => students.where((s) => s.gioiTinh == 'Nữ').length;

  // GPA trung bình toàn khóa
  double getOverallGPA() {
    if (semesterData.isEmpty) return 0.0;
    double totalGPA = 0.0;
    for (var data in semesterData) {
      totalGPA += data.gpa;
    }
    return totalGPA / semesterData.length;
  }

  // GPA trung bình theo học kỳ
  double? getGPABySemester(String hocKy) {
    final data = semesterData.firstWhere(
      (d) => d.hocKy == hocKy,
      orElse: () => semesterData.first,
    );
    return data.gpa;
  }

  // Tỷ lệ đậu/rớt theo học kỳ
  double getPassRateBySemester(String hocKy) {
    final data = semesterData.firstWhere(
      (d) => d.hocKy == hocKy,
      orElse: () => semesterData.first,
    );
    return data.passRate;
  }

  // Tỷ lệ học lực theo học kỳ
  Map<String, double> getAcademicLevelBySemester(String hocKy) {
    final data = semesterData.firstWhere(
      (d) => d.hocKy == hocKy,
      orElse: () => semesterData.first,
    );
    return data.academicLevels;
  }

  // Điểm rèn luyện trung bình
  double getAverageConductScore() {
    if (students.isEmpty) return 0.0;
    double total = 0.0;
    for (var student in students) {
      total += student.diemRenLuyen;
    }
    return total / students.length;
  }
}

class ClassSemesterData {
  final String hocKy;
  final int namHoc;
  final int hocKySo;
  final double gpa;
  final double passRate; // Tỷ lệ đậu (%)
  final Map<String, double> academicLevels; // {"Giỏi": 30, "Khá": 50, "Trung bình": 20}
  final Map<String, double> subjectGPA; // GPA theo từng môn
  final Map<String, double> subjectPassRate; // Tỷ lệ đậu theo từng môn
  final int? totalStudents; // Tổng số sinh viên trong kỳ này
  final int? maleCount; // Số sinh viên nam trong kỳ này
  final int? femaleCount; // Số sinh viên nữ trong kỳ này

  ClassSemesterData({
    required this.hocKy,
    required this.namHoc,
    required this.hocKySo,
    required this.gpa,
    required this.passRate,
    required this.academicLevels,
    required this.subjectGPA,
    required this.subjectPassRate,
    this.totalStudents,
    this.maleCount,
    this.femaleCount,
  });
}

