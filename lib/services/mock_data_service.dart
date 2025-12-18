import '../models/student_academic.dart';
import '../models/semester.dart';
import '../models/subject.dart';

class MockDataService {
  static StudentAcademic getMockStudentData() {
    return StudentAcademic(
      maSinhVien: '001134263',
      hoTen: 'Quách Phùng Đỗ',
      lop: 'CNTT2021',
      khuVuc: 'Hà Nội',
      semesters: [
        // Năm 1 - Học kỳ 1
        Semester(
          hocKy: '2021-2022-1',
          namHoc: 2021,
          hocKySo: 1,
          diemRenLuyen: 85.0,
          subjects: [
            Subject(maMon: 'CS101', tenMon: 'Lập trình cơ bản', diem: 8.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.8),
            Subject(maMon: 'MATH101', tenMon: 'Toán cao cấp', diem: 7.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 6.5),
            Subject(maMon: 'ENG101', tenMon: 'Tiếng Anh 1', diem: 6.5, soTinChi: 2, isPassed: true, diemTrungBinhLop: 6.8),
            Subject(maMon: 'PHY101', tenMon: 'Vật lý đại cương', diem: 7.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.2),
            Subject(maMon: 'HIS101', tenMon: 'Lịch sử Đảng', diem: 8.0, soTinChi: 2, isPassed: true, diemTrungBinhLop: 7.5),
          ],
        ),
        // Năm 1 - Học kỳ 2
        Semester(
          hocKy: '2021-2022-2',
          namHoc: 2021,
          hocKySo: 2,
          diemRenLuyen: 88.0,
          subjects: [
            Subject(maMon: 'CS102', tenMon: 'Cấu trúc dữ liệu', diem: 9.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.2),
            Subject(maMon: 'MATH102', tenMon: 'Xác suất thống kê', diem: 8.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.5),
            Subject(maMon: 'ENG102', tenMon: 'Tiếng Anh 2', diem: 7.5, soTinChi: 2, isPassed: true, diemTrungBinhLop: 7.0),
            Subject(maMon: 'DB101', tenMon: 'Cơ sở dữ liệu', diem: 8.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.0),
            Subject(maMon: 'NET101', tenMon: 'Mạng máy tính', diem: 7.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 6.8),
          ],
        ),
        // Năm 2 - Học kỳ 1
        Semester(
          hocKy: '2022-2023-1',
          namHoc: 2022,
          hocKySo: 1,
          diemRenLuyen: 90.0,
          subjects: [
            Subject(maMon: 'CS201', tenMon: 'Lập trình hướng đối tượng', diem: 8.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.0),
            Subject(maMon: 'WEB201', tenMon: 'Phát triển Web', diem: 9.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.5),
            Subject(maMon: 'ALG201', tenMon: 'Giải thuật', diem: 8.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.8),
            Subject(maMon: 'OS201', tenMon: 'Hệ điều hành', diem: 7.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.2),
            Subject(maMon: 'SE201', tenMon: 'Kỹ thuật phần mềm', diem: 8.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.5),
          ],
        ),
        // Năm 2 - Học kỳ 2
        Semester(
          hocKy: '2022-2023-2',
          namHoc: 2022,
          hocKySo: 2,
          diemRenLuyen: 92.0,
          subjects: [
            Subject(maMon: 'CS202', tenMon: 'Lập trình Java', diem: 9.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.3),
            Subject(maMon: 'MOB202', tenMon: 'Lập trình di động', diem: 8.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.0),
            Subject(maMon: 'AI202', tenMon: 'Trí tuệ nhân tạo', diem: 7.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.2),
            Subject(maMon: 'SEC202', tenMon: 'An ninh mạng', diem: 8.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.5),
            Subject(maMon: 'PROJ202', tenMon: 'Đồ án 1', diem: 8.5, soTinChi: 2, isPassed: true, diemTrungBinhLop: 8.0),
          ],
        ),
        // Năm 3 - Học kỳ 1
        Semester(
          hocKy: '2023-2024-1',
          namHoc: 2023,
          hocKySo: 1,
          diemRenLuyen: 93.0,
          subjects: [
            Subject(maMon: 'CS301', tenMon: 'Lập trình Python', diem: 9.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.8),
            Subject(maMon: 'CLOUD301', tenMon: 'Điện toán đám mây', diem: 8.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.5),
            Subject(maMon: 'BIG301', tenMon: 'Dữ liệu lớn', diem: 7.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.0),
            Subject(maMon: 'ARCH301', tenMon: 'Kiến trúc phần mềm', diem: 8.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.2),
            Subject(maMon: 'PROJ301', tenMon: 'Đồ án 2', diem: 9.0, soTinChi: 2, isPassed: true, diemTrungBinhLop: 8.5),
          ],
        ),
        // Năm 3 - Học kỳ 2
        Semester(
          hocKy: '2023-2024-2',
          namHoc: 2023,
          hocKySo: 2,
          diemRenLuyen: 95.0,
          subjects: [
            Subject(maMon: 'CS302', tenMon: 'Machine Learning', diem: 8.5, soTinChi: 3, isPassed: true, diemTrungBinhLop: 8.0),
            Subject(maMon: 'DEVOPS302', tenMon: 'DevOps', diem: 8.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 7.8),
            Subject(maMon: 'BLOCK302', tenMon: 'Blockchain', diem: 7.0, soTinChi: 3, isPassed: true, diemTrungBinhLop: 6.5),
            Subject(maMon: 'INTERN302', tenMon: 'Thực tập tốt nghiệp', diem: 9.0, soTinChi: 4, isPassed: true, diemTrungBinhLop: 8.5),
            Subject(maMon: 'THESIS302', tenMon: 'Khóa luận tốt nghiệp', diem: 8.5, soTinChi: 10, isPassed: true, diemTrungBinhLop: 8.2),
          ],
        ),
      ],
    );
  }
}



