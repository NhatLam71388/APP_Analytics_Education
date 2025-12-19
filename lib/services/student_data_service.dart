import 'package:flutter/foundation.dart';
import 'package:study_analytics/services/teacher_api_service.dart';
import '../models/student_academic.dart';
import '../models/semester.dart';
import '../models/subject.dart';
import 'student_api_service.dart';
import 'teacher_api_service.dart';
import 'auth_service.dart';

class StudentDataService {
  // Load tất cả dữ liệu từ API và tạo cấu trúc StudentAcademic
  static Future<StudentAcademic> loadStudentData() async {
    // Kiểm tra access token trước khi gọi API
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Không có access token. Vui lòng đăng nhập lại.');
    }

    try {
      // Load dữ liệu với error handling riêng cho từng API
      // Nếu một API fail, vẫn tiếp tục với các API khác
      StudentInfoResponse? studentInfo;
      List<GPATrendResponse> gpaTrends = [];
      List<ConductScoreResponse> conductScores = [];
      List<SubjectBySemesterResponse> subjectsBySemester = [];
      List<SubjectDetailResponse> subjectDetails = [];
      List<SemesterGPAResponse> semesterGPAs = [];
      List<PassRateBySemesterResponse> passRates = [];
      List<SubjectComparisonResponse> subjectComparisons = [];
      List<HighestScoreResponse> highestScores = [];
      List<LowestScoreResponse> lowestScores = [];
      List<SubjectGradeRateResponse> subjectGradeRates = [];
      OverallGPAResponse? overallGPA;
      SemesterCountResponse? semesterCount;

      // Load từng API riêng biệt để xử lý lỗi tốt hơn
      try {
        studentInfo = await StudentApiService.getStudentInfo();
        debugPrint('✓ Successfully loaded student info');
      } catch (e) {
        debugPrint('✗ Error loading student info: $e');
        final errorMsg = e.toString();
        if (errorMsg.contains('404')) {
          debugPrint('Student info API returned 404, continuing with other APIs...');
        } else if (!errorMsg.contains('401')) {
          // Không throw nếu không phải 401, tiếp tục với các API khác
        } else {
          throw Exception('Không thể tải thông tin sinh viên: ${errorMsg.replaceAll('Exception: ', '')}');
        }
      }

      // Load số học kỳ
      try {
        semesterCount = await StudentApiService.getSemesterCount();
        debugPrint('✓ Successfully loaded semester count: ${semesterCount.soKyHoc}');
      } catch (e) {
        debugPrint('✗ Error loading semester count: $e');
      }

      // Load các API khác, nếu fail thì dùng giá trị mặc định
      try {
        gpaTrends = await StudentApiService.getGPATrend();
        debugPrint('✓ Successfully loaded GPA trends: ${gpaTrends.length} items');
      } catch (e) {
        debugPrint('✗ Error loading GPA trend: $e');
        gpaTrends = [];
      }

      try {
        conductScores = await StudentApiService.getConductScores();
        debugPrint('✓ Successfully loaded conduct scores: ${conductScores.length} items');
      } catch (e) {
        debugPrint('✗ Error loading conduct scores: $e');
        conductScores = [];
      }

      try {
        subjectsBySemester = await StudentApiService.getSubjectsBySemester();
        debugPrint('✓ Successfully loaded subjects by semester: ${subjectsBySemester.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subjects by semester: $e');
        subjectsBySemester = [];
      }

      try {
        subjectDetails = await StudentApiService.getSubjectDetails();
        debugPrint('✓ Successfully loaded subject details: ${subjectDetails.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject details: $e');
        subjectDetails = [];
      }

      try {
        semesterGPAs = await StudentApiService.getSemesterGPA();
        debugPrint('✓ Successfully loaded semester GPAs: ${semesterGPAs.length} items');
      } catch (e) {
        debugPrint('✗ Error loading semester GPAs: $e');
        semesterGPAs = [];
      }

      try {
        passRates = await StudentApiService.getPassRateBySemester();
        debugPrint('✓ Successfully loaded pass rates: ${passRates.length} items');
      } catch (e) {
        debugPrint('✗ Error loading pass rates: $e');
        passRates = [];
      }

      try {
        subjectComparisons = await StudentApiService.getSubjectComparison();
        debugPrint('✓ Successfully loaded subject comparisons: ${subjectComparisons.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject comparison: $e');
        subjectComparisons = [];
      }

      try {
        highestScores = await StudentApiService.getHighestScores();
        debugPrint('✓ Successfully loaded highest scores: ${highestScores.length} items');
      } catch (e) {
        debugPrint('✗ Error loading highest scores: $e');
        highestScores = [];
      }

      try {
        lowestScores = await StudentApiService.getLowestScores();
        debugPrint('✓ Successfully loaded lowest scores: ${lowestScores.length} items');
      } catch (e) {
        debugPrint('✗ Error loading lowest scores: $e');
        lowestScores = [];
      }

      try {
        subjectGradeRates = await StudentApiService.getSubjectGradeRate();
        debugPrint('✓ Successfully loaded subject grade rates: ${subjectGradeRates.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject grade rate: $e');
        subjectGradeRates = [];
      }

      try {
        overallGPA = await StudentApiService.getOverallGPA();
        debugPrint('✓ Successfully loaded overall GPA: ${overallGPA.gpaToanKhoa}');
      } catch (e) {
        debugPrint('✗ Error loading overall GPA: $e');
      }

      // Kiểm tra xem có đủ dữ liệu để tạo StudentAcademic không
      debugPrint('=== Data Summary ===');
      debugPrint('Student Info: ${studentInfo != null ? "✓" : "✗"}');
      debugPrint('GPA Trends: ${gpaTrends.length} items');
      debugPrint('Conduct Scores: ${conductScores.length} items');
      debugPrint('Subjects by Semester: ${subjectsBySemester.length} items');
      debugPrint('Subject Details: ${subjectDetails.length} items');
      debugPrint('Semester GPAs: ${semesterGPAs.length} items');
      debugPrint('Pass Rates: ${passRates.length} items');
      debugPrint('Subject Comparisons: ${subjectComparisons.length} items');
      debugPrint('===================');

      if (gpaTrends.isEmpty && semesterGPAs.isEmpty) {
        throw Exception('Không có dữ liệu học kỳ. Có thể tài khoản của bạn chưa có dữ liệu học tập. Vui lòng liên hệ quản trị viên để được hỗ trợ.');
      }

      // Nếu không có studentInfo, tạo một StudentInfoResponse mặc định
      StudentInfoResponse finalStudentInfo;
      if (studentInfo == null) {
        debugPrint('Warning: Student info is null, using default values');
        final userInfo = await AuthService.getUserInfo();
        finalStudentInfo = StudentInfoResponse(
          maSinhVien: userInfo?.username ?? 'N/A',
          hoTen: userInfo?.username ?? 'N/A',
          tenLop: 'N/A',
          tenKhuVuc: 'N/A',
          factHocTapCount: 0,
        );
      } else {
        finalStudentInfo = studentInfo;
      }

      // Tạo map để dễ truy cập
      final gpaMap = <String, double>{};
      for (var trend in gpaTrends) {
        final key = '${trend.tenNamHoc}-${trend.tenHocKy}';
        gpaMap[key] = trend.gpa;
      }

      // Thêm GPA từ semesterGPAs nếu có
      for (var semesterGPA in semesterGPAs) {
        final key = '${semesterGPA.tenNamHoc}-${semesterGPA.tenHocKy}';
        if (!gpaMap.containsKey(key)) {
          gpaMap[key] = semesterGPA.gpaHocKy;
        }
      }

      final conductMap = <String, double>{};
      for (var conduct in conductScores) {
        final key = '${conduct.tenNamHoc}-${conduct.tenHocKy}';
        conductMap[key] = conduct.drl;
      }

      final xepLoaiMap = <String, String>{};
      for (var semesterGPA in semesterGPAs) {
        final key = '${semesterGPA.tenNamHoc}-${semesterGPA.tenHocKy}';
        xepLoaiMap[key] = semesterGPA.loaiHocLuc;
      }

      final passRateMap = <String, PassRateBySemesterResponse>{};
      for (var passRate in passRates) {
        final key = '${passRate.tenNamHoc}-${passRate.tenHocKy}';
        passRateMap[key] = passRate;
      }

      final subjectComparisonMap = <String, SubjectComparisonResponse>{};
      for (var comp in subjectComparisons) {
        subjectComparisonMap[comp.tenMonHoc] = comp;
      }

      // Tạo map cho subject details (điểm chi tiết)
      final subjectDetailMap = <String, SubjectDetailResponse>{};
      for (var detail in subjectDetails) {
        final key = '${detail.tenNamHoc}-${detail.tenHocKy}-${detail.tenMonHoc}';
        subjectDetailMap[key] = detail;
      }

      // Tạo map cho subjects by semester
      final subjectsBySemesterMap = <String, List<SubjectBySemesterResponse>>{};
      for (var subject in subjectsBySemester) {
        final key = '${subject.tenNamHoc}-${subject.tenHocKy}';
        subjectsBySemesterMap.putIfAbsent(key, () => []).add(subject);
      }

      // Tạo danh sách học kỳ từ GPA trends hoặc semester GPAs
      final semesters = <Semester>[];
      final semesterKeys = <String>{};
      
      // Thu thập tất cả các học kỳ từ các nguồn dữ liệu
      for (var trend in gpaTrends) {
        final key = '${trend.tenNamHoc}-${trend.tenHocKy}';
        semesterKeys.add(key);
      }
      for (var semesterGPA in semesterGPAs) {
        final key = '${semesterGPA.tenNamHoc}-${semesterGPA.tenHocKy}';
        semesterKeys.add(key);
      }

      // Tạo từng học kỳ
      for (var key in semesterKeys) {
        final parts = key.split('-');
        if (parts.length < 2) continue;
        
        final tenNamHoc = '${parts[0]}-${parts[1]}';
        final tenHocKy = parts.length > 2 ? parts.sublist(2).join('-') : 'HK1';
        
        // Tạo hocKy string
        final hocKy = _createHocKyString(tenNamHoc, tenHocKy);
        final namHoc = _extractNamHoc(tenNamHoc);
        final hocKySo = _extractHocKySo(tenHocKy);

        // Lấy GPA
        final gpa = gpaMap[key] ?? 0.0;
        
        // Lấy xếp loại
        final xepLoai = xepLoaiMap[key] ?? _getXepLoaiFromGPA(gpa);
        
        // Lấy điểm rèn luyện
        final diemRenLuyen = conductMap[key] ?? 0.0;

        // Tạo danh sách môn học cho học kỳ này
        final semesterSubjects = subjectsBySemesterMap[key] ?? [];
        final subjects = <Subject>[];
        
        for (var subjectData in semesterSubjects) {
          // Tìm điểm chi tiết nếu có
          final detailKey = '$key-${subjectData.tenMonHoc}';
          final detail = subjectDetailMap[detailKey];
          
          // Tìm điểm trung bình lớp
          final comparison = subjectComparisonMap[subjectData.tenMonHoc];
          
          // Parse số tín chỉ
          final soTinChi = int.tryParse(subjectData.soTinChi) ?? 
                          (detail != null ? int.tryParse(detail.soTinChi) ?? 0 : 0);
          
          // Lấy điểm trung bình
          final diem = subjectData.diemTrungBinh;
          
          // Tạo mã môn từ tên môn
          final maMon = _generateMaMon(subjectData.tenMonHoc);

          subjects.add(Subject(
            maMon: maMon,
            tenMon: subjectData.tenMonHoc,
            diem: diem,
            soTinChi: soTinChi,
            isPassed: diem >= 5.0,
            diemTrungBinhLop: comparison?.dtbAll,
          ));
        }

        semesters.add(Semester(
          hocKy: hocKy,
          namHoc: namHoc,
          hocKySo: hocKySo,
          subjects: subjects,
          gpa: gpa,
          xepLoai: xepLoai,
          diemRenLuyen: diemRenLuyen > 0 ? diemRenLuyen : null,
        ));
      }

      // Sắp xếp semesters theo năm học và học kỳ
      semesters.sort((a, b) {
        if (a.namHoc != b.namHoc) {
          return a.namHoc.compareTo(b.namHoc);
        }
        return a.hocKySo.compareTo(b.hocKySo);
      });

      // Tạo StudentAcademic
      return StudentAcademic(
        maSinhVien: finalStudentInfo.maSinhVien,
        hoTen: finalStudentInfo.hoTen.isNotEmpty 
            ? finalStudentInfo.hoTen 
            : (semesterCount?.hoTen ?? ''),
        lop: finalStudentInfo.tenLop,
        khuVuc: finalStudentInfo.tenKhuVuc,
        semesters: semesters,
      );
    } catch (e) {
      throw Exception('Lỗi load dữ liệu sinh viên: ${e.toString()}');
    }
  }

  // Helper methods
  static String _createHocKyString(String tenNamHoc, String tenHocKy) {
    // Ví dụ: "2024-2025" + "HK1" -> "HK1 - 2024 - 2025"
    final parts = tenNamHoc.split('-');
    if (parts.length >= 2) {
      return '$tenHocKy - ${parts[0]} - ${parts[1]}';
    }
    return '$tenHocKy - $tenNamHoc';
  }

  static int _extractNamHoc(String tenNamHoc) {
    final parts = tenNamHoc.split('-');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return 0;
  }

  static int _extractHocKySo(String tenHocKy) {
    // "HK1" -> 1, "HK2" -> 2
    if (tenHocKy.length >= 3) {
      final so = tenHocKy.substring(2);
      return int.tryParse(so) ?? 1;
    }
    return 1;
  }

  static String _generateMaMon(String tenMon) {
    // Tạo mã môn từ tên môn (có thể cần điều chỉnh)
    final words = tenMon.split(' ');
    if (words.isNotEmpty) {
      return words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    }
    return tenMon.substring(0, tenMon.length > 5 ? 5 : tenMon.length).toUpperCase();
  }

  static String _getXepLoaiFromGPA(double gpa) {
    if (gpa >= 9.0) return 'Xuất sắc';
    if (gpa >= 8.0) return 'Giỏi';
    if (gpa >= 7.0) return 'Khá';
    if (gpa >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  // Load dữ liệu sinh viên từ teacher APIs với masv
  static Future<StudentAcademic> loadStudentDataByMasv(String masv) async {
    // Kiểm tra access token trước khi gọi API
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Không có access token. Vui lòng đăng nhập lại.');
    }

    try {
      // Load dữ liệu với error handling riêng cho từng API
      StudentInfoResponse? studentInfo;
      List<GPATrendResponse> gpaTrends = [];
      List<ConductScoreResponse> conductScores = [];
      List<SubjectDetailResponse> subjectDetails = [];
      List<PassRateBySemesterResponse> passRates = [];
      List<SubjectComparisonResponse> subjectComparisons = [];
      List<SubjectGradeRateResponse> subjectGradeRates = [];
      OverallGPAResponse? overallGPA;

      // Load từng API riêng biệt để xử lý lỗi tốt hơn
      try {
        studentInfo = await TeacherApiService.getStudentInfoByMasv(masv);
        debugPrint('✓ Successfully loaded student info by masv');
      } catch (e) {
        debugPrint('✗ Error loading student info by masv: $e');
        final errorMsg = e.toString();
        if (errorMsg.contains('404')) {
          debugPrint('Student info API returned 404, continuing with other APIs...');
        } else if (!errorMsg.contains('401')) {
          // Không throw nếu không phải 401, tiếp tục với các API khác
        } else {
          throw Exception('Không thể tải thông tin sinh viên: ${errorMsg.replaceAll('Exception: ', '')}');
        }
      }

      // Load các API khác, nếu fail thì dùng giá trị mặc định
      try {
        gpaTrends = await TeacherApiService.getGPATrendByMasv(masv);
        debugPrint('✓ Successfully loaded GPA trends by masv: ${gpaTrends.length} items');
      } catch (e) {
        debugPrint('✗ Error loading GPA trend by masv: $e');
        gpaTrends = [];
      }

      try {
        conductScores = await TeacherApiService.getConductScoresByMasv(masv);
        debugPrint('✓ Successfully loaded conduct scores by masv: ${conductScores.length} items');
      } catch (e) {
        debugPrint('✗ Error loading conduct scores by masv: $e');
        conductScores = [];
      }

      try {
        subjectDetails = await TeacherApiService.getSubjectDetailsByMasv(masv);
        debugPrint('✓ Successfully loaded subject details by masv: ${subjectDetails.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject details by masv: $e');
        subjectDetails = [];
      }

      try {
        passRates = await TeacherApiService.getPassRateByMasv(masv);
        debugPrint('✓ Successfully loaded pass rates by masv: ${passRates.length} items');
      } catch (e) {
        debugPrint('✗ Error loading pass rates by masv: $e');
        passRates = [];
      }

      try {
        subjectComparisons = await TeacherApiService.getSubjectComparisonByMasv(masv);
        debugPrint('✓ Successfully loaded subject comparisons by masv: ${subjectComparisons.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject comparison by masv: $e');
        subjectComparisons = [];
      }

      try {
        subjectGradeRates = await TeacherApiService.getSubjectGradeRateByMasv(masv);
        debugPrint('✓ Successfully loaded subject grade rates by masv: ${subjectGradeRates.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject grade rate by masv: $e');
        subjectGradeRates = [];
      }

      try {
        overallGPA = await TeacherApiService.getOverallGPAByMasv(masv);
        debugPrint('✓ Successfully loaded overall GPA by masv');
      } catch (e) {
        debugPrint('✗ Error loading overall GPA by masv: $e');
      }

      // Xử lý dữ liệu tương tự như loadStudentData
      // Tạo map cho GPA trends
      final gpaMap = <String, double>{};
      for (var trend in gpaTrends) {
        final key = '${trend.tenNamHoc}-${trend.tenHocKy}';
        gpaMap[key] = trend.gpa;
      }

      // Tạo map cho điểm rèn luyện
      final conductMap = <String, double>{};
      for (var conduct in conductScores) {
        final key = '${conduct.tenNamHoc}-${conduct.tenHocKy}';
        conductMap[key] = conduct.drl;
      }

      final passRateMap = <String, PassRateBySemesterResponse>{};
      for (var passRate in passRates) {
        final key = '${passRate.tenNamHoc}-${passRate.tenHocKy}';
        passRateMap[key] = passRate;
      }

      final subjectComparisonMap = <String, SubjectComparisonResponse>{};
      for (var comp in subjectComparisons) {
        subjectComparisonMap[comp.tenMonHoc] = comp;
      }

      // Tạo map cho subject details
      final subjectDetailMap = <String, SubjectDetailResponse>{};
      for (var detail in subjectDetails) {
        final key = '${detail.tenNamHoc}-${detail.tenHocKy}-${detail.tenMonHoc}';
        subjectDetailMap[key] = detail;
      }

      // Tạo danh sách học kỳ từ GPA trends
      final semesters = <Semester>[];
      final semesterKeys = <String>{};
      
      for (var trend in gpaTrends) {
        final key = '${trend.tenNamHoc}-${trend.tenHocKy}';
        semesterKeys.add(key);
      }

      // Tạo từng học kỳ
      for (var key in semesterKeys) {
        final parts = key.split('-');
        if (parts.length < 2) continue;
        
        final tenNamHoc = '${parts[0]}-${parts[1]}';
        final tenHocKy = parts.length > 2 ? parts.sublist(2).join('-') : 'HK1';
        
        final hocKy = _createHocKyString(tenNamHoc, tenHocKy);
        final namHoc = _extractNamHoc(tenNamHoc);
        final hocKySo = _extractHocKySo(tenHocKy);

        final gpa = gpaMap[key] ?? 0.0;
        final xepLoai = overallGPA?.loaiHocLucToanKhoa ?? _getXepLoaiFromGPA(gpa);
        final diemRenLuyen = conductMap[key] ?? 0.0;

        // Tạo danh sách môn học từ subject details
        final subjects = <Subject>[];
        for (var detail in subjectDetails) {
          if (detail.tenNamHoc == tenNamHoc && detail.tenHocKy == tenHocKy) {
            final comparison = subjectComparisonMap[detail.tenMonHoc];
            final soTinChi = int.tryParse(detail.soTinChi) ?? 0;
            final maMon = _generateMaMon(detail.tenMonHoc);

            subjects.add(Subject(
              maMon: maMon,
              tenMon: detail.tenMonHoc,
              diem: detail.diemTrungBinh,
              soTinChi: soTinChi,
              isPassed: detail.diemTrungBinh >= 5.0,
              diemTrungBinhLop: comparison?.dtbAll,
            ));
          }
        }

        semesters.add(Semester(
          hocKy: hocKy,
          namHoc: namHoc,
          hocKySo: hocKySo,
          subjects: subjects,
          gpa: gpa,
          xepLoai: xepLoai,
          diemRenLuyen: diemRenLuyen > 0 ? diemRenLuyen : null,
        ));
      }

      // Sắp xếp semesters theo năm học và học kỳ
      semesters.sort((a, b) {
        if (a.namHoc != b.namHoc) {
          return a.namHoc.compareTo(b.namHoc);
        }
        return a.hocKySo.compareTo(b.hocKySo);
      });

      // Tạo StudentAcademic
      final finalStudentInfo = studentInfo ?? StudentInfoResponse(
        maSinhVien: masv,
        hoTen: '',
        tenLop: '',
        tenKhuVuc: '',
        factHocTapCount: 0,
      );

      return StudentAcademic(
        maSinhVien: finalStudentInfo.maSinhVien,
        hoTen: finalStudentInfo.hoTen.isNotEmpty ? finalStudentInfo.hoTen : '',
        lop: finalStudentInfo.tenLop,
        khuVuc: finalStudentInfo.tenKhuVuc,
        semesters: semesters,
      );
    } catch (e) {
      throw Exception('Lỗi load dữ liệu sinh viên: ${e.toString()}');
    }
  }
}
