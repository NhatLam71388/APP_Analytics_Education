import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/semester.dart';
import '../../services/student_api_service.dart';

class SemesterCreditCard extends StatefulWidget {
  final Semester semester;
  final Animation<double>? animation;

  const SemesterCreditCard({
    super.key,
    required this.semester,
    this.animation,
  });

  @override
  State<SemesterCreditCard> createState() => _SemesterCreditCardState();
}

class _SemesterCreditCardState extends State<SemesterCreditCard> {
  CreditResponse? _creditData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCreditData();
  }

  Future<void> _loadCreditData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allCredits = await StudentApiService.getCreditInfo();
      
      if (!mounted) return;
      
      // Tìm đúng học kỳ
      final matchedCredit = _findMatchingSemester(allCredits);
      
      setState(() {
        _creditData = matchedCredit;
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

  // Normalize năm học để so sánh
  String _normalizeNamHoc(String namHoc) {
    return namHoc.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Normalize học kỳ
  String _normalizeHocKy(String hocKy) {
    if (hocKy.contains('_')) {
      final parts = hocKy.split('_');
      if (parts.length > 1) {
        return 'HK${parts[1]}';
      }
    }
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
    final parts = widget.semester.hocKy.split('-');
    if (parts.length >= 3) {
      for (int i = 0; i < parts.length - 1; i++) {
        final year1 = int.tryParse(parts[i].trim());
        final year2 = int.tryParse(parts[i + 1].trim());
        if (year1 != null && year2 != null && year2 == year1 + 1) {
          return '$year1 - $year2';
        }
      }
    }
    return '${widget.semester.namHoc} - ${widget.semester.namHoc + 1}';
  }

  // Extract học kỳ từ semester
  String _extractHocKy() {
    return 'HK${widget.semester.hocKySo}';
  }

  CreditResponse? _findMatchingSemester(List<CreditResponse> allCredits) {
    final namHoc = _extractNamHoc();
    final hocKy = _extractHocKy();
    final normalizedHocKy = _normalizeHocKy(hocKy);
    final normalizedNamHoc = _normalizeNamHoc(namHoc);

    for (var credit in allCredits) {
      final normalizedItemHocKy = _normalizeHocKy(credit.tenHocKy);
      final normalizedItemNamHoc = _normalizeNamHoc(credit.tenNamHoc);
      
      if (normalizedItemNamHoc == normalizedNamHoc && normalizedItemHocKy == normalizedHocKy) {
        return credit;
      }
    }
    return null;
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
          height: 120,
          child: Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.indigo.shade600,
              size: 30,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || _creditData == null) {
      return const SizedBox.shrink();
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
                      // Header với icon và title
                      Row(
                        children: [
                          Container(
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
                              Icons.school,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Số tín chỉ đăng ký',
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
                      const SizedBox(height: 24),
                      // Số tín chỉ lớn ở giữa
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: _creditData!.tongTinChi.toDouble()),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                                letterSpacing: 1.2,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Label ở giữa
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.indigo.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'tín chỉ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade700,
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
}

