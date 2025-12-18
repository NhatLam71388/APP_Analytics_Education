import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/semester.dart';
import '../../services/student_api_service.dart';

class ConductScoreCard extends StatefulWidget {
  final Semester semester;
  final Animation<double>? animation;

  const ConductScoreCard({
    super.key,
    required this.semester,
    this.animation,
  });

  @override
  State<ConductScoreCard> createState() => _ConductScoreCardState();
}

class _ConductScoreCardState extends State<ConductScoreCard> {
  ConductScoreResponse? _conductScore;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConductScore();
  }

  Future<void> _loadConductScore() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allConductScores = await StudentApiService.getConductScores();
      
      if (!mounted) return;
      
      // Tìm đúng học kỳ
      final matchedScore = _findMatchingSemester(allConductScores);
      
      setState(() {
        _conductScore = matchedScore;
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

  ConductScoreResponse? _findMatchingSemester(List<ConductScoreResponse> allScores) {
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = _normalizeHocKy(hocKy);

    for (var score in allScores) {
      final normalizedItemHocKy = _normalizeHocKy(score.tenHocKy);
      if (score.tenNamHoc == namHoc && normalizedItemHocKy == normalizedHocKy) {
        return score;
      }
    }
    return null;
  }

  // Xác định xếp loại rèn luyện
  String _getXepLoai(double drl) {
    if (drl >= 90) return 'Xuất sắc';
    if (drl >= 80) return 'Tốt';
    if (drl >= 70) return 'Khá';
    if (drl >= 60) return 'Trung bình';
    if (drl >= 50) return 'Yếu';
    return 'Kém';
  }

  Color _getXepLoaiColor(double drl) {
    if (drl >= 90) return Colors.purple;
    if (drl >= 80) return Colors.green;
    if (drl >= 70) return Colors.blue;
    if (drl >= 60) return Colors.orange;
    if (drl >= 50) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ semester
    if (_errorMessage != null || _conductScore == null) {
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
        height: 200,
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
    final drl = widget.semester.diemRenLuyen ?? 0.0;
    return _buildContent(drl);
  }

  Widget _buildFromAPI() {
    final drl = _conductScore!.drl;
    return _buildContent(drl);
  }

  Widget _buildContent(double drl) {
    final xepLoai = _getXepLoai(drl);
    final xepLoaiColor = _getXepLoaiColor(drl);

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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade100.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.9),
                      Colors.teal.shade50.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.3),
                      blurRadius: 25,
                      spreadRadius: 3,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Điểm Rèn Luyện',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: drl),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                              letterSpacing: 1.2,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: xepLoaiColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          xepLoai,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: xepLoaiColor,
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
    );
  }
}






