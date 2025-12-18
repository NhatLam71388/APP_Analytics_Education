import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/prediction_response.dart' show PredictionResponse, PredictionNextSemesterResponse, PredictionSubjectsResponse, DuDoan, DuDoanNextSemester, XacSuatDatLoai, DiemCanDat, MonDuDoan;

class StudentApiService {
  static const String baseUrl = ApiService.baseUrl;
  
  // Helper method to get headers with auth token
  static Future<Map<String, String>> getHeaders() async {
    final accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Không có access token. Vui lòng đăng nhập lại.');
    }
    
    // Đảm bảo token không có khoảng trắng thừa
    final cleanToken = accessToken.trim();
    
    final headers = ApiService.getHeaders(accessToken: cleanToken);
    // Thêm header cho ngrok nếu cần
    headers['ngrok-skip-browser-warning'] = 'true';
    
    // Debug: Log token (chỉ hiển thị một phần để bảo mật)
    if (kDebugMode) {
      debugPrint('Authorization header: Bearer ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
    }
    
    return headers;
  }

  // 1. Thông tin sinh viên
  static Future<StudentInfoResponse> getStudentInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/thong-tin-sinh-vien'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isEmpty) {
          throw Exception('404: Không tìm thấy dữ liệu.');
        }
        return StudentInfoResponse.fromJson(jsonData[0]);
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 2. Số học kỳ sinh viên đã học
  static Future<SemesterCountResponse> getSemesterCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/so-hoc-ky-sinh-vien-da-hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isEmpty) {
          throw Exception('404: Không tìm thấy dữ liệu.');
        }
        return SemesterCountResponse.fromJson(jsonData[0]);
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 3. Môn học sinh viên đã học theo kỳ
  static Future<List<SubjectBySemesterResponse>> getSubjectsBySemester() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/mon-hoc-sinh-vien-da-hoc-theo-hoc-ky'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectBySemesterResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 4. GPA sinh viên theo từng kỳ năm học
  static Future<List<SemesterGPAResponse>> getSemesterGPA() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/gpa-sinh-vien-theo-hoc-ky-nam-hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SemesterGPAResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 5. GPA trung bình toàn khóa của sinh viên
  static Future<OverallGPAResponse> getOverallGPA() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/gpa-trung-binh-toan-khoa-cua-sinh-vien'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isEmpty) {
          throw Exception('404: Không tìm thấy dữ liệu.');
        }
        return OverallGPAResponse.fromJson(jsonData[0]);
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 6. Tỷ lệ qua môn của sinh viên
  static Future<List<PassRateBySemesterResponse>> getPassRateBySemester() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/ty-le-qua-mon-cua-sinh-vien'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => PassRateBySemesterResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 7. Điểm chi tiết từng môn học sinh viên đã học theo kỳ và năm học
  static Future<List<SubjectDetailResponse>> getSubjectDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/diem-chi-tiet-tung-mon-hoc-sinh-vien-da-hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectDetailResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 8. Môn học điểm cao nhất trong học kỳ
  static Future<List<HighestScoreResponse>> getHighestScores() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/mon-hoc-diem-cao-nhat-trong-hoc-ky'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => HighestScoreResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 9. Môn học điểm thấp nhất trong học kỳ
  static Future<List<LowestScoreResponse>> getLowestScores() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/mon-hoc-diem-thap-nhat-trong-hoc-ky'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => LowestScoreResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 10. So sánh điểm trung bình môn học của sinh viên với lớp
  static Future<List<SubjectComparisonResponse>> getSubjectComparison() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/so-sanh-diem-trung-binh-mon-hoc-cua-sinh-vien-voi-lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectComparisonResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 11. Xu hướng GPA qua các kỳ
  static Future<List<GPATrendResponse>> getGPATrend() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/xu-huong-gpa-cua-sinh-vien-qua-cac-hoc-ky'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => GPATrendResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 12. Điểm rèn luyện của sinh viên trong từng kỳ
  static Future<List<ConductScoreResponse>> getConductScores() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/diem-ren-luyen-cua-sinh-vien-trong-tung-hoc-ky'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ConductScoreResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 13. Tỷ lệ thuận của GPA và điểm rèn luyện của sinh viên
  static Future<List<GPAConductCorrelationResponse>> getGPAConductCorrelation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/ty-le-thuan-cua-gpa-va-diem-ren-luyen-cua-sinh-vien'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => GPAConductCorrelationResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 14. Tỷ lệ môn học đạt loại của sinh viên
  static Future<List<SubjectGradeRateResponse>> getSubjectGradeRate() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/ty-le-mon-hoc-dat-loai-cua-sinh-vien-loai-chu'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectGradeRateResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // 15. Số tín chỉ đăng ký của sinh viên
  static Future<List<CreditResponse>> getCreditInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sinhvien/so-tin-chi-dang-ki-cua-sinh-vien'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => CreditResponse.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('access token') || e.toString().contains('hết hạn')) {
        rethrow;
      }
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }
}

