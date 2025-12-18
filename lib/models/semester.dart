import 'subject.dart';

class Semester {
  final String hocKy; // VD: "2023-2024-1" hoặc "HK1-2023"
  final int namHoc;
  final int hocKySo; // 1 hoặc 2
  final List<Subject> subjects;
  final double? gpa;
  final String? xepLoai; // Giỏi, Khá, Trung bình, Yếu
  final double? diemRenLuyen; // Điểm rèn luyện (0-100)

  Semester({
    required this.hocKy,
    required this.namHoc,
    required this.hocKySo,
    required this.subjects,
    this.gpa,
    this.xepLoai,
    this.diemRenLuyen,
  });

  // Tính GPA từ danh sách môn học
  double calculateGPA() {
    if (subjects.isEmpty) return 0.0;
    double totalDiem = 0.0;
    int totalTinChi = 0;
    
    for (var subject in subjects) {
      totalDiem += subject.diem * subject.soTinChi;
      totalTinChi += subject.soTinChi;
    }
    
    return totalTinChi > 0 ? totalDiem / totalTinChi : 0.0;
  }

  // Tính tỷ lệ đậu
  double calculatePassRate() {
    if (subjects.isEmpty) return 0.0;
    int passedCount = subjects.where((s) => s.isPassed).length;
    return (passedCount / subjects.length) * 100;
  }

  // Xác định xếp loại
  String getXepLoai() {
    final gpaValue = gpa ?? calculateGPA();
    if (gpaValue >= 9.0) return 'Xuất sắc';
    if (gpaValue >= 8.0) return 'Giỏi';
    if (gpaValue >= 7.0) return 'Khá';
    if (gpaValue >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  factory Semester.fromJson(Map<String, dynamic> json) {
    final subjectsList = (json['subjects'] as List?)
            ?.map((s) => Subject.fromJson(s))
            .toList() ??
        [];
    
    final semester = Semester(
      hocKy: json['hoc_ky'] ?? '',
      namHoc: json['nam_hoc'] ?? 0,
      hocKySo: json['hoc_ky_so'] ?? 1,
      subjects: subjectsList,
      gpa: json['gpa'] != null ? (json['gpa'] as num).toDouble() : null,
      xepLoai: json['xep_loai'],
      diemRenLuyen: json['diem_ren_luyen'] != null ? (json['diem_ren_luyen'] as num).toDouble() : null,
    );
    
    // Tính toán nếu chưa có
    if (semester.gpa == null) {
      final calculatedGPA = semester.calculateGPA();
      return Semester(
        hocKy: semester.hocKy,
        namHoc: semester.namHoc,
        hocKySo: semester.hocKySo,
        subjects: semester.subjects,
        gpa: calculatedGPA,
        xepLoai: semester.getXepLoai(),
        diemRenLuyen: semester.diemRenLuyen,
      );
    }
    
    return semester;
  }

  Map<String, dynamic> toJson() {
    return {
      'hoc_ky': hocKy,
      'nam_hoc': namHoc,
      'hoc_ky_so': hocKySo,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'gpa': gpa,
      'xep_loai': xepLoai,
      'diem_ren_luyen': diemRenLuyen,
    };
  }
}



