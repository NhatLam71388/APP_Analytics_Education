class PredictionResponse {
  final int maSinhVien;
  final String hoTen;
  final double gpaHe10;
  final double gpaHe4;
  final int tongTinChi;
  final int conLai;
  final DuDoan duDoan;

  PredictionResponse({
    required this.maSinhVien,
    required this.hoTen,
    required this.gpaHe10,
    required this.gpaHe4,
    required this.tongTinChi,
    required this.conLai,
    required this.duDoan,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      maSinhVien: json['MaSinhVien'] as int,
      hoTen: json['HoTen'] as String,
      gpaHe10: (json['GPA_He10'] as num).toDouble(),
      gpaHe4: (json['GPA_He4'] as num).toDouble(),
      tongTinChi: json['TongTinChi'] as int,
      conLai: json['ConLai'] as int,
      duDoan: DuDoan.fromJson(json['DuDoan'] as Map<String, dynamic>),
    );
  }
}

class DuDoan {
  final String phuongPhap;
  final int soKichBan;
  final double gpaHienTaiHe10;
  final double gpaHienTaiHe4;
  final String loaiHienTai;
  final XacSuatDatLoai xacSuatDatLoai;
  final DiemCanDat diemCanDat;
  final String ghiChu;

  DuDoan({
    required this.phuongPhap,
    required this.soKichBan,
    required this.gpaHienTaiHe10,
    required this.gpaHienTaiHe4,
    required this.loaiHienTai,
    required this.xacSuatDatLoai,
    required this.diemCanDat,
    required this.ghiChu,
  });

  factory DuDoan.fromJson(Map<String, dynamic> json) {
    return DuDoan(
      phuongPhap: json['PhuongPhap'] as String,
      soKichBan: json['SoKichBan'] as int,
      gpaHienTaiHe10: (json['GPA_HienTai_He10'] as num).toDouble(),
      gpaHienTaiHe4: (json['GPA_HienTai_He4'] as num).toDouble(),
      loaiHienTai: json['Loai_HienTai'] as String,
      xacSuatDatLoai: XacSuatDatLoai.fromJson(
        json['XacSuat_DatLoai'] as Map<String, dynamic>,
      ),
      diemCanDat: DiemCanDat.fromJson(
        json['DiemCanDat_O_ConLai_DeDat'] as Map<String, dynamic>,
      ),
      ghiChu: json['GhiChu'] as String,
    );
  }
}

class XacSuatDatLoai {
  final double gioi;
  final double kha;
  final double trungBinh;
  final double xuatSac;
  final double yeu;
  final double kem;

  XacSuatDatLoai({
    required this.gioi,
    required this.kha,
    required this.trungBinh,
    required this.xuatSac,
    required this.yeu,
    required this.kem,
  });

  factory XacSuatDatLoai.fromJson(Map<String, dynamic> json) {
    return XacSuatDatLoai(
      gioi: (json['Giỏi'] as num).toDouble(),
      kha: (json['Khá'] as num).toDouble(),
      trungBinh: (json['Trung bình'] as num).toDouble(),
      xuatSac: (json['Xuất sắc'] as num).toDouble(),
      yeu: (json['Yếu'] as num).toDouble(),
      kem: (json['Kém'] as num).toDouble(),
    );
  }

  List<MapEntry<String, double>> get entries => [
        MapEntry('Xuất sắc', xuatSac),
        MapEntry('Giỏi', gioi),
        MapEntry('Khá', kha),
        MapEntry('Trung bình', trungBinh),
        MapEntry('Yếu', yeu),
        MapEntry('Kém', kem),
      ]..removeWhere((entry) => entry.value == 0);
}

class DiemCanDat {
  final double? xuatSac;
  final double? gioi;
  final double? kha;

  DiemCanDat({
    this.xuatSac,
    this.gioi,
    this.kha,
  });

  factory DiemCanDat.fromJson(Map<String, dynamic> json) {
    return DiemCanDat(
      xuatSac: json['Xuất sắc (≥3.60)'] != null && json['Xuất sắc (≥3.60)'] != 'null'
          ? (json['Xuất sắc (≥3.60)'] as num).toDouble()
          : null,
      gioi: json['Giỏi     (≥3.20)'] != null && json['Giỏi     (≥3.20)'] != 'null'
          ? (json['Giỏi     (≥3.20)'] as num).toDouble()
          : null,
      kha: json['Khá      (≥2.50)'] != null && json['Khá      (≥2.50)'] != 'null'
          ? (json['Khá      (≥2.50)'] as num).toDouble()
          : null,
    );
  }
}

