import 'subject.dart';
import 'semester.dart';

class StudentAcademic {
  final String maSinhVien;
  final String hoTen;
  final String lop;
  final String khuVuc;
  final List<Semester> semesters;

  StudentAcademic({
    required this.maSinhVien,
    required this.hoTen,
    required this.lop,
    required this.khuVuc,
    required this.semesters,
  });

  // Tính GPA tổng kết toàn khóa
  double calculateOverallGPA() {
    if (semesters.isEmpty) return 0.0;
    
    double totalDiem = 0.0;
    int totalTinChi = 0;
    
    for (var semester in semesters) {
      for (var subject in semester.subjects) {
        totalDiem += subject.diem * subject.soTinChi;
        totalTinChi += subject.soTinChi;
      }
    }
    
    return totalTinChi > 0 ? totalDiem / totalTinChi : 0.0;
  }

  // Tính tỷ lệ đậu toàn khóa
  double calculateOverallPassRate() {
    if (semesters.isEmpty) return 0.0;
    
    int totalSubjects = 0;
    int passedSubjects = 0;
    
    for (var semester in semesters) {
      totalSubjects += semester.subjects.length;
      passedSubjects += semester.subjects.where((s) => s.isPassed).length;
    }
    
    return totalSubjects > 0 ? (passedSubjects / totalSubjects) * 100 : 0.0;
  }

  // Xếp loại toàn khóa
  String getOverallXepLoai() {
    final gpa = calculateOverallGPA();
    if (gpa >= 9.0) return 'Xuất sắc';
    if (gpa >= 8.0) return 'Giỏi';
    if (gpa >= 7.0) return 'Khá';
    if (gpa >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  // Lấy môn điểm cao nhất trong học kỳ
  Subject? getHighestScoreSubject(String hocKy) {
    final semester = semesters.firstWhere(
      (s) => s.hocKy == hocKy,
      orElse: () => semesters.first,
    );
    
    if (semester.subjects.isEmpty) return null;
    
    return semester.subjects.reduce((a, b) => a.diem > b.diem ? a : b);
  }

  // Lấy môn điểm thấp nhất trong học kỳ
  Subject? getLowestScoreSubject(String hocKy) {
    final semester = semesters.firstWhere(
      (s) => s.hocKy == hocKy,
      orElse: () => semesters.first,
    );
    
    if (semester.subjects.isEmpty) return null;
    
    return semester.subjects.reduce((a, b) => a.diem < b.diem ? a : b);
  }

  factory StudentAcademic.fromJson(Map<String, dynamic> json) {
    final semestersList = (json['semesters'] as List?)
            ?.map((s) => Semester.fromJson(s))
            .toList() ??
        [];
    
    return StudentAcademic(
      maSinhVien: json['ma_sinh_vien'] ?? '',
      hoTen: json['ho_ten'] ?? '',
      lop: json['lop'] ?? '',
      khuVuc: json['khu_vuc'] ?? '',
      semesters: semestersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_sinh_vien': maSinhVien,
      'ho_ten': hoTen,
      'lop': lop,
      'khu_vuc': khuVuc,
      'semesters': semesters.map((s) => s.toJson()).toList(),
    };
  }
}

