import 'package:flutter/foundation.dart';
import '../models/teacher_advisor.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import 'teacher_api_service.dart';
import 'auth_service.dart';

class TeacherDataService {
  // Load tất cả dữ liệu từ API và tạo cấu trúc TeacherAdvisor
  static Future<TeacherAdvisor> loadTeacherData() async {
    // Kiểm tra access token trước khi gọi API
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Không có access token. Vui lòng đăng nhập lại.');
    }

    try {
      // Load dữ liệu với error handling riêng cho từng API
      TeacherInfoResponse? teacherInfo;
      List<ClassStudentCountResponse> classStudentCounts = [];
      List<ClassGenderCountResponse> classGenderCounts = [];
      TotalStudentsResponse? totalStudents;
      List<ClassSemesterGPAResponse> classSemesterGPAs = [];
      List<ClassOverallGPAResponse> classOverallGPAs = [];
      List<ClassGPATrendResponse> classGPATrends = [];
      List<ClassSubjectGPAResponse> classSubjectGPAs = [];
      List<ClassPassFailRateResponse> classPassFailRates = [];
      List<SubjectPassFailRateResponse> subjectPassFailRates = [];
      List<SubjectFailRateHighResponse> subjectFailRateHighs = [];
      List<SubjectFailRateLowResponse> subjectFailRateLows = [];
      List<ClassAcademicLevelResponse> classAcademicLevels = [];
      List<SubjectGPAComparisonResponse> subjectGPAComparisons = [];
      List<SubjectGradeDistributionResponse> subjectGradeDistributions = [];
      List<SubjectPassFailRateBySemesterResponse> subjectPassFailRatesBySemester = [];
      List<StudentFailCountBySemesterResponse> studentFailCountsBySemester = [];
      List<ClassGPAConductCorrelationResponse> classGPAConductCorrelations = [];
      List<StudentGPAByClassResponse> studentGPAs = [];
      List<TeacherAdvisorBySemesterResponse> teacherAdvisorBySemesters = [];

      // Load từng API riêng biệt để xử lý lỗi tốt hơn
      try {
        teacherInfo = await TeacherApiService.getTeacherInfo();
        debugPrint('✓ Successfully loaded teacher info');
      } catch (e) {
        debugPrint('✗ Error loading teacher info: $e');
        final errorMsg = e.toString();
        if (errorMsg.contains('404')) {
          debugPrint('Teacher info API returned 404, continuing with other APIs...');
        } else if (!errorMsg.contains('401')) {
          // Không throw nếu không phải 401, tiếp tục với các API khác
        } else {
          throw Exception('Không thể tải thông tin giảng viên: ${errorMsg.replaceAll('Exception: ', '')}');
        }
      }

      // Load các API khác
      try {
        classStudentCounts = await TeacherApiService.getClassStudentCounts();
        debugPrint('✓ Successfully loaded class student counts: ${classStudentCounts.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class student counts: $e');
        classStudentCounts = [];
      }

      try {
        classGenderCounts = await TeacherApiService.getClassGenderCounts();
        debugPrint('✓ Successfully loaded class gender counts: ${classGenderCounts.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class gender counts: $e');
        classGenderCounts = [];
      }

      try {
        totalStudents = await TeacherApiService.getTotalStudents();
        debugPrint('✓ Successfully loaded total students: ${totalStudents.tongSoSinhVien}');
      } catch (e) {
        // API này có thể trả về 404 nếu không có dữ liệu, không cần log lỗi
        // Tổng số sinh viên sẽ được tính từ classStudentCounts
        if (kDebugMode && !e.toString().contains('404')) {
          debugPrint('✗ Error loading total students: $e');
        }
      }

      try {
        classSemesterGPAs = await TeacherApiService.getClassSemesterGPA();
        debugPrint('✓ Successfully loaded class semester GPAs: ${classSemesterGPAs.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class semester GPAs: $e');
        classSemesterGPAs = [];
      }

      try {
        classOverallGPAs = await TeacherApiService.getClassOverallGPA();
        debugPrint('✓ Successfully loaded class overall GPAs: ${classOverallGPAs.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class overall GPAs: $e');
        classOverallGPAs = [];
      }

      try {
        classGPATrends = await TeacherApiService.getClassGPATrend();
        debugPrint('✓ Successfully loaded class GPA trends: ${classGPATrends.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class GPA trends: $e');
        classGPATrends = [];
      }

      try {
        classSubjectGPAs = await TeacherApiService.getClassSubjectGPA();
        debugPrint('✓ Successfully loaded class subject GPAs: ${classSubjectGPAs.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class subject GPAs: $e');
        classSubjectGPAs = [];
      }

      try {
        classPassFailRates = await TeacherApiService.getClassPassFailRate();
        debugPrint('✓ Successfully loaded class pass/fail rates: ${classPassFailRates.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class pass/fail rates: $e');
        classPassFailRates = [];
      }

      try {
        subjectPassFailRates = await TeacherApiService.getSubjectPassFailRate();
        debugPrint('✓ Successfully loaded subject pass/fail rates: ${subjectPassFailRates.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject pass/fail rates: $e');
        subjectPassFailRates = [];
      }

      try {
        subjectFailRateHighs = await TeacherApiService.getSubjectFailRateHigh();
        debugPrint('✓ Successfully loaded subject fail rate high: ${subjectFailRateHighs.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject fail rate high: $e');
        subjectFailRateHighs = [];
      }

      try {
        subjectFailRateLows = await TeacherApiService.getSubjectFailRateLow();
        debugPrint('✓ Successfully loaded subject fail rate low: ${subjectFailRateLows.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject fail rate low: $e');
        subjectFailRateLows = [];
      }

      try {
        subjectGPAComparisons = await TeacherApiService.getSubjectGPAComparison();
        debugPrint('✓ Successfully loaded subject GPA comparisons: ${subjectGPAComparisons.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject GPA comparisons: $e');
        subjectGPAComparisons = [];
      }

      try {
        classAcademicLevels = await TeacherApiService.getClassAcademicLevel();
        debugPrint('✓ Successfully loaded class academic levels: ${classAcademicLevels.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class academic levels: $e');
        classAcademicLevels = [];
      }

      try {
        subjectGradeDistributions = await TeacherApiService.getSubjectGradeDistribution();
        debugPrint('✓ Successfully loaded subject grade distributions: ${subjectGradeDistributions.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject grade distributions: $e');
        subjectGradeDistributions = [];
      }

      try {
        subjectPassFailRatesBySemester = await TeacherApiService.getSubjectPassFailRateBySemester();
        debugPrint('✓ Successfully loaded subject pass/fail rates by semester: ${subjectPassFailRatesBySemester.length} items');
      } catch (e) {
        debugPrint('✗ Error loading subject pass/fail rates by semester: $e');
        subjectPassFailRatesBySemester = [];
      }

      try {
        studentFailCountsBySemester = await TeacherApiService.getStudentFailCountBySemester();
        debugPrint('✓ Successfully loaded student fail counts by semester: ${studentFailCountsBySemester.length} items');
      } catch (e) {
        debugPrint('✗ Error loading student fail counts by semester: $e');
        studentFailCountsBySemester = [];
      }

      try {
        classGPAConductCorrelations = await TeacherApiService.getClassGPAConductCorrelation();
        debugPrint('✓ Successfully loaded class GPA-conduct correlations: ${classGPAConductCorrelations.length} items');
      } catch (e) {
        debugPrint('✗ Error loading class GPA-conduct correlations: $e');
        classGPAConductCorrelations = [];
      }

      try {
        studentGPAs = await TeacherApiService.getStudentGPAByClass();
        debugPrint('✓ Successfully loaded student GPAs: ${studentGPAs.length} items');
      } catch (e) {
        debugPrint('✗ Error loading student GPAs: $e');
        studentGPAs = [];
      }

      try {
        teacherAdvisorBySemesters = await TeacherApiService.getTeacherAdvisorBySemester();
        debugPrint('✓ Successfully loaded teacher advisor by semesters: ${teacherAdvisorBySemesters.length} items');
      } catch (e) {
        debugPrint('✗ Error loading teacher advisor by semesters: $e');
        teacherAdvisorBySemesters = [];
      }

      // Kiểm tra xem có đủ dữ liệu để tạo TeacherAdvisor không
      debugPrint('=== Data Summary ===');
      debugPrint('Teacher Info: ${teacherInfo != null ? "✓" : "✗"}');
      debugPrint('Class Student Counts: ${classStudentCounts.length} items');
      debugPrint('Class Gender Counts: ${classGenderCounts.length} items');
      debugPrint('Class Semester GPAs: ${classSemesterGPAs.length} items');
      debugPrint('Teacher Advisor By Semesters: ${teacherAdvisorBySemesters.length} items');
      debugPrint('===================');

      if (teacherAdvisorBySemesters.isEmpty && classStudentCounts.isEmpty) {
        throw Exception('Không có dữ liệu lớp học. Có thể tài khoản của bạn chưa có dữ liệu. Vui lòng liên hệ quản trị viên để được hỗ trợ.');
      }

      // Nếu không có teacherInfo, tạo một TeacherInfoResponse mặc định
      TeacherInfoResponse finalTeacherInfo;
      if (teacherInfo == null) {
        debugPrint('Warning: Teacher info is null, using default values');
        final userInfo = await AuthService.getUserInfo();
        finalTeacherInfo = TeacherInfoResponse(
          hoTen: userInfo?.hoTen ?? 'N/A',
          maGiaoVien: userInfo?.username ?? 'N/A',
          soLopPhuTrach: 0,
        );
      } else {
        finalTeacherInfo = teacherInfo;
      }

      // Tạo map để dễ truy cập
      final classStudentCountMap = <String, int>{};
      // Tính tổng số sinh viên từ API Tong-So-Sinh-Vien-Theo-Lop
      int totalStudentsFromAPI = 0;
      for (var count in classStudentCounts) {
        classStudentCountMap[count.tenLop] = count.tongSv;
        totalStudentsFromAPI += count.tongSv;
      }

      final classGenderCountMap = <String, ClassGenderCountResponse>{};
      // Tạo map để lưu gender count theo lớp (dùng trong TeacherAdvisor)
      final genderCountByClass = <String, GenderCount>{};
      for (var gender in classGenderCounts) {
        classGenderCountMap[gender.tenLop] = gender;
        genderCountByClass[gender.tenLop] = GenderCount(
          soNam: gender.soNam,
          soNu: gender.soNu,
        );
      }

      final classOverallGPAMap = <String, double>{};
      for (var gpa in classOverallGPAs) {
        classOverallGPAMap[gpa.tenLop] = gpa.gpa;
      }

      // Tạo map cho semester data theo lớp và học kỳ
      final classSemesterGPAMap = <String, List<ClassSemesterGPAResponse>>{};
      for (var gpa in classSemesterGPAs) {
        classSemesterGPAMap.putIfAbsent(gpa.tenLop, () => []).add(gpa);
      }

      // Tính GPA trung bình theo Ten Nam Hoc + Ten Hoc Ky (khóa chính)
      // Key: "Ten Nam Hoc-Ten Hoc Ky", Value: GPA trung bình
      final averageGPABySemester = <String, double>{};
      final gpaCountBySemester = <String, int>{};
      final gpaSumBySemester = <String, double>{};
      
      for (var gpa in classSemesterGPAs) {
        // Normalize tenHocKy để đảm bảo match
        final normalizedHocKy = _normalizeHocKy(gpa.maHocKy);
        if (normalizedHocKy.isEmpty) continue; // Bỏ qua nếu học kỳ rỗng
        
        final key = '${gpa.tenNamHoc}-$normalizedHocKy';
        gpaSumBySemester[key] = (gpaSumBySemester[key] ?? 0.0) + gpa.gpa;
        gpaCountBySemester[key] = (gpaCountBySemester[key] ?? 0) + 1;
      }
      
      // Tính trung bình
      for (var key in gpaSumBySemester.keys) {
        final count = gpaCountBySemester[key] ?? 1;
        averageGPABySemester[key] = gpaSumBySemester[key]! / count;
      }

      final classPassFailRateMap = <String, List<ClassPassFailRateResponse>>{};
      for (var rate in classPassFailRates) {
        // Normalize tenHocKy để đảm bảo match khi tìm kiếm
        final normalizedTenHocKy = _normalizeHocKy(rate.tenHocKy);
        final key = '${rate.tenLop}-${rate.tenNamHoc}-$normalizedTenHocKy';
        classPassFailRateMap.putIfAbsent(key, () => []).add(rate);
      }

      final classAcademicLevelMap = <String, ClassAcademicLevelResponse>{};
      for (var level in classAcademicLevels) {
        // Normalize tenHocKy để đảm bảo match khi tìm kiếm
        final normalizedTenHocKy = _normalizeHocKy(level.tenHocKy);
        final key = '${level.tenLop}-${level.tenNamHoc}-$normalizedTenHocKy';
        classAcademicLevelMap[key] = level;
      }

      final classSubjectGPAMap = <String, List<ClassSubjectGPAResponse>>{};
      for (var subjectGPA in classSubjectGPAs) {
        // Normalize maHocKy để đảm bảo match khi tìm kiếm
        final normalizedMaHocKy = _normalizeHocKy(subjectGPA.maHocKy);
        final key = '${subjectGPA.tenLop}-${subjectGPA.tenNamHoc}-$normalizedMaHocKy';
        classSubjectGPAMap.putIfAbsent(key, () => []).add(subjectGPA);
      }

      // Tạo map cho subject pass/fail rates (theo lớp và môn học, không cần học kỳ vì API không có)
      final subjectPassFailRateMap = <String, SubjectPassFailRateResponse>{};
      for (var rate in subjectPassFailRates) {
        final key = '${rate.tenLop}-${rate.tenMonHoc}';
        subjectPassFailRateMap[key] = rate;
      }

      final studentGPAMap = <String, List<StudentGPAByClassResponse>>{};
      for (var studentGPA in studentGPAs) {
        final key = '${studentGPA.tenLop}-${studentGPA.tenNamHoc}-${studentGPA.tenHocKy}';
        studentGPAMap.putIfAbsent(key, () => []).add(studentGPA);
      }

      // Tạo danh sách các lớp từ teacherAdvisorBySemesters hoặc classStudentCounts
      final classNames = <String>{};
      for (var advisor in teacherAdvisorBySemesters) {
        classNames.add(advisor.tenLop);
      }
      for (var count in classStudentCounts) {
        classNames.add(count.tenLop);
      }
      // Thêm các lớp từ classGenderCounts để đảm bảo có dữ liệu gender
      for (var gender in classGenderCounts) {
        classNames.add(gender.tenLop);
      }

      // Tạo danh sách các học kỳ từ teacherAdvisorBySemesters
      final semesterKeys = <String>{};
      for (var advisor in teacherAdvisorBySemesters) {
        final key = _createHocKyString(advisor.tenNamHoc, advisor.tenHocKy);
        semesterKeys.add(key);
      }

      // Tạo danh sách lớp
      final classes = <ClassModel>[];
      
      for (var className in classNames) {
        // Lấy thông tin lớp
        final genderCount = classGenderCountMap[className];
        
        // Tạo danh sách học kỳ cho lớp này
        final semesterDataList = <ClassSemesterData>[];
        final classSemesterGPAsForClass = classSemesterGPAMap[className] ?? [];
        
        // Tạo set các học kỳ từ classSemesterGPAs
        final semesterSet = <String>{};
        for (var semesterGPA in classSemesterGPAsForClass) {
          // Normalize maHocKy trước khi tạo key
          final normalizedHocKy = _normalizeHocKy(semesterGPA.maHocKy);
          // Bỏ qua nếu học kỳ rỗng
          if (normalizedHocKy.isEmpty) continue;
          final key = _createHocKyString(semesterGPA.tenNamHoc, normalizedHocKy);
          semesterSet.add(key);
        }
        
        // Thêm các học kỳ từ teacherAdvisorBySemesters
        for (var advisor in teacherAdvisorBySemesters) {
          if (advisor.tenLop == className) {
            // Normalize tenHocKy trước khi tạo key
            final normalizedHocKy = _normalizeHocKy(advisor.tenHocKy);
            // Bỏ qua nếu học kỳ rỗng
            if (normalizedHocKy.isEmpty) continue;
            final key = _createHocKyString(advisor.tenNamHoc, normalizedHocKy);
            semesterSet.add(key);
          }
        }

        // Tạo ClassSemesterData cho từng học kỳ
        for (var semesterKey in semesterSet) {
          final parts = semesterKey.split('-');
          if (parts.length < 3) continue;
          
          final maHocKy = parts[0];
          // Bỏ qua nếu học kỳ rỗng
          if (maHocKy.isEmpty) continue;
          
          final tenNamHoc = '${parts[1]}-${parts[2]}';
          final hocKySo = _extractHocKySo(maHocKy);
          final namHoc = _extractNamHoc(parts[1]);

          // Tìm GPA cho học kỳ này (so sánh với normalized maHocKy)
          double gpa = 0.0;
          final normalizedMaHocKy = _normalizeHocKy(maHocKy);
          for (var semesterGPA in classSemesterGPAsForClass) {
            final normalizedSemesterHocKy = _normalizeHocKy(semesterGPA.maHocKy);
            if (semesterGPA.tenNamHoc == tenNamHoc && normalizedSemesterHocKy == normalizedMaHocKy) {
              gpa = semesterGPA.gpa;
              break;
            }
          }

          // Tìm pass rate (sử dụng normalized maHocKy)
          final passFailKey = '$className-$tenNamHoc-$normalizedMaHocKy';
          final passFailRates = classPassFailRateMap[passFailKey] ?? [];
          double passRate = 0.0;
          if (passFailRates.isNotEmpty) {
            final rate = passFailRates.first;
            passRate = (rate.tyLeDau ?? 0.0) * 100; // Convert to percentage
          }
          
          // Debug log để kiểm tra (chỉ log khi thực sự cần thiết)
          if (kDebugMode && passFailRates.isEmpty && normalizedMaHocKy.isNotEmpty) {
            // Chỉ log warning nếu học kỳ không rỗng và không tìm thấy dữ liệu
            final availableKeys = classPassFailRateMap.keys.where((k) => k.startsWith(className)).toList();
            if (availableKeys.isNotEmpty) {
              debugPrint('⚠ No pass/fail rate found for key: $passFailKey');
              debugPrint('   Class: $className, NamHoc: $tenNamHoc, HocKy: $normalizedMaHocKy');
              debugPrint('   Available keys for this class: $availableKeys');
            }
          }

          // Tìm academic levels (sử dụng normalized hocKy)
          final academicKey = '$className-$tenNamHoc-$normalizedMaHocKy';
          final academicLevel = classAcademicLevelMap[academicKey];
          final academicLevels = <String, double>{
            'Xuất sắc': (academicLevel?.tlXuatSac ?? 0.0) * 100,
            'Giỏi': (academicLevel?.tlGioi ?? 0.0) * 100,
            'Khá': (academicLevel?.tlKha ?? 0.0) * 100,
            'Trung bình': (academicLevel?.tlTb ?? 0.0) * 100,
            'Yếu': (academicLevel?.tlYeu ?? 0.0) * 100,
            'Kém': (academicLevel?.tlKem ?? 0.0) * 100,
          };

          // Tìm subject GPAs (sử dụng normalized maHocKy)
          final subjectGPAKey = '$className-$tenNamHoc-$normalizedMaHocKy';
          final subjectGPAs = classSubjectGPAMap[subjectGPAKey] ?? [];
          final subjectGPAMap = <String, double>{};
          final subjectPassRateMap = <String, double>{};
          for (var subjectGPA in subjectGPAs) {
            subjectGPAMap[subjectGPA.tenMonHoc] = subjectGPA.gpa;
            // Tìm pass rate cho môn học này (theo lớp và môn học)
            final passFailKey = '$className-${subjectGPA.tenMonHoc}';
            final passFailRate = subjectPassFailRateMap[passFailKey];
            if (passFailRate != null) {
              subjectPassRateMap[subjectGPA.tenMonHoc] = passFailRate.tyLeDau * 100;
            } else {
              subjectPassRateMap[subjectGPA.tenMonHoc] = 0.0;
            }
          }
          
          // Debug log để kiểm tra (chỉ log khi thực sự cần thiết)
          if (kDebugMode && subjectGPAs.isEmpty && normalizedMaHocKy.isNotEmpty) {
            // Chỉ log warning nếu học kỳ không rỗng và không tìm thấy dữ liệu
            final availableKeys = classSubjectGPAMap.keys.where((k) => k.startsWith(className)).toList();
            if (availableKeys.isNotEmpty) {
              debugPrint('⚠ No subject GPA found for key: $subjectGPAKey');
              debugPrint('   Class: $className, NamHoc: $tenNamHoc, HocKy: $normalizedMaHocKy');
              debugPrint('   Available keys for this class: $availableKeys');
            }
          }

          // Tìm số lượng sinh viên trong kỳ này
          int? totalStudentsInSemester;
          int? maleCountInSemester;
          int? femaleCountInSemester;
          
          for (var advisor in teacherAdvisorBySemesters) {
            final normalizedAdvisorHocKy = _normalizeHocKy(advisor.tenHocKy);
            if (advisor.tenLop == className && 
                advisor.tenNamHoc == tenNamHoc && 
                normalizedAdvisorHocKy == normalizedMaHocKy) {
              totalStudentsInSemester = advisor.factHocTapCount;
              break;
            }
          }

          // Nếu không tìm thấy, dùng gender count
          if (totalStudentsInSemester == null && genderCount != null) {
            totalStudentsInSemester = genderCount.soNam + genderCount.soNu;
            maleCountInSemester = genderCount.soNam;
            femaleCountInSemester = genderCount.soNu;
          }

          semesterDataList.add(ClassSemesterData(
            hocKy: semesterKey,
            namHoc: namHoc,
            hocKySo: hocKySo,
            gpa: gpa,
            passRate: passRate,
            academicLevels: academicLevels,
            subjectGPA: subjectGPAMap,
            subjectPassRate: subjectPassRateMap,
            totalStudents: totalStudentsInSemester,
            maleCount: maleCountInSemester,
            femaleCount: femaleCountInSemester,
          ));
        }

        // Tạo danh sách sinh viên (có thể cần API riêng, tạm thời tạo empty)
        final students = <StudentModel>[];
        // Có thể sử dụng studentGPAs để tạo danh sách sinh viên
        for (var studentGPA in studentGPAs) {
          if (studentGPA.tenLop == className) {
            students.add(StudentModel(
              maSinhVien: '', // API không có
              hoTen: studentGPA.hoTen,
              gioiTinh: 'Nam', // API không có, mặc định
              diemRenLuyen: 0.0, // Có thể lấy từ classGPAConductCorrelations
              gpa: studentGPA.gpaHocKy,
            ));
          }
        }

        // Extract năm học và khóa từ tên lớp (ví dụ: "12DHTH07" -> năm học 2021, khóa 2021)
        final namHoc = _extractNamHocFromClassName(className);
        final khoa = namHoc;

        // Lấy tổng số sinh viên từ API
        final totalStudentsFromAPI = classStudentCountMap[className];

        classes.add(ClassModel(
          maLop: className,
          tenLop: className,
          namHoc: namHoc,
          khoa: khoa,
          students: students,
          semesterData: semesterDataList,
          totalStudentsCount: totalStudentsFromAPI,
        ));
      }

      // Sắp xếp classes theo tên lớp
      classes.sort((a, b) => a.tenLop.compareTo(b.tenLop));

      // Tạo TeacherAdvisor
      return TeacherAdvisor(
        academicLevelsByClass: classAcademicLevels,
        maGiangVien: finalTeacherInfo.maGiaoVien,
        hoTen: finalTeacherInfo.hoTen,
        classes: classes,
        soLopPhuTrach: finalTeacherInfo.soLopPhuTrach,
        totalStudentsFromAPI: totalStudentsFromAPI > 0 ? totalStudentsFromAPI : null,
        genderCountByClass: genderCountByClass.isNotEmpty ? genderCountByClass : null,
        gpaTrendByClass: classGPATrends.isNotEmpty ? classGPATrends : null,
        subjectFailRateHighs: subjectFailRateHighs.isNotEmpty ? subjectFailRateHighs : null,
        subjectFailRateLows: subjectFailRateLows.isNotEmpty ? subjectFailRateLows : null,
        subjectGPAsByClass: classSubjectGPAs.isNotEmpty ? classSubjectGPAs : null,
        subjectGPAComparisons: subjectGPAComparisons.isNotEmpty ? subjectGPAComparisons : null,
        subjectGradeDistributions: subjectGradeDistributions.isNotEmpty ? subjectGradeDistributions : null,
        subjectPassFailRatesBySemester: subjectPassFailRatesBySemester.isNotEmpty ? subjectPassFailRatesBySemester : null,
        classOverallGPAs: classOverallGPAs.isNotEmpty ? classOverallGPAs : null,
        studentFailCountsBySemester: studentFailCountsBySemester.isNotEmpty ? studentFailCountsBySemester : null,
        classPassFailRates: classPassFailRates.isNotEmpty ? classPassFailRates : null,
        teacherAdvisorBySemesters: teacherAdvisorBySemesters.isNotEmpty ? teacherAdvisorBySemesters : null,
        averageGPABySemester: averageGPABySemester.isNotEmpty ? averageGPABySemester : null,
      );
    } catch (e) {
      throw Exception('Lỗi load dữ liệu giảng viên: ${e.toString()}');
    }
  }

  // Helper methods
  static String _createHocKyString(String tenNamHoc, String tenHocKy) {
    // Normalize tenHocKy: "HK_1" -> "HK1", "HK_3" -> "HK3", "HK3" -> "HK3"
    final normalizedHocKy = _normalizeHocKy(tenHocKy);
    
    // "2024-2025" + "HK1" -> "HK1-2024-2025"
    final parts = tenNamHoc.split('-');
    if (parts.length >= 2) {
      return '$normalizedHocKy-${parts[0]}-${parts[1]}';
    }
    return '$normalizedHocKy-$tenNamHoc';
  }

  // Normalize học kỳ string: "HK_1" -> "HK1", "HK_3" -> "HK3"
  static String _normalizeHocKy(String hocKy) {
    // Xử lý null hoặc empty string
    if (hocKy.isEmpty || hocKy.trim().isEmpty) {
      return '';
    }
    
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    // Nếu đã là format "HK1", "HK2", etc thì giữ nguyên
    return hocKy;
  }

  static int _extractNamHoc(String namHocStr) {
    final parts = namHocStr.split('-');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return 0;
  }

  static int _extractHocKySo(String maHocKy) {
    // "HK_1" -> 1, "HK_2" -> 2, "HK1" -> 1
    if (maHocKy.contains('_')) {
      final parts = maHocKy.split('_');
      if (parts.length > 1) {
        return int.tryParse(parts[1]) ?? 1;
      }
    } else if (maHocKy.length >= 3) {
      final so = maHocKy.substring(2);
      return int.tryParse(so) ?? 1;
    }
    return 1;
  }

  static int _extractNamHocFromClassName(String className) {
    // "12DHTH07" -> 2021 (12 là năm vào học, + 9 = 2021)
    // Hoặc có thể parse từ "12" -> 2012 + 9 = 2021
    if (className.length >= 2) {
      final yearPrefix = className.substring(0, 2);
      final year = int.tryParse(yearPrefix);
      if (year != null) {
        // Giả sử "12" là năm 2012, nhưng thực tế có thể là 2021-2025
        // Cần điều chỉnh theo logic thực tế
        return 2000 + year;
      }
    }
    return 2021; // Default
  }
}

