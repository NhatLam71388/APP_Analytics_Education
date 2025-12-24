import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/class_model.dart';
import '../../services/teacher_api_service.dart';

class LowestFailRateSubjectCard extends StatefulWidget {
  final ClassModel classModel;
  final ClassSemesterData semester;
  final Animation<double>? animation;

  const LowestFailRateSubjectCard({
    super.key,
    required this.classModel,
    required this.semester,
    this.animation,
  });

  @override
  State<LowestFailRateSubjectCard> createState() => _LowestFailRateSubjectCardState();
}

class _LowestFailRateSubjectCardState extends State<LowestFailRateSubjectCard> {
  SubjectFailRateLowResponse? _subjectData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allData = await TeacherApiService.getSubjectFailRateLow();

      if (!mounted) return;

      // Debug: In ra thông tin để kiểm tra
      debugPrint('🔍 LowestFailRateSubjectCard - Loading data:');
      debugPrint('  - Class: ${widget.classModel.tenLop} / ${widget.classModel.maLop}');
      debugPrint('  - Semester: ${widget.semester.hocKy}');
      debugPrint('  - Total data from API: ${allData.length}');

      // Lọc dữ liệu theo lớp (không lọc theo học kỳ và năm học)
      final filteredData = allData.where((item) {
        final matchesClass = item.tenLop == widget.classModel.tenLop ||
            item.tenLop == widget.classModel.maLop ||
            item.tenLop.trim() == widget.classModel.tenLop.trim() ||
            item.tenLop.trim() == widget.classModel.maLop.trim();

        if (matchesClass) {
          debugPrint('  ✅ Match found: ${item.tenMonHoc} - ${item.tenNamHoc} - ${item.tenHocKy}');
        }

        return matchesClass;
      }).toList();

      debugPrint('  - Filtered data: ${filteredData.length}');

      // Tìm môn học có tỷ lệ rớt thấp nhất
      SubjectFailRateLowResponse? lowestFailRate;
      if (filteredData.isNotEmpty) {
        lowestFailRate = filteredData.reduce((a, b) =>
            a.tyLeRot < b.tyLeRot ? a : b);
      }

      setState(() {
        _subjectData = lowestFailRate;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
              color: Colors.green.shade600,
              size: 40,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? 'Không thể tải dữ liệu',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_subjectData == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Chưa có dữ liệu môn học rớt thấp nhất',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

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
            final clampedValue = scaleValue.clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.95 + (0.05 * clampedValue),
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
                        Colors.green.shade100.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.9),
                        Colors.green.shade50.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Môn học rớt thấp nhất',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _subjectData!.tenMonHoc,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Năm học',
                              _subjectData!.tenNamHoc,
                              Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItem(
                              'Học kỳ',
                              _subjectData!.tenHocKy,
                              Icons.school,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Tổng SV',
                              '${_subjectData!.tongSv}',
                              Icons.people,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItem(
                              'SV rớt',
                              '${_subjectData!.svRot}',
                              Icons.person_off,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Tỷ lệ rớt',
                              '${(_subjectData!.tyLeRot * 100).toStringAsFixed(2)}%',
                              Icons.percent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItem(
                              'ĐTB',
                              _subjectData!.dtb.toStringAsFixed(2),
                              Icons.grade,
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
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}




