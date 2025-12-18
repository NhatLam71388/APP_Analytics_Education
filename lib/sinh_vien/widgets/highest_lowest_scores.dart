import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/student_academic.dart';
import '../../models/semester.dart';
import '../../models/subject.dart';
import '../../services/student_api_service.dart';

class HighestLowestScores extends StatefulWidget {
  final StudentAcademic studentData;
  final Semester semester;
  final Animation<double>? animation;

  const HighestLowestScores({
    super.key,
    required this.studentData,
    required this.semester,
    this.animation,
  });

  @override
  State<HighestLowestScores> createState() => _HighestLowestScoresState();
}

class _HighestLowestScoresState extends State<HighestLowestScores> {
  HighestScoreResponse? _highestScore;
  LowestScoreResponse? _lowestScore;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allHighestScores = await StudentApiService.getHighestScores();
      final allLowestScores = await StudentApiService.getLowestScores();
      
      if (!mounted) return;
      
      // Tìm đúng học kỳ
      final matchedHighest = _findMatchingHighest(allHighestScores);
      final matchedLowest = _findMatchingLowest(allLowestScores);
      
      setState(() {
        _highestScore = matchedHighest;
        _lowestScore = matchedLowest;
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

  HighestScoreResponse? _findMatchingHighest(List<HighestScoreResponse> allScores) {
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

  LowestScoreResponse? _findMatchingLowest(List<LowestScoreResponse> allScores) {
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

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ semester
    if (_errorMessage != null || (_highestScore == null && _lowestScore == null)) {
      return _buildFromSemester();
    }

    // Sử dụng dữ liệu từ API
    return _buildFromAPI();
  }

  Widget _buildLoadingWidget() {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 150,
              child: Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue.shade600,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 150,
              child: Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue.shade600,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFromSemester() {
    final highest = widget.studentData.getHighestScoreSubject(widget.semester.hocKy);
    final lowest = widget.studentData.getLowestScoreSubject(widget.semester.hocKy);

    return _buildContent(highest, lowest);
  }

  Widget _buildFromAPI() {
    // Tạo Subject objects từ API response để tương thích với _ScoreCard
    Subject? highestSubject;
    Subject? lowestSubject;
    
    if (_highestScore != null) {
      highestSubject = Subject(
        maMon: '', // Không có mã môn từ API
        tenMon: _highestScore!.tenMonHoc,
        soTinChi: 0, // Không có số tín chỉ từ API
        diem: _highestScore!.dtb,
        isPassed: _highestScore!.dtb >= 5.0,
      );
    }
    
    if (_lowestScore != null) {
      lowestSubject = Subject(
        maMon: '', // Không có mã môn từ API
        tenMon: _lowestScore!.tenMonHoc,
        soTinChi: 0, // Không có số tín chỉ từ API
        diem: _lowestScore!.dtb,
        isPassed: _lowestScore!.dtb >= 5.0,
      );
    }
    
    return _buildContent(highestSubject, lowestSubject);
  }

  Widget _buildContent(Subject? highest, Subject? lowest) {
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
        child: Row(
          children: [
            Expanded(
              child: _ScoreCard(
                title: 'Điểm cao nhất',
                subject: highest,
                color: Colors.green,
                icon: Icons.trending_up,
                delay: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScoreCard(
                title: 'Điểm thấp nhất',
                subject: lowest,
                color: Colors.red,
                icon: Icons.trending_down,
                delay: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final Subject? subject;
  final MaterialColor color;
  final IconData icon;
  final int delay;

  const _ScoreCard({
    required this.title,
    required this.subject,
    required this.color,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.shade300,
                color.shade500,
                color.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (subject != null) ...[
                 Text(
                   subject!.tenMon,
                   style: const TextStyle(
                     color: Colors.white,
                     fontSize: 13,
                     fontWeight: FontWeight.w600,
                     height: 1.2,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 10),
                 TweenAnimationBuilder<double>(
                   tween: Tween(begin: 0.0, end: subject!.diem),
                   duration: const Duration(milliseconds: 1000),
                   curve: Curves.easeOutCubic,
                   builder: (context, value, child) {
                     return Text(
                       value.toStringAsFixed(1),
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 28,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 0.5,
                       ),
                     );
                   },
                 ),
              ] else
                const Text(
                  'N/A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