// Response Models
class StudentInfoResponse {
  final String maSinhVien;
  final String hoTen;
  final String tenLop;
  final String tenKhuVuc;
  final int factHocTapCount;

  StudentInfoResponse({
    required this.maSinhVien,
    required this.hoTen,
    required this.tenLop,
    required this.tenKhuVuc,
    required this.factHocTapCount,
  });

  factory StudentInfoResponse.fromJson(Map<String, dynamic> json) {
    return StudentInfoResponse(
      maSinhVien: json['Ma Sinh Vien'] ?? '',
      hoTen: json['Ho Ten'] ?? '',
      tenLop: json['Ten Lop'] ?? '',
      tenKhuVuc: json['Ten Khu Vuc'] ?? '',
      factHocTapCount: json['Fact Hoc Tap Count'] ?? 0,
    );
  }
}

class SemesterCountResponse {
  final String hoTen;
  final int soKyHoc;

  SemesterCountResponse({
    required this.hoTen,
    required this.soKyHoc,
  });

  factory SemesterCountResponse.fromJson(Map<String, dynamic> json) {
    return SemesterCountResponse(
      hoTen: json['Ho Ten'] ?? '',
      soKyHoc: json['So_Ky_Hoc'] ?? 0,
    );
  }
}

class SubjectBySemesterResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenMonHoc;
  final String soTinChi;
  final double diemTrungBinh;

  SubjectBySemesterResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenMonHoc,
    required this.soTinChi,
    required this.diemTrungBinh,
  });

  factory SubjectBySemesterResponse.fromJson(Map<String, dynamic> json) {
    return SubjectBySemesterResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      soTinChi: json['So Tin Chi'] ?? '0',
      diemTrungBinh: (json['Diem Trung Binh'] ?? 0.0).toDouble(),
    );
  }
}

class SemesterGPAResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final double gpaHocKy;
  final String diemChu;
  final String loaiHocLuc;

  SemesterGPAResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.gpaHocKy,
    required this.diemChu,
    required this.loaiHocLuc,
  });

  factory SemesterGPAResponse.fromJson(Map<String, dynamic> json) {
    return SemesterGPAResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      gpaHocKy: (json['GPA_HocKy'] ?? 0.0).toDouble(),
      diemChu: json['Diem_Chu'] ?? '',
      loaiHocLuc: json['Loai_Hoc_Luc'] ?? '',
    );
  }
}

class OverallGPAResponse {
  final double gpaToanKhoa;
  final String diemChuToanKhoa;
  final String loaiHocLucToanKhoa;

  OverallGPAResponse({
    required this.gpaToanKhoa,
    required this.diemChuToanKhoa,
    required this.loaiHocLucToanKhoa,
  });

  factory OverallGPAResponse.fromJson(Map<String, dynamic> json) {
    return OverallGPAResponse(
      gpaToanKhoa: (json['GPA_ToanKhoa'] ?? 0.0).toDouble(),
      diemChuToanKhoa: json['Diem_Chu_ToanKhoa'] ?? '',
      loaiHocLucToanKhoa: json['Loai_Hoc_Luc_ToanKhoa'] ?? '',
    );
  }
}

class PassRateBySemesterResponse {
  final String maSinhVien;
  final String tenNamHoc;
  final String tenHocKy;
  final int soMonDau;
  final int tongMon;
  final double tyLeQuaMon;

