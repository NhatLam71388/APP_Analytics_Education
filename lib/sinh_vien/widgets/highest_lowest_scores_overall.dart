import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/student_academic.dart';
import '../../models/subject.dart';
import '../../services/student_api_service.dart';
import '../../services/teacher_api_service.dart';

class HighestLowestScoresOverall extends StatefulWidget {
  final StudentAcademic studentData;
  final Animation<double>? animation;
  final String? masv; // Optional: nếu có thì load từ teacher APIs

  const HighestLowestScoresOverall({
    super.key,
    required this.studentData,
    this.animation,
    this.masv,
  });

  @override
  State<HighestLowestScoresOverall> createState() => _HighestLowestScoresOverallState();
}

class _HighestLowestScoresOverallState extends State<HighestLowestScoresOverall> {
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

      // Sử dụng teacher API nếu có masv, ngược lại dùng student API
      // Note: Teacher APIs có thể không có methods riêng cho highest/lowest scores
      // Nên vẫn dùng student APIs (chúng có thể hoạt động với teacher token)
      final allHighestScores = await StudentApiService.getHighestScores();
      final allLowestScores = await StudentApiService.getLowestScores();
      
      if (!mounted) return;
      
      // Tìm điểm cao nhất và thấp nhất từ tất cả các học kỳ
      final highest = _findHighestOverall(allHighestScores);
      final lowest = _findLowestOverall(allLowestScores);
      
      setState(() {
        _highestScore = highest;
        _lowestScore = lowest;
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

  // Tìm điểm cao nhất từ tất cả các học kỳ
  HighestScoreResponse? _findHighestOverall(List<HighestScoreResponse> allScores) {
    if (allScores.isEmpty) return null;
    
    HighestScoreResponse? highest;
    for (var score in allScores) {
      if (highest == null || score.dtb > highest.dtb) {
        highest = score;
      }
    }
    return highest;
  }

  // Tìm điểm thấp nhất từ tất cả các học kỳ
  LowestScoreResponse? _findLowestOverall(List<LowestScoreResponse> allScores) {
    if (allScores.isEmpty) return null;
    
    LowestScoreResponse? lowest;
    for (var score in allScores) {
      if (lowest == null || score.dtb < lowest.dtb) {
        lowest = score;
      }
    }
    return lowest;
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ studentData
    if (_errorMessage != null || (_highestScore == null && _lowestScore == null)) {
      return _buildFromStudentData();
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

  Widget _buildFromStudentData() {
    Subject? highest;
    for (var semester in widget.studentData.semesters) {
      for (var subject in semester.subjects) {
        if (highest == null || subject.diem > highest.diem) {
          highest = subject;
        }
      }
    }

    Subject? lowest;
    for (var semester in widget.studentData.semesters) {
      for (var subject in semester.subjects) {
        if (lowest == null || subject.diem < lowest.diem) {
          lowest = subject;
        }
      }
    }

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








