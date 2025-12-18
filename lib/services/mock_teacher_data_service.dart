import '../models/teacher_advisor.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';

class MockTeacherDataService {
  static TeacherAdvisor getMockTeacherData() {
    return TeacherAdvisor(
      maGiangVien: 'GV001',
      hoTen: 'Nguyễn Văn A',
      classes: [
        // Lớp CNTT2021
        ClassModel(
          maLop: 'CNTT2021',
          tenLop: 'Công nghệ thông tin 2021',
          namHoc: 2021,
          khoa: 2021,
          students: _generateStudents('CNTT2021', 35),
          semesterData: [
            ClassSemesterData(
              hocKy: '2021-2022-1',
              namHoc: 2021,
              hocKySo: 1,
              gpa: 7.8,
              passRate: 85.5,
              academicLevels: {'Giỏi': 25.0, 'Khá': 45.0, 'Trung bình': 30.0},
              subjectGPA: {
                'Lập trình cơ bản': 8.2,
                'Toán cao cấp': 7.5,
                'Tiếng Anh 1': 7.0,
                'Vật lý đại cương': 7.8,
                'Lịch sử Đảng': 8.5,
              },
              subjectPassRate: {
                'Lập trình cơ bản': 90.0,
                'Toán cao cấp': 85.0,
                'Tiếng Anh 1': 80.0,
                'Vật lý đại cương': 88.0,
                'Lịch sử Đảng': 95.0,
              },
              totalStudents: 35,
              maleCount: 20,
              femaleCount: 15,
            ),
            ClassSemesterData(
              hocKy: '2021-2022-2',
              namHoc: 2021,
              hocKySo: 2,
              gpa: 8.1,
              passRate: 88.0,
              academicLevels: {'Giỏi': 30.0, 'Khá': 50.0, 'Trung bình': 20.0},
              subjectGPA: {
                'Cấu trúc dữ liệu': 8.5,
                'Xác suất thống kê': 7.8,
                'Tiếng Anh 2': 7.5,
                'Cơ sở dữ liệu': 8.2,
                'Mạng máy tính': 8.0,
              },
              subjectPassRate: {
                'Cấu trúc dữ liệu': 92.0,
                'Xác suất thống kê': 87.0,
                'Tiếng Anh 2': 82.0,
                'Cơ sở dữ liệu': 90.0,
                'Mạng máy tính': 88.0,
              },
              totalStudents: 34,
              maleCount: 19,
              femaleCount: 15,
            ),
            ClassSemesterData(
              hocKy: '2022-2023-1',
              namHoc: 2022,
              hocKySo: 1,
              gpa: 8.3,
              passRate: 90.0,
              academicLevels: {'Giỏi': 35.0, 'Khá': 48.0, 'Trung bình': 17.0},
              subjectGPA: {
                'Lập trình hướng đối tượng': 8.6,
                'Phát triển Web': 8.8,
                'Giải thuật': 8.2,
                'Hệ điều hành': 7.9,
                'Kỹ thuật phần mềm': 8.4,
              },
              subjectPassRate: {
                'Lập trình hướng đối tượng': 93.0,
                'Phát triển Web': 95.0,
                'Giải thuật': 90.0,
                'Hệ điều hành': 88.0,
                'Kỹ thuật phần mềm': 91.0,
              },
              totalStudents: 33,
              maleCount: 18,
              femaleCount: 15,
            ),
            ClassSemesterData(
              hocKy: '2022-2023-2',
              namHoc: 2022,
              hocKySo: 2,
              gpa: 8.5,
              passRate: 92.0,
              academicLevels: {'Giỏi': 40.0, 'Khá': 45.0, 'Trung bình': 15.0},
              subjectGPA: {
                'Lập trình Java': 8.7,
                'Lập trình di động': 8.5,
                'Trí tuệ nhân tạo': 8.0,
                'An ninh mạng': 8.3,
                'Đồ án 1': 8.6,
              },
              subjectPassRate: {
                'Lập trình Java': 94.0,
                'Lập trình di động': 92.0,
                'Trí tuệ nhân tạo': 89.0,
                'An ninh mạng': 91.0,
                'Đồ án 1': 93.0,
              },
              totalStudents: 33,
              maleCount: 18,
              femaleCount: 15,
            ),
            ClassSemesterData(
              hocKy: '2023-2024-1',
              namHoc: 2023,
              hocKySo: 1,
              gpa: 8.6,
              passRate: 93.0,
              academicLevels: {'Giỏi': 42.0, 'Khá': 46.0, 'Trung bình': 12.0},
              subjectGPA: {
                'Lập trình Python': 8.8,
                'Điện toán đám mây': 8.4,
                'Dữ liệu lớn': 8.2,
                'Kiến trúc phần mềm': 8.5,
                'Đồ án 2': 8.7,
              },
              subjectPassRate: {
                'Lập trình Python': 95.0,
                'Điện toán đám mây': 92.0,
                'Dữ liệu lớn': 90.0,
                'Kiến trúc phần mềm': 93.0,
                'Đồ án 2': 94.0,
              },
              totalStudents: 32,
              maleCount: 17,
              femaleCount: 15,
            ),
          ],
        ),
        // Lớp CNTT2022
        ClassModel(
          maLop: 'CNTT2022',
          tenLop: 'Công nghệ thông tin 2022',
          namHoc: 2022,
          khoa: 2022,
          students: _generateStudents('CNTT2022', 40),
          semesterData: [
            ClassSemesterData(
              hocKy: '2022-2023-1',
              namHoc: 2022,
              hocKySo: 1,
              gpa: 7.5,
              passRate: 82.0,
              academicLevels: {'Giỏi': 20.0, 'Khá': 40.0, 'Trung bình': 40.0},
              subjectGPA: {
                'Lập trình cơ bản': 7.8,
                'Toán cao cấp': 7.2,
                'Tiếng Anh 1': 6.8,
                'Vật lý đại cương': 7.5,
                'Lịch sử Đảng': 8.0,
              },
              subjectPassRate: {
                'Lập trình cơ bản': 85.0,
                'Toán cao cấp': 80.0,
                'Tiếng Anh 1': 75.0,
                'Vật lý đại cương': 83.0,
                'Lịch sử Đảng': 90.0,
              },
              totalStudents: 40,
              maleCount: 23,
              femaleCount: 17,
            ),
            ClassSemesterData(
              hocKy: '2022-2023-2',
              namHoc: 2022,
              hocKySo: 2,
              gpa: 7.8,
              passRate: 85.0,
              academicLevels: {'Giỏi': 25.0, 'Khá': 45.0, 'Trung bình': 30.0},
              subjectGPA: {
                'Cấu trúc dữ liệu': 8.0,
                'Xác suất thống kê': 7.5,
                'Tiếng Anh 2': 7.2,
                'Cơ sở dữ liệu': 7.8,
                'Mạng máy tính': 7.6,
              },
              subjectPassRate: {
                'Cấu trúc dữ liệu': 88.0,
                'Xác suất thống kê': 82.0,
                'Tiếng Anh 2': 78.0,
                'Cơ sở dữ liệu': 85.0,
                'Mạng máy tính': 83.0,
              },
              totalStudents: 39,
              maleCount: 22,
              femaleCount: 17,
            ),
            ClassSemesterData(
              hocKy: '2023-2024-1',
              namHoc: 2023,
              hocKySo: 1,
              gpa: 8.0,
              passRate: 87.0,
              academicLevels: {'Giỏi': 30.0, 'Khá': 48.0, 'Trung bình': 22.0},
              subjectGPA: {
                'Lập trình hướng đối tượng': 8.2,
                'Phát triển Web': 8.4,
                'Giải thuật': 7.9,
                'Hệ điều hành': 7.7,
                'Kỹ thuật phần mềm': 8.1,
              },
              subjectPassRate: {
                'Lập trình hướng đối tượng': 90.0,
                'Phát triển Web': 92.0,
                'Giải thuật': 87.0,
                'Hệ điều hành': 85.0,
                'Kỹ thuật phần mềm': 89.0,
              },
              totalStudents: 38,
              maleCount: 21,
              femaleCount: 17,
            ),
          ],
        ),
        // Lớp CNTT2023
        ClassModel(
          maLop: 'CNTT2023',
          tenLop: 'Công nghệ thông tin 2023',
          namHoc: 2023,
          khoa: 2023,
          students: _generateStudents('CNTT2023', 38),
          semesterData: [
            ClassSemesterData(
              hocKy: '2023-2024-1',
              namHoc: 2023,
              hocKySo: 1,
              gpa: 7.2,
              passRate: 78.0,
              academicLevels: {'Giỏi': 15.0, 'Khá': 35.0, 'Trung bình': 50.0},
              subjectGPA: {
                'Lập trình cơ bản': 7.5,
                'Toán cao cấp': 6.8,
                'Tiếng Anh 1': 6.5,
                'Vật lý đại cương': 7.2,
                'Lịch sử Đảng': 7.8,
              },
              subjectPassRate: {
                'Lập trình cơ bản': 80.0,
                'Toán cao cấp': 75.0,
                'Tiếng Anh 1': 70.0,
                'Vật lý đại cương': 78.0,
                'Lịch sử Đảng': 85.0,
              },
              totalStudents: 38,
              maleCount: 22,
              femaleCount: 16,
            ),
          ],
        ),
      ],
    );
  }

  static List<StudentModel> _generateStudents(String lop, int count) {
    final students = <StudentModel>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 1; i <= count; i++) {
      final isMale = (random + i) % 2 == 0;
      final diemRenLuyen = 75.0 + ((random + i) % 20);
      students.add(StudentModel(
        maSinhVien: '$lop${i.toString().padLeft(3, '0')}',
        hoTen: 'Sinh viên $i',
        gioiTinh: isMale ? 'Nam' : 'Nữ',
        diemRenLuyen: diemRenLuyen,
        gpa: 7.0 + ((random + i) % 30) / 10, // GPA từ 7.0 đến 10.0
      ));
    }
    return students;
  }

  // GPA trung bình toàn khoa (mock data)
  static double getFacultyGPA(String hocKy) {
    switch (hocKy) {
      case '2021-2022-1':
        return 7.6;
      case '2021-2022-2':
        return 7.9;
      case '2022-2023-1':
        return 8.1;
      case '2022-2023-2':
        return 8.3;
      case '2023-2024-1':
        return 8.2;
      default:
        return 8.0;
  }
}
}