  PassRateBySemesterResponse({
    required this.maSinhVien,
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.soMonDau,
    required this.tongMon,
    required this.tyLeQuaMon,
  });

  factory PassRateBySemesterResponse.fromJson(Map<String, dynamic> json) {
    return PassRateBySemesterResponse(
      maSinhVien: json['Ma Sinh Vien'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      soMonDau: json['So_Mon_Dau'] ?? 0,
      tongMon: json['Tong_Mon'] ?? 0,
      tyLeQuaMon: (json['Ty_Le_Qua_Mon'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectDetailResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenMonHoc;
  final String diemGiuaKy;
  final String diemCuoiKy;
  final String soTinChi;
  final double diemTrungBinh;
  final String xepLoai;
  final int diemHe4;

  SubjectDetailResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenMonHoc,
    required this.diemGiuaKy,
    required this.diemCuoiKy,
    required this.soTinChi,
    required this.diemTrungBinh,
    required this.xepLoai,
    required this.diemHe4,
  });

  factory SubjectDetailResponse.fromJson(Map<String, dynamic> json) {
    return SubjectDetailResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      diemGiuaKy: json['Diem Giua Ky'] ?? '0',
      diemCuoiKy: json['Diem Cuoi Ky'] ?? '0',
      soTinChi: json['So Tin Chi'] ?? '0',
      diemTrungBinh: (json['Diem Trung Binh'] ?? 0.0).toDouble(),
      xepLoai: json['Xep Loai'] ?? '',
      diemHe4: (json['Diem He4'] ?? 0).toInt(),
    );
  }

  double get diemGiuaKyDouble {
    if (diemGiuaKy.isEmpty || diemGiuaKy == '.00' || diemGiuaKy == '.0') {
      return 0.0;
    }
    return double.tryParse(diemGiuaKy) ?? 0.0;
  }

  double get diemCuoiKyDouble {
    if (diemCuoiKy.isEmpty || diemCuoiKy == '.00' || diemCuoiKy == '.0') {
      return 0.0;
    }
    return double.tryParse(diemCuoiKy) ?? 0.0;
  }

  int get soTinChiInt {
    return int.tryParse(soTinChi) ?? 0;
  }

  bool get isPassed => diemTrungBinh >= 5.0;
}

class HighestScoreResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenMonHoc;
  final double dtb;

  HighestScoreResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenMonHoc,
    required this.dtb,
  });

  factory HighestScoreResponse.fromJson(Map<String, dynamic> json) {
    return HighestScoreResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      dtb: (json['DTB'] ?? 0.0).toDouble(),
    );
  }
}

class LowestScoreResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenMonHoc;
  final double dtb;

  LowestScoreResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenMonHoc,
    required this.dtb,
  });

  factory LowestScoreResponse.fromJson(Map<String, dynamic> json) {
    return LowestScoreResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      dtb: (json['DTB'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectComparisonResponse {
  final String tenMonHoc;
  final double dtbSv;
  final double dtbAll;

  SubjectComparisonResponse({
    required this.tenMonHoc,
    required this.dtbSv,
    required this.dtbAll,
  });

  factory SubjectComparisonResponse.fromJson(Map<String, dynamic> json) {
    return SubjectComparisonResponse(
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      dtbSv: (json['DTB_SV'] ?? 0.0).toDouble(),
      dtbAll: (json['DTB_ALL'] ?? 0.0).toDouble(),
    );
  }
}

class GPATrendResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final double gpa;

  GPATrendResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.gpa,
  });

  factory GPATrendResponse.fromJson(Map<String, dynamic> json) {
    return GPATrendResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      gpa: (json['GPA'] ?? 0.0).toDouble(),
    );
  }
}

class ConductScoreResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final double drl;

  ConductScoreResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.drl,
  });

  factory ConductScoreResponse.fromJson(Map<String, dynamic> json) {
    return ConductScoreResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      drl: (json['DRL'] ?? 0.0).toDouble(),
    );
  }
}

class GPAConductCorrelationResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final double gpa;
  final double drl;
  final double doLechChuan;
  final String tiLeThuan;

  GPAConductCorrelationResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.gpa,
    required this.drl,
    required this.doLechChuan,
    required this.tiLeThuan,
  });

  factory GPAConductCorrelationResponse.fromJson(Map<String, dynamic> json) {
    return GPAConductCorrelationResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      gpa: (json['GPA'] ?? 0.0).toDouble(),
      drl: (json['DRL'] ?? 0.0).toDouble(),
      doLechChuan: (json['Do_Lech_Chuan'] ?? 0.0).toDouble(),
      tiLeThuan: json['Ti_Le_Thuan'] ?? '',
    );
  }
}

class SubjectGradeRateResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String maSinhVien;
  final int tongMon;
  final int soA;
  final int soBPlus;
  final int soB;
  final int soCPlus;
  final int soC;
  final int soDPlus;
  final int soD;
  final int soF;
  final double tyLeA;
  final double tyLeBPlus;
  final double tyLeB;
  final double tyLeCPlus;
  final double tyLeC;
  final double tyLeDPlus;
  final double tyLeD;
  final double tyLeF;
  
  // Format mới từ teacher API (Giỏi, Khá, Trung bình, Yếu)
  final double? tyLeGioiNew;
  final double? tyLeKhaNew;
  final double? tyLeTbNew;
  final double? tyLeYeuNew;
  final bool isNewFormat; // Flag để biết là format mới hay cũ

  SubjectGradeRateResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.maSinhVien,
    required this.tongMon,
    required this.soA,
    required this.soBPlus,
    required this.soB,
    required this.soCPlus,
    required this.soC,
    required this.soDPlus,
    required this.soD,
    required this.soF,
    required this.tyLeA,
    required this.tyLeBPlus,
    required this.tyLeB,
    required this.tyLeCPlus,
    required this.tyLeC,
    required this.tyLeDPlus,
    required this.tyLeD,
    required this.tyLeF,
    this.tyLeGioiNew,
    this.tyLeKhaNew,
    this.tyLeTbNew,
    this.tyLeYeuNew,
    this.isNewFormat = false,
  });

  factory SubjectGradeRateResponse.fromJson(Map<String, dynamic> json) {
    // Kiểm tra format: nếu có TyLe_Gioi thì là format mới (teacher API)
    final isNewFormat = json.containsKey('TyLe_Gioi');
    
    if (isNewFormat) {
      // Format mới từ teacher API: TyLe_Gioi, TyLe_Kha, TyLe_TB, TyLe_Yeu
      final tyLeGioi = (json['TyLe_Gioi'] ?? 0.0).toDouble();
      final tyLeKha = (json['TyLe_Kha'] ?? 0.0).toDouble();
      final tyLeTb = (json['TyLe_TB'] ?? 0.0).toDouble();
      final tyLeYeu = (json['TyLe_Yeu'] ?? 0.0).toDouble();
      
      // Format mới không có tongMon, sẽ tính từ studentData sau
      return SubjectGradeRateResponse(
        tenNamHoc: json['Ten Nam Hoc'] ?? '',
        tenHocKy: json['Ten Hoc Ky'] ?? '',
        maSinhVien: json['Ma Sinh Vien'] ?? '',
        tongMon: 0, // Sẽ tính từ studentData sau
        soA: 0,
        soBPlus: 0,
        soB: 0,
        soCPlus: 0,
        soC: 0,
        soDPlus: 0,
        soD: 0,
        soF: 0,
        tyLeA: 0.0,
        tyLeBPlus: 0.0,
        tyLeB: 0.0,
        tyLeCPlus: 0.0,
        tyLeC: 0.0,
        tyLeDPlus: 0.0,
        tyLeD: 0.0,
        tyLeF: 0.0,
        tyLeGioiNew: tyLeGioi,
        tyLeKhaNew: tyLeKha,
        tyLeTbNew: tyLeTb,
        tyLeYeuNew: tyLeYeu,
        isNewFormat: true,
      );
    } else {
      // Format cũ từ student API: TyLe_A, TyLe_B+, etc.
      return SubjectGradeRateResponse(
        tenNamHoc: json['Ten Nam Hoc'] ?? '',
        tenHocKy: json['Ten Hoc Ky'] ?? '',
        maSinhVien: json['Ma Sinh Vien'] ?? '',
        tongMon: json['TongMon'] ?? 0,
        soA: json['So_A'] ?? 0,
        soBPlus: json['So_B+'] ?? 0,
        soB: json['So_B'] ?? 0,
        soCPlus: json['So_C+'] ?? 0,
        soC: json['So_C'] ?? 0,
        soDPlus: json['So_D+'] ?? 0,
        soD: json['So_D'] ?? 0,
        soF: json['So_F'] ?? 0,
        tyLeA: (json['TyLe_A'] ?? 0.0).toDouble(),
        tyLeBPlus: (json['TyLe_B+'] ?? 0.0).toDouble(),
        tyLeB: (json['TyLe_B'] ?? 0.0).toDouble(),
        tyLeCPlus: (json['TyLe_C+'] ?? 0.0).toDouble(),
        tyLeC: (json['TyLe_C'] ?? 0.0).toDouble(),
        tyLeDPlus: (json['TyLe_D+'] ?? 0.0).toDouble(),
        tyLeD: (json['TyLe_D'] ?? 0.0).toDouble(),
        tyLeF: (json['TyLe_F'] ?? 0.0).toDouble(),
        isNewFormat: false,
      );
    }
  }

  // Tính tỷ lệ Giỏi (A, B+) - từ format cũ hoặc format mới
  double get tyLeGioi => isNewFormat ? (tyLeGioiNew ?? 0.0) : (tyLeA + tyLeBPlus);
  
  // Tính tỷ lệ Khá (B, C+) - từ format cũ hoặc format mới
  double get tyLeKha => isNewFormat ? (tyLeKhaNew ?? 0.0) : (tyLeB + tyLeCPlus);
  
  // Tính tỷ lệ Trung bình (C, D+) - từ format cũ hoặc format mới
  double get tyLeTb => isNewFormat ? (tyLeTbNew ?? 0.0) : (tyLeC + tyLeDPlus);
  
  // Tính tỷ lệ Yếu (D, F) - từ format cũ hoặc format mới
  double get tyLeYeu => isNewFormat ? (tyLeYeuNew ?? 0.0) : (tyLeD + tyLeF);

  // Tính số lượng Giỏi
  int get soGioi => soA + soBPlus;
  
  // Tính số lượng Khá
  int get soKha => soB + soCPlus;
  
  // Tính số lượng Trung bình
  int get soTb => soC + soDPlus;
  
  // Tính số lượng Yếu
  int get soYeu => soD + soF;
}

