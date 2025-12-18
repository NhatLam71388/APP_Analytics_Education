import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_academic.dart';
import '../models/teacher_advisor.dart';

class CacheService {
  static const String _studentDataKey = 'cached_student_data';
  static const String _teacherDataKey = 'cached_teacher_data';
  static const String _studentDataTimestampKey = 'cached_student_data_timestamp';
  static const String _teacherDataTimestampKey = 'cached_teacher_data_timestamp';
  static const String _studentDataByMasvPrefix = 'cached_student_data_masv_';
  static const String _studentDataByMasvTimestampPrefix = 'cached_student_data_masv_timestamp_';
  
  // Cache duration: 5 phút (300 giây)
  static const int _cacheDurationSeconds = 300;

  // Lưu dữ liệu sinh viên vào cache
  static Future<void> saveStudentData(StudentAcademic data, {String? masv}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      if (masv != null) {
        await prefs.setString('$_studentDataByMasvPrefix$masv', jsonString);
        await prefs.setInt('$_studentDataByMasvTimestampPrefix$masv', timestamp);
      } else {
        await prefs.setString(_studentDataKey, jsonString);
        await prefs.setInt(_studentDataTimestampKey, timestamp);
      }
    } catch (e) {
      debugPrint('Error saving student data to cache: $e');
    }
  }

  // Lấy dữ liệu sinh viên từ cache
  static Future<StudentAcademic?> getStudentData({String? masv}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString;
      int? timestamp;
      
      if (masv != null) {
        jsonString = prefs.getString('$_studentDataByMasvPrefix$masv');
        timestamp = prefs.getInt('$_studentDataByMasvTimestampPrefix$masv');
      } else {
        jsonString = prefs.getString(_studentDataKey);
        timestamp = prefs.getInt(_studentDataTimestampKey);
      }
      
      if (jsonString == null || timestamp == null) {
        return null;
      }
      
      // Kiểm tra xem cache có còn hợp lệ không
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDurationSeconds * 1000) {
        // Cache đã hết hạn
        return null;
      }
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return StudentAcademic.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error getting student data from cache: $e');
      return null;
    }
  }

  // Kiểm tra cache có tồn tại và còn hợp lệ không
  static Future<bool> hasValidStudentCache({String? masv}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? timestamp;
      
      if (masv != null) {
        timestamp = prefs.getInt('$_studentDataByMasvTimestampPrefix$masv');
      } else {
        timestamp = prefs.getInt(_studentDataTimestampKey);
      }
      
      if (timestamp == null) {
        return false;
      }
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      return cacheAge <= _cacheDurationSeconds * 1000;
    } catch (e) {
      return false;
    }
  }

  // Lưu dữ liệu giáo viên vào cache (dạng JSON string đơn giản)
  static Future<void> saveTeacherData(TeacherAdvisor data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Vì TeacherAdvisor phức tạp, ta sẽ cache các thông tin cơ bản
      // và để các màn hình con tự load lại khi cần
      final cacheData = {
        'maGiangVien': data.maGiangVien,
        'hoTen': data.hoTen,
        'soLopPhuTrach': data.soLopPhuTrach,
        'totalStudentsFromAPI': data.totalStudentsFromAPI,
        // Cache danh sách lớp cơ bản
        'classes': data.classes.map((c) => {
          'tenLop': c.tenLop,
          'maLop': c.maLop,
          'totalStudents': c.totalStudents,
          'maleCount': c.maleCount,
          'femaleCount': c.femaleCount,
        }).toList(),
      };
      
      final jsonString = jsonEncode(cacheData);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_teacherDataKey, jsonString);
      await prefs.setInt(_teacherDataTimestampKey, timestamp);
    } catch (e) {
      debugPrint('Error saving teacher data to cache: $e');
    }
  }

  // Lấy dữ liệu giáo viên từ cache (chỉ thông tin cơ bản)
  static Future<Map<String, dynamic>?> getTeacherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_teacherDataKey);
      final timestamp = prefs.getInt(_teacherDataTimestampKey);
      
      if (jsonString == null || timestamp == null) {
        return null;
      }
      
      // Kiểm tra xem cache có còn hợp lệ không
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDurationSeconds * 1000) {
        // Cache đã hết hạn
        return null;
      }
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting teacher data from cache: $e');
      return null;
    }
  }

  // Kiểm tra cache giáo viên có tồn tại và còn hợp lệ không
  static Future<bool> hasValidTeacherCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_teacherDataTimestampKey);
      
      if (timestamp == null) {
        return false;
      }
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      return cacheAge <= _cacheDurationSeconds * 1000;
    } catch (e) {
      return false;
    }
  }

  // Xóa cache sinh viên
  static Future<void> clearStudentCache({String? masv}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (masv != null) {
        await prefs.remove('$_studentDataByMasvPrefix$masv');
        await prefs.remove('$_studentDataByMasvTimestampPrefix$masv');
      } else {
        await prefs.remove(_studentDataKey);
        await prefs.remove(_studentDataTimestampKey);
      }
    } catch (e) {
      debugPrint('Error clearing student cache: $e');
    }
  }

  // Xóa cache giáo viên
  static Future<void> clearTeacherCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_teacherDataKey);
      await prefs.remove(_teacherDataTimestampKey);
    } catch (e) {
      debugPrint('Error clearing teacher cache: $e');
    }
  }

  // Xóa tất cả cache
  static Future<void> clearAllCache() async {
    await clearStudentCache();
    await clearTeacherCache();
  }
}

