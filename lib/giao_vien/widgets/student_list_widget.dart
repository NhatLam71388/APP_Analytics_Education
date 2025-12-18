import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../services/teacher_api_service.dart';
import '../../models/class_model.dart';
import '../../widgets/salomon_tab_bar_wrapper.dart';
import '../../sinh_vien/sinh_vien_home.dart';

class StudentListWidget extends StatefulWidget {
  final ClassModel classModel;
  final ClassSemesterData semester;
  final Animation<double>? animation;

  const StudentListWidget({
    super.key,
    required this.classModel,
    required this.semester,
    this.animation,
  });

  @override
  State<StudentListWidget> createState() => _StudentListWidgetState();
}

class _StudentListWidgetState extends State<StudentListWidget> {
  List<ClassStudentListResponse> _students = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Lấy danh sách sinh viên từ API
      final students = await TeacherApiService.getClassStudentsList(
        widget.classModel.tenLop,
      );

      // Nhóm theo mã sinh viên (lấy bản ghi mới nhất cho mỗi sinh viên)
      final Map<String, ClassStudentListResponse> uniqueStudents = {};
      
      for (var student in students) {
        final maSinhVien = student.maSinhVien;
        
        // Nếu chưa có sinh viên này hoặc bản ghi hiện tại mới hơn
        if (!uniqueStudents.containsKey(maSinhVien)) {
          uniqueStudents[maSinhVien] = student;
        } else {
          final existing = uniqueStudents[maSinhVien]!;
          // So sánh năm học và học kỳ để lấy bản ghi mới nhất
          final existingYear = int.tryParse(existing.tenNamHoc.split('-').first) ?? 0;
          final currentYear = int.tryParse(student.tenNamHoc.split('-').first) ?? 0;
          
          if (currentYear > existingYear) {
            uniqueStudents[maSinhVien] = student;
          } else if (currentYear == existingYear) {
            // Nếu cùng năm học, so sánh học kỳ
            final existingSemester = int.tryParse(existing.tenHocKy.replaceAll('HK', '')) ?? 0;
            final currentSemester = int.tryParse(student.tenHocKy.replaceAll('HK', '')) ?? 0;
            
            if (currentSemester > existingSemester) {
              uniqueStudents[maSinhVien] = student;
            }
          }
        }
      }

      // Chuyển map thành list và sắp xếp theo GPA giảm dần
      final studentList = uniqueStudents.values.toList();
      studentList.sort((a, b) => b.gpaHocKy.compareTo(a.gpaHocKy));

      if (mounted) {
        setState(() {
          _students = studentList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _getGPAStatus(double gpa) {
    if (gpa >= 8.0) return 'Giỏi';
    if (gpa >= 6.5) return 'Khá';
    if (gpa >= 5.0) return 'Trung bình';
    if (gpa > 0) return 'Yếu';
    return 'Chưa có điểm';
  }

  Color _getGPAColor(double gpa) {
    if (gpa >= 8.0) return Colors.green;
    if (gpa >= 6.5) return Colors.blue;
    if (gpa >= 5.0) return Colors.orange;
    if (gpa > 0) return Colors.red;
    return Colors.grey;
  }

  void _onStudentTap(ClassStudentListResponse student) {
    final parentContext = context;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (newContext) => wrapWithSalomonTabBar(
          parentContext,
          SinhVienHome(
            masv: student.maSinhVien,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: widget.animation != null
            ? Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: widget.animation!,
                curve: Curves.easeOutCubic,
              ))
            : const AlwaysStoppedAnimation(Offset.zero),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.green.shade50,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.people,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Danh sách sinh viên',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tổng: ${_students.length} sinh viên',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.blue.shade600,
                            size: 50,
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade300,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadStudents,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_students.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Colors.grey.shade300,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Không có sinh viên nào',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _isExpanded || _students.length <= 5
                                ? _students.length
                                : 5,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onStudentTap(student),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        // Số thứ tự
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Thông tin sinh viên
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.hoTen,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student.maSinhVien,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.green.shade600,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_students.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _isExpanded
                                                ? 'Thu gọn'
                                                : 'Xem thêm (${_students.length - 5})',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            _isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.green.shade700,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

