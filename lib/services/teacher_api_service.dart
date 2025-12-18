import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'student_api_service.dart';

class TeacherApiService {
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
    
    if (kDebugMode) {
      debugPrint('Authorization header: Bearer ${cleanToken.substring(0, cleanToken.length > 20 ? 20 : cleanToken.length)}...');
    }
    
    return headers;
  }

  // 1. Số lớp giảng viên phụ trách
  static Future<TeacherInfoResponse> getTeacherInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/So-Lop-Phu-Trach'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isEmpty) {
          throw Exception('404: Không tìm thấy dữ liệu.');
        }
        return TeacherInfoResponse.fromJson(jsonData[0]);
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

  // 2. Tổng số sinh viên theo lớp
  static Future<List<ClassStudentCountResponse>> getClassStudentCounts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Tong-So-Sinh-Vien-Theo-Lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassStudentCountResponse.fromJson(json)).toList();
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

  // 3. Số lượng sinh viên nam nữ theo lớp
  static Future<List<ClassGenderCountResponse>> getClassGenderCounts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/So-Luong-Sinh-Vien-Nam-Nu-Theo-Lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassGenderCountResponse.fromJson(json)).toList();
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

  // 4. Tổng số sinh viên giảng viên phụ trách
  static Future<TotalStudentsResponse> getTotalStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Tong-So-Sinh-Vien-Giang-Vien-Phu-Trach'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isEmpty) {
          throw Exception('404: Không tìm thấy dữ liệu.');
        }
        return TotalStudentsResponse.fromJson(jsonData[0]);
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

  // 5. GPA trung bình theo lớp học kỳ năm học
  static Future<List<ClassSemesterGPAResponse>> getClassSemesterGPA() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/GPA-Trung-Binh-Theo-Lop-Hoc-Ky-Nam-Hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassSemesterGPAResponse.fromJson(json)).toList();
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

  // 6. GPA trung bình theo lớp toàn khóa
  static Future<List<ClassOverallGPAResponse>> getClassOverallGPA() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/GPA-Trung-Binh-Theo-Lop-Toan-Khoa'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        // Handle both simple array and nested array responses
        if (decoded is List) {
          // Check if it's a nested array (array of arrays)
          if (decoded.isNotEmpty && decoded.first is List) {
            // Flatten the nested array
            jsonData = decoded.expand((item) => item as List).toList();
          } else {
            // Simple array
            jsonData = decoded;
          }
        } else if (decoded is Map) {
          // If it's a Map, try to extract 'data' field or convert the Map to a List
          if (decoded.containsKey('data') && decoded['data'] is List) {
            final data = decoded['data'] as List;
            // Check if data is nested
            if (data.isNotEmpty && data.first is List) {
              jsonData = data.expand((item) => item as List).toList();
            } else {
              jsonData = data;
            }
          } else {
            // If it's a single object wrapped in a Map, convert to List
            jsonData = [decoded];
          }
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => ClassOverallGPAResponse.fromJson(json as Map<String, dynamic>)).toList();
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

  // 7. Xu hướng GPA trung bình theo lớp
  static Future<List<ClassGPATrendResponse>> getClassGPATrend() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Xu-Huong-GPA-Trung-Binh-Theo-Lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassGPATrendResponse.fromJson(json)).toList();
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

  // 8. GPA trung bình theo lớp Môn học, học kỳ, năm học
  static Future<List<ClassSubjectGPAResponse>> getClassSubjectGPA() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/GPA-Trung-Binh-Theo-Lop-Mon-Hoc-Hoc-Ky-Nam-Hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassSubjectGPAResponse.fromJson(json)).toList();
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

  // 9. Môn học tỷ lệ rớt cao nhất theo lớp
  static Future<List<SubjectFailRateHighResponse>> getSubjectFailRateHigh() async {
    try {
      final response = await http.get(
        Uri.parse('https://forceless-kit-flyable.ngrok-free.dev/api/giangvien/Mon-Hoc-Ty-Le-Rot-Cao-Nhat-Theo-Lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectFailRateHighResponse.fromJson(json)).toList();
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

  // 10. Môn học tỷ lệ rớt thấp nhất theo lớp
  static Future<List<SubjectFailRateLowResponse>> getSubjectFailRateLow() async {
    try {
      final response = await http.get(
        Uri.parse('https://forceless-kit-flyable.ngrok-free.dev/api/giangvien/Mon-Hoc-Ty-Le-Rot-Thap-Nhat-Theo-Lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectFailRateLowResponse.fromJson(json)).toList();
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

  // 11. Điểm trung bình môn so với GPA toàn khóa
  static Future<List<SubjectGPAComparisonResponse>> getSubjectGPAComparison() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Diem-Trung-Binh-Mon-So-Voi-GPA-Toan-Khoa'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectGPAComparisonResponse.fromJson(json)).toList();
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

  // 12. Tỷ lệ phần trăm qua/ rớt môn theo lớp học, kỳ học, năm học
  static Future<List<ClassPassFailRateResponse>> getClassPassFailRate() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Ty-Le-Phan-Tram-Qua-Rot-Mon-Theo-Lop-Hoc-Ky-Nam-Hoc-mobi'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassPassFailRateResponse.fromJson(json)).toList();
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

  // 13. Tỷ lệ phần trăm học lực theo lớp, học kỳ, năm học
  static Future<List<ClassAcademicLevelResponse>> getClassAcademicLevel() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Ty-Le-Phan-Tram-Hoc-Luc-Theo-Lop-Hoc-Ky'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassAcademicLevelResponse.fromJson(json)).toList();
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

  // 14. Tỷ lệ phần trăm loại theo môn học, lớp (đậu/rớt)
  static Future<List<SubjectPassFailRateResponse>> getSubjectPassFailRate() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Ty-Le-Phan-Tram-Loai-Theo-Mon-Hoc-Lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectPassFailRateResponse.fromJson(json)).toList();
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

  // 15. Mối tương quan giữa điểm rèn luyện trung bình và GPA trung bình
  static Future<List<ClassGPAConductCorrelationResponse>> getClassGPAConductCorrelation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Moi-Tuong-Quan-Giua-Diem-Ren-Luyen-Trung-Binh-Va-GPA-Trung-Binh'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ClassGPAConductCorrelationResponse.fromJson(json)).toList();
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

  // 16. Số lượng sinh viên rớt môn tại học kỳ, năm học
  static Future<List<StudentFailCountResponse>> getStudentFailCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/So-Luong-Sinh-Vien-Rot-Mon-Tai-Hoc-Ky-Nam-Hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => StudentFailCountResponse.fromJson(json)).toList();
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

  // 17. GPA từng sinh viên trong lớp tại học kỳ, năm học
  static Future<List<StudentGPAByClassResponse>> getStudentGPAByClass() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/GPA-tung-sinh-vien-trong-lop-tai-hoc-ki-nam-hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => StudentGPAByClassResponse.fromJson(json)).toList();
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

  // 18. Số lượng sinh viên đậu theo từng môn tại học kì, năm học
  static Future<List<SubjectPassCountResponse>> getSubjectPassCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/so-luong-sinh-vien-dau-theo-tung-mon-tai-hoc-ki'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectPassCountResponse.fromJson(json)).toList();
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

  // 19. Giảng viên cố vấn lớp học theo kỳ học, năm học
  static Future<List<TeacherAdvisorBySemesterResponse>> getTeacherAdvisorBySemester() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Giang-Vien-Co-Van-Lop-Hoc-Theo-Ky'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => TeacherAdvisorBySemesterResponse.fromJson(json)).toList();
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

  // Tỷ lệ phần trăm xếp loại theo môn học lớp
  static Future<List<SubjectGradeDistributionResponse>> getSubjectGradeDistribution() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Ty-Le-Phan-Tram-Loai-Theo-Mon-Hoc-Lop'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        // Handle both Map and List responses
        if (decoded is Map) {
          // If it's a Map, try to extract 'data' field or convert the Map to a List
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            // If it's a single object wrapped in a Map, convert to List
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => SubjectGradeDistributionResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Tỷ lệ phần trăm qua/rớt môn theo lớp học kỳ năm học
  static Future<List<SubjectPassFailRateBySemesterResponse>> getSubjectPassFailRateBySemester() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/Ty-Le-Phan-Tram-Qua-Rot-Mon-Theo-Lop-Hoc-Ky-Nam-Hoc-mobi'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectPassFailRateBySemesterResponse.fromJson(json)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Số lượng sinh viên rớt môn tại học kỳ năm học
  static Future<List<StudentFailCountBySemesterResponse>> getStudentFailCountBySemester() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/so-luong-sinh-vien-rot-mon-tai-hoc-ki-nam-hoc'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        // Handle both Map and List responses
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => StudentFailCountBySemesterResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Danh sách sinh viên trong lớp
  static Future<List<ClassStudentListResponse>> getClassStudentsList(String lop) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/Danh-Sach-Sinh-Vien-Lop-X'),
        headers: headers,
        body: jsonEncode({'lop': lop}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        // Handle both Map and List responses
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => ClassStudentListResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Số lượng sinh viên đậu theo từng môn tại học kỳ
  static Future<List<SubjectPassRateResponse>> getStudentPassRateBySubject() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/giangvien/so-luong-sinh-vien-dau-theo-tung-mon-tai-hoc-ki'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => SubjectPassRateResponse.fromJson(json)).toList();
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

  // Thông tin sinh viên (cho giảng viên - với masv)
  static Future<StudentInfoResponse> getStudentInfoByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/thong-tin-sinh-vien'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        if (jsonData.isEmpty) {
          throw Exception('404: Không tìm thấy dữ liệu.');
        }
        return StudentInfoResponse.fromJson(jsonData[0] as Map<String, dynamic>);
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // GPA trung bình toàn khóa của sinh viên (cho giảng viên - với masv)
  static Future<OverallGPAResponse> getOverallGPAByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/gpa-trung-binh-toan-khoa-cua-sinh-vien'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        if (jsonData.isEmpty) {
          throw Exception('404: Không tìm thấy dữ liệu.');
        }
        return OverallGPAResponse.fromJson(jsonData[0] as Map<String, dynamic>);
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Tỷ lệ qua môn của sinh viên (cho giảng viên - với masv)
  static Future<List<PassRateBySemesterResponse>> getPassRateByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/gpa-trung-binh-toan-khoa-cua-sinh-vien'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => PassRateBySemesterResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Tỷ lệ môn học đạt loại của sinh viên (cho giảng viên - với masv)
  static Future<List<SubjectGradeRateResponse>> getSubjectGradeRateByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/ty-le-mon-hoc-dat-loai-cua-sinh-vien'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => SubjectGradeRateResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Xu hướng GPA của sinh viên qua các học kỳ (cho giảng viên - với masv)
  static Future<List<GPATrendResponse>> getGPATrendByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/xu-huong-gpa-cua-sinh-vien-qua-cac-hoc-ky'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => GPATrendResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Điểm chi tiết từng môn học sinh viên đã học (cho giảng viên - với masv)
  static Future<List<SubjectDetailResponse>> getSubjectDetailsByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/diem-chi-tiet-tung-mon-hoc-sinh-vien-da-hoc'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => SubjectDetailResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // So sánh điểm trung bình môn học của sinh viên với lớp (cho giảng viên - với masv)
  static Future<List<SubjectComparisonResponse>> getSubjectComparisonByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/so-sanh-diem-trung-binh-mon-hoc-cua-sinh-vien-voi-lop'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => SubjectComparisonResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }

  // Điểm rèn luyện của sinh viên trong từng học kỳ (cho giảng viên - với masv)
  static Future<List<ConductScoreResponse>> getConductScoresByMasv(String masv) async {
    try {
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/giangvien/diem-ren-luyen-cua-sinh-vien-trong-tung-hoc-ky'),
        headers: headers,
        body: jsonEncode({'masv': masv}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonData;
        
        if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonData = decoded['data'] as List<dynamic>;
          } else {
            jsonData = [decoded];
          }
        } else if (decoded is List) {
          jsonData = decoded;
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }
        
        return jsonData.map((json) => ConductScoreResponse.fromJson(json as Map<String, dynamic>)).toList();
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
      throw Exception('Lỗi khi gọi API: ${e.toString()}');
    }
  }
}

// Tỷ lệ phần trăm qua/rớt môn theo lớp học kỳ năm học
class SubjectPassFailRateBySemesterResponse {
  final String tenLop;
  final String tenNamHoc;
  final String tenHocKy;
  final int? soDau;
  final int? soRot;
  final int tongLuot;
  final double? tyLeDau;
  final double? tyLeRot;

  SubjectPassFailRateBySemesterResponse({
    required this.tenLop,
    required this.tenNamHoc,
    required this.tenHocKy,
    this.soDau,
    this.soRot,
    required this.tongLuot,
    this.tyLeDau,
    this.tyLeRot,
  });

  factory SubjectPassFailRateBySemesterResponse.fromJson(Map<String, dynamic> json) {
    return SubjectPassFailRateBySemesterResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      soDau: json['So_Dau'],
      soRot: json['So_Rot'],
      tongLuot: json['Tong_Luot'] ?? 0,
      tyLeDau: json['Ty_Le_Dau'] != null ? (json['Ty_Le_Dau'] as num).toDouble() : null,
      tyLeRot: json['Ty_Le_Rot'] != null ? (json['Ty_Le_Rot'] as num).toDouble() : null,
    );
  }
}

// Response Models
class TeacherInfoResponse {
  final String hoTen;
  final String maGiaoVien;
  final int soLopPhuTrach;

  TeacherInfoResponse({
    required this.hoTen,
    required this.maGiaoVien,
    required this.soLopPhuTrach,
  });

  factory TeacherInfoResponse.fromJson(Map<String, dynamic> json) {
    return TeacherInfoResponse(
      hoTen: json['Ho Ten'] ?? '',
      maGiaoVien: json['Ma Giao Vien'] ?? '',
      soLopPhuTrach: json['So_Lop_Phu_Trach'] ?? 0,
    );
  }
}

class ClassStudentCountResponse {
  final String tenLop;
  final int tongSv;

  ClassStudentCountResponse({
    required this.tenLop,
    required this.tongSv,
  });

  factory ClassStudentCountResponse.fromJson(Map<String, dynamic> json) {
    return ClassStudentCountResponse(
      tenLop: json['Ten Lop'] ?? '',
      tongSv: json['Tong_SV'] ?? 0,
    );
  }
}

class ClassGenderCountResponse {
  final String tenLop;
  final int soNam;
  final int soNu;

  ClassGenderCountResponse({
    required this.tenLop,
    required this.soNam,
    required this.soNu,
  });

  factory ClassGenderCountResponse.fromJson(Map<String, dynamic> json) {
    return ClassGenderCountResponse(
      tenLop: json['Ten Lop'] ?? '',
      soNam: json['SoNam'] ?? 0,
      soNu: json['SoNu'] ?? 0,
    );
  }
}

class TotalStudentsResponse {
  final int tongSoSinhVien;

  TotalStudentsResponse({required this.tongSoSinhVien});

  factory TotalStudentsResponse.fromJson(Map<String, dynamic> json) {
    return TotalStudentsResponse(
      tongSoSinhVien: json['Tong_So_Sinh_Vien'] ?? 0,
    );
  }
}

class ClassSemesterGPAResponse {
  final String tenLop;
  final String tenNamHoc;
  final String maHocKy;
  final double gpa;

  ClassSemesterGPAResponse({
    required this.tenLop,
    required this.tenNamHoc,
    required this.maHocKy,
    required this.gpa,
  });

  factory ClassSemesterGPAResponse.fromJson(Map<String, dynamic> json) {
    // API đã đổi từ "Ma Hoc Ky" sang "Ten Hoc Ky", ưu tiên parse "Ten Hoc Ky"
    final hocKy = json['Ten Hoc Ky'] ?? json['Ma Hoc Ky'] ?? '';
    return ClassSemesterGPAResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      maHocKy: hocKy,
      gpa: (json['GPA'] ?? 0.0).toDouble(),
    );
  }
}

class ClassOverallGPAResponse {
  final String tenLop;
  final String khoaHoc;
  final double gpa;

  ClassOverallGPAResponse({
    required this.tenLop,
    required this.khoaHoc,
    required this.gpa,
  });

  factory ClassOverallGPAResponse.fromJson(Map<String, dynamic> json) {
    return ClassOverallGPAResponse(
      tenLop: json['Ten Lop'] ?? '',
      khoaHoc: json['Khoa Hoc'] ?? '',
      gpa: (json['GPA'] ?? 0.0).toDouble(),
    );
  }
}

class ClassGPATrendResponse {
  final String tenLop;
  final Map<String, double?> gpaByYear;

  ClassGPATrendResponse({
    required this.tenLop,
    required this.gpaByYear,
  });

  factory ClassGPATrendResponse.fromJson(Map<String, dynamic> json) {
    final gpaByYear = <String, double?>{};
    json.forEach((key, value) {
      if (key != 'Ten Lop') {
        gpaByYear[key] = value == null ? null : (value as num).toDouble();
      }
    });
    return ClassGPATrendResponse(
      tenLop: json['Ten Lop'] ?? '',
      gpaByYear: gpaByYear,
    );
  }
}

class ClassSubjectGPAResponse {
  final String tenLop;
  final String tenMonHoc;
  final String tenNamHoc;
  final String maHocKy;
  final double gpa;

  ClassSubjectGPAResponse({
    required this.tenLop,
    required this.tenMonHoc,
    required this.tenNamHoc,
    required this.maHocKy,
    required this.gpa,
  });

  factory ClassSubjectGPAResponse.fromJson(Map<String, dynamic> json) {
    // API đã đổi từ "Ma Hoc Ky" sang "Ten Hoc Ky", ưu tiên parse "Ten Hoc Ky"
    final hocKy = json['Ten Hoc Ky'] ?? json['Ma Hoc Ky'] ?? '';
    return ClassSubjectGPAResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      maHocKy: hocKy,
      gpa: (json['GPA'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectFailRateHighResponse {
  final String tenLop;
  final String tenMonHoc;
  final String tenNamHoc;
  final String tenHocKy;
  final double tyLeRot;

  SubjectFailRateHighResponse({
    required this.tenLop,
    required this.tenMonHoc,
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tyLeRot,
  });

  factory SubjectFailRateHighResponse.fromJson(Map<String, dynamic> json) {
    return SubjectFailRateHighResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tyLeRot: (json['Ty_Le_Rot'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectFailRateLowResponse {
  final String tenLop;
  final String tenMonHoc;
  final String tenNamHoc;
  final String tenHocKy;
  final double tyLeRot;

  SubjectFailRateLowResponse({
    required this.tenLop,
    required this.tenMonHoc,
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tyLeRot,
  });

  factory SubjectFailRateLowResponse.fromJson(Map<String, dynamic> json) {
    return SubjectFailRateLowResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tyLeRot: (json['Ty_Le_Rot'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectGPAComparisonResponse {
  final String tenLop;
  final String tenMonHoc;
  final String tenNamHoc;
  final String maHocKy;
  final double gpaLop;
  final double gpaKhoa;
  final double doChenhLech;

  SubjectGPAComparisonResponse({
    required this.tenLop,
    required this.tenMonHoc,
    required this.tenNamHoc,
    required this.maHocKy,
    required this.gpaLop,
    required this.gpaKhoa,
    required this.doChenhLech,
  });

  factory SubjectGPAComparisonResponse.fromJson(Map<String, dynamic> json) {
    // API đã đổi từ "Ma Hoc Ky" sang "Ten Hoc Ky", ưu tiên parse "Ten Hoc Ky"
    final hocKy = json['Ten Hoc Ky'] ?? json['Ma Hoc Ky'] ?? '';
    return SubjectGPAComparisonResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      maHocKy: hocKy,
      gpaLop: (json['GPA_Lop'] ?? 0.0).toDouble(),
      gpaKhoa: (json['GPA_Khoa'] ?? 0.0).toDouble(),
      doChenhLech: (json['Do_Chenh_Lech'] ?? 0.0).toDouble(),
    );
  }
}

class ClassPassFailRateResponse {
  final String tenLop;
  final String tenNamHoc;
  final String tenHocKy;
  final int? soDau;
  final int? soRot;
  final int tongLuot;
  final double? tyLeDau;
  final double? tyLeRot;

  ClassPassFailRateResponse({
    required this.tenLop,
    required this.tenNamHoc,
    required this.tenHocKy,
    this.soDau,
    this.soRot,
    required this.tongLuot,
    this.tyLeDau,
    this.tyLeRot,
  });

  factory ClassPassFailRateResponse.fromJson(Map<String, dynamic> json) {
    return ClassPassFailRateResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      soDau: json['So_Dau'],
      soRot: json['So_Rot'],
      tongLuot: json['Tong_Luot'] ?? 0,
      tyLeDau: json['Ty_Le_Dau'] != null ? (json['Ty_Le_Dau'] as num).toDouble() : null,
      tyLeRot: json['Ty_Le_Rot'] != null ? (json['Ty_Le_Rot'] as num).toDouble() : null,
    );
  }
}

class ClassAcademicLevelResponse {
  final String tenLop;
  final String tenNamHoc;
  final String tenHocKy;
  final double tlXuatSac;
  final double tlGioi;
  final double tlKha;
  final double tlTb;
  final double tlYeu;
  final double tlKem;

  ClassAcademicLevelResponse({
    required this.tenLop,
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tlXuatSac,
    required this.tlGioi,
    required this.tlKha,
    required this.tlTb,
    required this.tlYeu,
    required this.tlKem,
  });

  factory ClassAcademicLevelResponse.fromJson(Map<String, dynamic> json) {
    return ClassAcademicLevelResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tlXuatSac: (json['TL_XuatSac'] ?? 0.0).toDouble(),
      tlGioi: (json['TL_Gioi'] ?? 0.0).toDouble(),
      tlKha: (json['TL_Kha'] ?? 0.0).toDouble(),
      tlTb: (json['TL_TB'] ?? 0.0).toDouble(),
      tlYeu: (json['TL_Yeu'] ?? 0.0).toDouble(),
      tlKem: (json['TL_Kem'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectPassFailRateResponse {
  final String tenLop;
  final String tenMonHoc;
  final double tyLeDau;
  final double tyLeRot;

  SubjectPassFailRateResponse({
    required this.tenLop,
    required this.tenMonHoc,
    required this.tyLeDau,
    required this.tyLeRot,
  });

  factory SubjectPassFailRateResponse.fromJson(Map<String, dynamic> json) {
    return SubjectPassFailRateResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      tyLeDau: (json['Ty_Le_Dau'] ?? 0.0).toDouble(),
      tyLeRot: (json['Ty_Le_Rot'] ?? 0.0).toDouble(),
    );
  }
}

class ClassGPAConductCorrelationResponse {
  final String tenLop;
  final double gpaLop;
  final double drlLop;

  ClassGPAConductCorrelationResponse({
    required this.tenLop,
    required this.gpaLop,
    required this.drlLop,
  });

  factory ClassGPAConductCorrelationResponse.fromJson(Map<String, dynamic> json) {
    return ClassGPAConductCorrelationResponse(
      tenLop: json['Ten Lop'] ?? '',
      gpaLop: (json['GPA_Lop'] ?? 0.0).toDouble(),
      drlLop: (json['DRL_Lop'] ?? 0.0).toDouble(),
    );
  }
}

class StudentFailCountResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final int soLuongRot;

  StudentFailCountResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.soLuongRot,
  });

  factory StudentFailCountResponse.fromJson(Map<String, dynamic> json) {
    return StudentFailCountResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      soLuongRot: json['So_Luong_Rot'] ?? 0,
    );
  }
}

class StudentGPAByClassResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenLop;
  final String hoTen;
  final double gpaHocKy;

  StudentGPAByClassResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenLop,
    required this.hoTen,
    required this.gpaHocKy,
  });

  factory StudentGPAByClassResponse.fromJson(Map<String, dynamic> json) {
    return StudentGPAByClassResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenLop: json['Ten Lop'] ?? '',
      hoTen: json['Ho Ten'] ?? '',
      gpaHocKy: (json['GPA_HocKy'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectPassCountResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenMonHoc;
  final int soSvDau;

  SubjectPassCountResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenMonHoc,
    required this.soSvDau,
  });

  factory SubjectPassCountResponse.fromJson(Map<String, dynamic> json) {
    return SubjectPassCountResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      soSvDau: json['SoSV_Dau'] ?? 0,
    );
  }
}

class TeacherAdvisorBySemesterResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenLop;
  final int factHocTapCount;

  TeacherAdvisorBySemesterResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenLop,
    required this.factHocTapCount,
  });

  factory TeacherAdvisorBySemesterResponse.fromJson(Map<String, dynamic> json) {
    return TeacherAdvisorBySemesterResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenLop: json['Ten Lop'] ?? '',
      factHocTapCount: json['Fact Hoc Tap Count'] ?? 0,
    );
  }
}

// Tỷ lệ phần trăm xếp loại theo môn học lớp
class SubjectGradeDistributionResponse {
  final String tenLop;
  final String tenMonHoc;
  final double tlGioi;
  final double tlKhaGioi;
  final double tlKha;
  final double tlTbk;
  final double tlTb;
  final double tlTby;
  final double tlYeu;
  final double tlKem;

  SubjectGradeDistributionResponse({
    required this.tenLop,
    required this.tenMonHoc,
    required this.tlGioi,
    required this.tlKhaGioi,
    required this.tlKha,
    required this.tlTbk,
    required this.tlTb,
    required this.tlTby,
    required this.tlYeu,
    required this.tlKem,
  });

  factory SubjectGradeDistributionResponse.fromJson(Map<String, dynamic> json) {
    return SubjectGradeDistributionResponse(
      tenLop: json['Ten Lop'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      tlGioi: (json['TL_Gioi'] ?? 0.0).toDouble(),
      tlKhaGioi: (json['TL_KhaGioi'] ?? 0.0).toDouble(),
      tlKha: (json['TL_Kha'] ?? 0.0).toDouble(),
      tlTbk: (json['TL_TBK'] ?? 0.0).toDouble(),
      tlTb: (json['TL_TB'] ?? 0.0).toDouble(),
      tlTby: (json['TL_TBY'] ?? 0.0).toDouble(),
      tlYeu: (json['TL_Yeu'] ?? 0.0).toDouble(),
      tlKem: (json['TL_Kem'] ?? 0.0).toDouble(),
    );
  }
}

// Số lượng sinh viên rớt môn tại học kỳ năm học
class StudentFailCountBySemesterResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final int soSVRot;

  StudentFailCountBySemesterResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.soSVRot,
  });

  factory StudentFailCountBySemesterResponse.fromJson(Map<String, dynamic> json) {
    return StudentFailCountBySemesterResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      soSVRot: json['SoSV_Rot'] ?? 0,
    );
  }
}

