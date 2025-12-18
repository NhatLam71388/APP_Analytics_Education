import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/semester.dart';
import '../../services/student_api_service.dart';

class ScoresTable extends StatefulWidget {
  final Semester semester;
  final Animation<double>? animation;

  const ScoresTable({
    super.key,
    required this.semester,
    this.animation,
  });

  @override
  State<ScoresTable> createState() => _ScoresTableState();
}

class _ScoresTableState extends State<ScoresTable> {
  List<SubjectDetailResponse>? _subjectDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubjectDetails();
  }

  Future<void> _loadSubjectDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allSubjectDetails = await StudentApiService.getSubjectDetails();
      
      if (!mounted) return;
      
      // Filter theo học kỳ đúng
      final filteredDetails = _filterBySemester(allSubjectDetails);
      
      setState(() {
        _subjectDetails = filteredDetails;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // Helper method để normalize hocKy
  String _normalizeHocKy(String hocKy) {
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
    // Nếu không có prefix HK, thêm vào
    if (!hocKy.toUpperCase().startsWith('HK')) {
      final numberMatch = RegExp(r'\d+').firstMatch(hocKy);
      if (numberMatch != null) {
        return 'HK${numberMatch.group(0)}';
      }
    }
    return hocKy.toUpperCase();
  }

  // Extract năm học từ semester
  String _extractNamHoc() {
    // semester.hocKy có thể là "HK1 - 2024 - 2025" hoặc "2024-2025-1"
    final parts = widget.semester.hocKy.split('-');
    if (parts.length >= 3) {
      // Tìm năm học (2 số liên tiếp)
      for (int i = 0; i < parts.length - 1; i++) {
        final year1 = int.tryParse(parts[i].trim());
        final year2 = int.tryParse(parts[i + 1].trim());
        if (year1 != null && year2 != null && year2 == year1 + 1) {
          return '${year1}-${year2}';
        }
      }
    }
    // Fallback: dùng namHoc từ semester
    return '${widget.semester.namHoc}-${widget.semester.namHoc + 1}';
  }

  // Extract học kỳ từ semester
  String _extractHocKy() {
    return 'HK${widget.semester.hocKySo}';
  }

  List<SubjectDetailResponse> _filterBySemester(List<SubjectDetailResponse> allDetails) {
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = _normalizeHocKy(hocKy);

    // Normalize năm học để so sánh (xử lý cả "2023 - 2024" và "2023-2024")
    String normalizeNamHoc(String namHocStr) {
      return namHocStr.replaceAll(' ', '').trim();
    }

    final normalizedNamHoc = normalizeNamHoc(namHoc);

    return allDetails.where((detail) {
      final normalizedItemHocKy = _normalizeHocKy(detail.tenHocKy);
      final normalizedDetailNamHoc = normalizeNamHoc(detail.tenNamHoc);
      return normalizedDetailNamHoc == normalizedNamHoc && normalizedItemHocKy == normalizedHocKy;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ semester
    if (_errorMessage != null || _subjectDetails == null || _subjectDetails!.isEmpty) {
      return _buildFromSemester();
    }

    // Sử dụng dữ liệu từ API
    return _buildFromAPI();
  }

  Widget _buildLoadingWidget() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        child: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue.shade600,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildFromSemester() {
    // Sử dụng dữ liệu từ semester như trước
    return _buildTable(widget.semester.subjects.map((subject) {
      return _SubjectRowData(
        tenMon: subject.tenMon,
        soTinChi: subject.soTinChi,
        diemGiuaKy: 0.0,
        diemCuoiKy: 0.0,
        diem: subject.diem,
        xepLoai: '',
        diemHe4: 0,
        isPassed: subject.isPassed,
      );
    }).toList());
  }

  Widget _buildFromAPI() {
    // Sử dụng dữ liệu từ API
    final rows = _subjectDetails!.map((detail) {
      return _SubjectRowData(
        tenMon: detail.tenMonHoc,
        soTinChi: detail.soTinChiInt,
        diemGiuaKy: detail.diemGiuaKyDouble,
        diemCuoiKy: detail.diemCuoiKyDouble,
        diem: detail.diemTrungBinh,
        xepLoai: detail.xepLoai,
        diemHe4: detail.diemHe4,
        isPassed: detail.isPassed,
      );
    }).toList();
    return _buildTable(rows);
  }

  Widget _buildTable(List<_SubjectRowData> rows) {
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
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (context, scaleValue, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * scaleValue),
              child: child,
            );
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.indigo.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.3),
                        blurRadius: 25,
                        spreadRadius: 3,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: -5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.rotate(
                            angle: (1 - value) * 0.3,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo.shade400,
                              Colors.indigo.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.table_chart,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'Chi Tiết Điểm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.indigo.shade50,
                      ),
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 60,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Tên môn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Tín chỉ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Điểm Giữa Kỳ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Điểm Cuối Kỳ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Điểm TB',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Xếp loại',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Điểm hệ 4',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Kết quả',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      rows: rows.asMap().entries.map((entry) {
                        final row = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  row.tenMon,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${row.soTinChi}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: _buildDiemCell(row.diemGiuaKy),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: _buildDiemCell(row.diemCuoiKy),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: row.isPassed
                                          ? [Colors.green.shade400, Colors.green.shade600]
                                          : [Colors.red.shade400, Colors.red.shade600],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (row.isPassed
                                                ? Colors.green
                                                : Colors.red)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    row.diem.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getXepLoaiColor(row.xepLoai).shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getXepLoaiColor(row.xepLoai).shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    row.xepLoai.isNotEmpty ? row.xepLoai : '-',
                                    style: TextStyle(
                                      color: _getXepLoaiColor(row.xepLoai).shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.purple.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    row.diemHe4 > 0 ? '${row.diemHe4}' : '-',
                                    style: TextStyle(
                                      color: Colors.purple.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: row.isPassed
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    gradient: LinearGradient(
                                      colors: row.isPassed
                                          ? [
                                              Colors.green.shade100,
                                              Colors.green.shade50,
                                            ]
                                          : [
                                              Colors.red.shade100,
                                              Colors.red.shade50,
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (row.isPassed
                                                ? Colors.green
                                                : Colors.red)
                                            .withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        row.isPassed
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 14,
                                        color: row.isPassed
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        row.isPassed ? 'Đậu' : 'Rớt',
                                        style: TextStyle(
                                          color: row.isPassed
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
          ),
        ),
      ),
    );
  }

  // Helper method để build cell cho điểm thành phần
  Widget _buildDiemCell(double diem) {
    if (diem == 0.0) {
      return Text(
        '-',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
      ),
      child: Text(
        diem.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.amber.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // Helper method để lấy màu theo xếp loại
  MaterialColor _getXepLoaiColor(String xepLoai) {
    switch (xepLoai.toLowerCase()) {
      case 'xuất sắc':
      case 'giỏi':
        return Colors.green;
      case 'khá':
        return Colors.blue;
      case 'trung bình':
        return Colors.orange;
      case 'yếu':
      case 'kém':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Helper class để chứa dữ liệu cho mỗi row
class _SubjectRowData {
  final String tenMon;
  final int soTinChi;
  final double diemGiuaKy;
  final double diemCuoiKy;
  final double diem;
  final String xepLoai;
  final int diemHe4;
  final bool isPassed;

  _SubjectRowData({
    required this.tenMon,
    required this.soTinChi,
    required this.diemGiuaKy,
    required this.diemCuoiKy,
    required this.diem,
    required this.xepLoai,
    required this.diemHe4,
    required this.isPassed,
  });
}