// Credit Response Model
class CreditResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String hoTen;
  final String maSinhVien;
  final int tongTinChi;

  CreditResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.hoTen,
    required this.maSinhVien,
    required this.tongTinChi,
  });

  factory CreditResponse.fromJson(Map<String, dynamic> json) {
    return CreditResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      hoTen: json['Ho Ten'] ?? '',
      maSinhVien: json['Ma Sinh Vien'] ?? '',
      tongTinChi: json['TongTinChi'] ?? 0,
    );
  }
}

// Prediction API Response
class PredictionApiService {
  static const String baseUrl = ApiService.baseUrl;

  // Helper method to get headers with auth token
  static Future<Map<String, String>> getHeaders() async {
    final accessToken = await AuthService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Không có access token. Vui lòng đăng nhập lại.');
    }
    
    final cleanToken = accessToken.trim();
    final headers = ApiService.getHeaders(accessToken: cleanToken);
    headers['ngrok-skip-browser-warning'] = 'true';
    
    return headers;
  }

  // GET /dudoan/sac-suat-dat-loai-khi-tot-nghiep
  static Future<PredictionResponse> getPredictionGraduation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dudoan/sac-suat-dat-loai-khi-tot-nghiep'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return PredictionResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // GET /dudoan/du-doan-hoc-ky-toi
  static Future<PredictionNextSemesterResponse> getPredictionNextSemester() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dudoan/du-doan-hoc-ky-toi'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return PredictionNextSemesterResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // GET /dudoan/predict-my-next-cohort
  static Future<PredictionSubjectsResponse> getPredictionSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dudoan/predict-my-next-cohort'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return PredictionSubjectsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('401: Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        throw Exception('404: Không tìm thấy dữ liệu.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: ${e.toString()}');
    }
  }

  // Giữ lại method cũ để tương thích ngược
  static Future<PredictionResponse> getPrediction() async {
    return getPredictionGraduation();
  }
}