// Model cho dự đoán học kỳ tới
class PredictionNextSemesterResponse {
  final int maSinhVien;
  final String hoTen;
  final double gpaHe10;
  final double gpaHe4;
  final int tongTinChi;
  final int conLai;
  final DuDoanNextSemester duDoan;

  PredictionNextSemesterResponse({
    required this.maSinhVien,
    required this.hoTen,
    required this.gpaHe10,
    required this.gpaHe4,
    required this.tongTinChi,
    required this.conLai,
    required this.duDoan,
  });

  factory PredictionNextSemesterResponse.fromJson(Map<String, dynamic> json) {
    return PredictionNextSemesterResponse(
      maSinhVien: json['MaSinhVien'] as int,
      hoTen: json['HoTen'] as String,
      gpaHe10: (json['GPA_He10'] as num).toDouble(),
      gpaHe4: (json['GPA_He4'] as num).toDouble(),
      tongTinChi: json['TongTinChi'] as int,
      conLai: json['ConLai'] as int,
      duDoan: DuDoanNextSemester.fromJson(json['DuDoan'] as Map<String, dynamic>),
    );
  }
}

class DuDoanNextSemester {
  final String phuongPhap;
  final int tinChiHocKySau;
  final int soKichBan;
  final double gpaHienTaiHe10;
  final double gpaHienTaiHe4;
  final String loaiHienTai;
  final XacSuatDatLoai xacSuatDatLoai;
  final DiemCanDat diemCanDat;
  final String ghiChu;

  DuDoanNextSemester({
    required this.phuongPhap,
    required this.tinChiHocKySau,
    required this.soKichBan,
    required this.gpaHienTaiHe10,
    required this.gpaHienTaiHe4,
    required this.loaiHienTai,
    required this.xacSuatDatLoai,
    required this.diemCanDat,
    required this.ghiChu,
  });

  factory DuDoanNextSemester.fromJson(Map<String, dynamic> json) {
    return DuDoanNextSemester(
      phuongPhap: json['PhuongPhap'] as String,
      tinChiHocKySau: json['TinChi_Hoc_Ky_Sau'] as int,
      soKichBan: json['SoKichBan'] as int,
      gpaHienTaiHe10: (json['GPA_HienTai_He10'] as num).toDouble(),
      gpaHienTaiHe4: (json['GPA_HienTai_He4'] as num).toDouble(),
      loaiHienTai: json['Loai_HienTai'] as String,
      xacSuatDatLoai: XacSuatDatLoai.fromJson(
        json['XacSuat_DatLoai'] as Map<String, dynamic>,
      ),
      diemCanDat: DiemCanDat.fromJson(
        json['DiemCanDat_O_ConLai_DeDat'] as Map<String, dynamic>,
      ),
      ghiChu: json['GhiChu'] as String,
    );
  }
}

// Model cho dự đoán điểm các môn
class PredictionSubjectsResponse {
  final String hoTen;
  final String maSinhVien;
  final String khoaHoc;
  final int tongMonDuDoan;
  final double diemTrungBinhDuDoan;
  final List<MonDuDoan> danhSachMon;

  PredictionSubjectsResponse({
    required this.hoTen,
    required this.maSinhVien,
    required this.khoaHoc,
    required this.tongMonDuDoan,
    required this.diemTrungBinhDuDoan,
    required this.danhSachMon,
  });

  factory PredictionSubjectsResponse.fromJson(Map<String, dynamic> json) {
    return PredictionSubjectsResponse(
      hoTen: json['HoTen'] as String,
      maSinhVien: json['MaSinhVien'].toString(),
      khoaHoc: json['KhoaHoc'] as String,
      tongMonDuDoan: json['tong_mon_du_doan'] as int,
      diemTrungBinhDuDoan: (json['diem_trung_binh_du_doan'] as num).toDouble(),
      danhSachMon: (json['danh_sach_mon'] as List<dynamic>)
          .map((item) => MonDuDoan.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MonDuDoan {
  final String tenMonHoc;
  final double diemDuDoan;
  final double diemGiuaKy;
  final double gpaTruocMon;

  MonDuDoan({
    required this.tenMonHoc,
    required this.diemDuDoan,
    required this.diemGiuaKy,
    required this.gpaTruocMon,
  });

  factory MonDuDoan.fromJson(Map<String, dynamic> json) {
    return MonDuDoan(
      tenMonHoc: json['TenMonHoc'] as String,
      diemDuDoan: (json['Diem_DuDoan'] as num).toDouble(),
      diemGiuaKy: (json['Diem_GiuaKy'] as num? ?? 0).toDouble(),
      gpaTruocMon: (json['GPA_truoc_mon'] as num).toDouble(),
    );
  }
}



