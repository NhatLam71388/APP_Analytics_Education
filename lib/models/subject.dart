class Subject {
  final String maMon;
  final String tenMon;
  final double diem;
  final int soTinChi;
  final bool isPassed; // true nếu đậu (diem >= 5.0)
  final double? diemTrungBinhLop; // Điểm trung bình của lớp cho môn này

  Subject({
    required this.maMon,
    required this.tenMon,
    required this.diem,
    required this.soTinChi,
    required this.isPassed,
    this.diemTrungBinhLop,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final diem = (json['diem'] as num).toDouble();
    return Subject(
      maMon: json['ma_mon'] ?? '',
      tenMon: json['ten_mon'] ?? '',
      diem: diem,
      soTinChi: json['so_tin_chi'] ?? 0,
      isPassed: diem >= 5.0,
      diemTrungBinhLop: json['diem_trung_binh_lop'] != null ? (json['diem_trung_binh_lop'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_mon': maMon,
      'ten_mon': tenMon,
      'diem': diem,
      'so_tin_chi': soTinChi,
      'is_passed': isPassed,
      'diem_trung_binh_lop': diemTrungBinhLop,
    };
  }
  
  // Xác định loại điểm (Giỏi >= 8.0, Khá >= 7.0, Trung bình >= 5.0, Yếu < 5.0)
  String getGradeLevel() {
    if (diem >= 8.0) return 'Giỏi';
    if (diem >= 7.0) return 'Khá';
    if (diem >= 5.0) return 'Trung bình';
    return 'Yếu';
  }
}