// Danh sách sinh viên trong lớp
class ClassStudentListResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String hoTen;
  final String maSinhVien;
  final double gpaHocKy;

  ClassStudentListResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.hoTen,
    required this.maSinhVien,
    required this.gpaHocKy,
  });

  factory ClassStudentListResponse.fromJson(Map<String, dynamic> json) {
    return ClassStudentListResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      hoTen: json['Ho Ten'] ?? '',
      maSinhVien: json['Ma Sinh Vien'] ?? '',
      gpaHocKy: (json['GPA_HocKy'] ?? 0.0).toDouble(),
    );
  }
}

// Số lượng sinh viên đậu theo từng môn tại học kỳ
class SubjectPassRateResponse {
  final String tenNamHoc;
  final String tenHocKy;
  final String tenMonHoc;
  final int soSV_Dau;

  SubjectPassRateResponse({
    required this.tenNamHoc,
    required this.tenHocKy,
    required this.tenMonHoc,
    required this.soSV_Dau,
  });

  factory SubjectPassRateResponse.fromJson(Map<String, dynamic> json) {
    return SubjectPassRateResponse(
      tenNamHoc: json['Ten Nam Hoc'] ?? '',
      tenHocKy: json['Ten Hoc Ky'] ?? '',
      tenMonHoc: json['Ten Mon Hoc'] ?? '',
      soSV_Dau: json['SoSV_Dau'] ?? 0,
    );
  }
}



