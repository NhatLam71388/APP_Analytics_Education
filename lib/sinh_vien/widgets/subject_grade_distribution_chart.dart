import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/student_academic.dart';
import '../../services/student_api_service.dart';
import '../../services/teacher_api_service.dart';

class SubjectGradeDistributionChart extends StatefulWidget {
  final StudentAcademic studentData;
  final Animation<double>? animation;
  final SubjectGradeRateResponse? gradeRate; // Optional: nếu có thì dùng dữ liệu này thay vì fetch từ API
  final String? masv; // Optional: nếu có thì load từ teacher APIs

  const SubjectGradeDistributionChart({
    super.key,
    required this.studentData,
    this.animation,
    this.gradeRate,
    this.masv,
  });

  @override
  State<SubjectGradeDistributionChart> createState() => _SubjectGradeDistributionChartState();
}

class _SubjectGradeDistributionChartState extends State<SubjectGradeDistributionChart> {
  List<SubjectGradeRateResponse>? _gradeRates;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGradeRates();
  }

  Future<void> _loadGradeRates() async {
    // Nếu đã có gradeRate từ parent, không cần fetch từ API
    if (widget.gradeRate != null) {
      setState(() {
        _gradeRates = [widget.gradeRate!];
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Sử dụng teacher API nếu có masv, ngược lại dùng student API
      final gradeRates = widget.masv != null
          ? await TeacherApiService.getSubjectGradeRateByMasv(widget.masv!)
          : await StudentApiService.getSubjectGradeRate();
      
      if (!mounted) return;
      
      setState(() {
        _gradeRates = gradeRates;
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
    // Nếu đang loading, hiển thị loading widget
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Nếu có lỗi hoặc không có dữ liệu từ API, fallback về dữ liệu từ studentData
    if (_errorMessage != null || _gradeRates == null || _gradeRates!.isEmpty) {
      if (widget.studentData.semesters.isEmpty) {
        return const SizedBox.shrink();
      }
      return _buildFromStudentData();
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
        height: 400,
        child: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue.shade600,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildFromStudentData() {
    // Tính tỷ lệ các loại điểm từ studentData
    int gioi = 0, kha = 0, trungBinh = 0, yeu = 0;
    int totalSubjects = 0;

    for (var semester in widget.studentData.semesters) {
      for (var subject in semester.subjects) {
        totalSubjects++;
        final gradeLevel = subject.getGradeLevel();
        switch (gradeLevel) {
          case 'Giỏi':
            gioi++;
            break;
          case 'Khá':
            kha++;
            break;
          case 'Trung bình':
            trungBinh++;
            break;
          case 'Yếu':
            yeu++;
            break;
        }
      }
    }

    final gioiPercent = totalSubjects > 0 ? (gioi / totalSubjects) * 100 : 0.0;
    final khaPercent = totalSubjects > 0 ? (kha / totalSubjects) * 100 : 0.0;
    final trungBinhPercent = totalSubjects > 0 ? (trungBinh / totalSubjects) * 100 : 0.0;
    final yeuPercent = totalSubjects > 0 ? (yeu / totalSubjects) * 100 : 0.0;

    return _buildContent(
      gioiPercent: gioiPercent,
      khaPercent: khaPercent,
      trungBinhPercent: trungBinhPercent,
      yeuPercent: yeuPercent,
      gioi: gioi,
      kha: kha,
      trungBinh: trungBinh,
      yeu: yeu,
    );
  }

  Widget _buildFromAPI() {
    // Kiểm tra xem có format mới không (từ teacher API)
    final hasNewFormat = _gradeRates!.any((rate) => rate.isNewFormat);
    
    if (hasNewFormat) {
      // Sử dụng format mới (Giỏi, Khá, Trung bình, Yếu)
      return _buildContentWithAcademicLevels();
    }
    
    // Nếu chỉ có 1 học kỳ (từ semester cụ thể), hiển thị dữ liệu của học kỳ đó
    if (_gradeRates!.length == 1) {
      final rate = _gradeRates!.first;
      return _buildContentWithLetterGrades(
        gradeRate: rate,
      );
    }

    // Tổng hợp dữ liệu từ tất cả các học kỳ
    return _buildContentWithAggregatedGrades();
  }
  
  Widget _buildContentWithAcademicLevels() {
    // Tổng hợp dữ liệu từ tất cả các học kỳ (format mới)
    // Format mới trả về tỷ lệ tổng hợp, không cần tính trung bình
    double totalTyLeGioi = 0.0;
    double totalTyLeKha = 0.0;
    double totalTyLeTb = 0.0;
    double totalTyLeYeu = 0.0;
    int totalTongMon = 0;
    
    // Tính tổng số môn từ studentData nếu có
    if (widget.studentData.semesters.isNotEmpty) {
      for (var semester in widget.studentData.semesters) {
        totalTongMon += semester.subjects.length;
      }
    }
    
    // Lấy dữ liệu từ rate đầu tiên (format mới chỉ có 1 record tổng hợp)
    final rate = _gradeRates!.firstWhere(
      (r) => r.isNewFormat,
      orElse: () => _gradeRates!.first,
    );
    
    if (rate.isNewFormat) {
      totalTyLeGioi = rate.tyLeGioi ?? 0.0;
      totalTyLeKha = rate.tyLeKha ?? 0.0;
      totalTyLeTb = rate.tyLeTb ?? 0.0;
      totalTyLeYeu = rate.tyLeYeu ?? 0.0;
    }
    
    // Tính số lượng môn từ tỷ lệ
    final soGioi = (totalTyLeGioi * totalTongMon).round();
    final soKha = (totalTyLeKha * totalTongMon).round();
    final soTb = (totalTyLeTb * totalTongMon).round();
    final soYeu = (totalTyLeYeu * totalTongMon).round();
    
    // Tạo danh sách các học lực với màu sắc
    final gradeSections = [
      _GradeSection(
        label: 'Giỏi',
        value: totalTyLeGioi * 100,
        count: soGioi,
        color: Colors.green.shade600,
      ),
      _GradeSection(
        label: 'Khá',
        value: totalTyLeKha * 100,
        count: soKha,
        color: Colors.blue.shade600,
      ),
      _GradeSection(
        label: 'Trung bình',
        value: totalTyLeTb * 100,
        count: soTb,
        color: Colors.orange.shade600,
      ),
      _GradeSection(
        label: 'Yếu',
        value: totalTyLeYeu * 100,
        count: soYeu,
        color: Colors.red.shade600,
      ),
    ].where((section) => section.value > 0).toList();
    
    return _buildContentWithSections(
      gradeSections: gradeSections,
      tongMon: totalTongMon,
    );
  }

  Widget _buildContentWithAggregatedGrades() {
    // Tổng hợp dữ liệu từ tất cả các học kỳ
    int totalTongMon = 0;
    int totalSoA = 0;
    int totalSoBPlus = 0;
    int totalSoB = 0;
    int totalSoCPlus = 0;
    int totalSoC = 0;
    int totalSoDPlus = 0;
    int totalSoD = 0;
    int totalSoF = 0;

    for (var rate in _gradeRates!) {
      totalTongMon += rate.tongMon;
      totalSoA += rate.soA;
      totalSoBPlus += rate.soBPlus;
      totalSoB += rate.soB;
      totalSoCPlus += rate.soCPlus;
      totalSoC += rate.soC;
      totalSoDPlus += rate.soDPlus;
      totalSoD += rate.soD;
      totalSoF += rate.soF;
    }

    // Tính tỷ lệ từ tổng số môn
    final tyLeA = totalTongMon > 0 ? (totalSoA / totalTongMon) : 0.0;
    final tyLeBPlus = totalTongMon > 0 ? (totalSoBPlus / totalTongMon) : 0.0;
    final tyLeB = totalTongMon > 0 ? (totalSoB / totalTongMon) : 0.0;
    final tyLeCPlus = totalTongMon > 0 ? (totalSoCPlus / totalTongMon) : 0.0;
    final tyLeC = totalTongMon > 0 ? (totalSoC / totalTongMon) : 0.0;
    final tyLeDPlus = totalTongMon > 0 ? (totalSoDPlus / totalTongMon) : 0.0;
    final tyLeD = totalTongMon > 0 ? (totalSoD / totalTongMon) : 0.0;
    final tyLeF = totalTongMon > 0 ? (totalSoF / totalTongMon) : 0.0;

    // Tạo gradeRate tổng hợp
    final aggregatedRate = SubjectGradeRateResponse(
      tenNamHoc: '', // Không có năm học cụ thể khi tổng hợp
      tenHocKy: '', // Không có học kỳ cụ thể khi tổng hợp
      maSinhVien: _gradeRates!.isNotEmpty ? _gradeRates!.first.maSinhVien : '',
      tongMon: totalTongMon,
      soA: totalSoA,
      soBPlus: totalSoBPlus,
      soB: totalSoB,
      soCPlus: totalSoCPlus,
      soC: totalSoC,
      soDPlus: totalSoDPlus,
      soD: totalSoD,
      soF: totalSoF,
      tyLeA: tyLeA,
      tyLeBPlus: tyLeBPlus,
      tyLeB: tyLeB,
      tyLeCPlus: tyLeCPlus,
      tyLeC: tyLeC,
      tyLeDPlus: tyLeDPlus,
      tyLeD: tyLeD,
      tyLeF: tyLeF,
    );

    return _buildContentWithLetterGrades(
      gradeRate: aggregatedRate,
    );
  }

  Widget _buildContentWithSections({
    required List<_GradeSection> gradeSections,
    required int tongMon,
  }) {
    return _buildPieChartWidget(
      gradeSections: gradeSections,
      tongMon: tongMon,
    );
  }

  Widget _buildContentWithLetterGrades({
    required SubjectGradeRateResponse gradeRate,
  }) {
    // Tạo danh sách các điểm chữ với màu sắc
    final gradeSections = [
      _GradeSection(
        label: 'A',
        value: gradeRate.tyLeA * 100,
        count: gradeRate.soA,
        color: Colors.purple.shade600,
      ),
      _GradeSection(
        label: 'B+',
        value: gradeRate.tyLeBPlus * 100,
        count: gradeRate.soBPlus,
        color: Colors.blue.shade600,
      ),
      _GradeSection(
        label: 'B',
        value: gradeRate.tyLeB * 100,
        count: gradeRate.soB,
        color: Colors.cyan.shade600,
      ),
      _GradeSection(
        label: 'C+',
        value: gradeRate.tyLeCPlus * 100,
        count: gradeRate.soCPlus,
        color: Colors.green.shade600,
      ),
      _GradeSection(
        label: 'C',
        value: gradeRate.tyLeC * 100,
        count: gradeRate.soC,
        color: Colors.orange.shade600,
      ),
      _GradeSection(
        label: 'D+',
        value: gradeRate.tyLeDPlus * 100,
        count: gradeRate.soDPlus,
        color: Colors.deepOrange.shade600,
      ),
      _GradeSection(
        label: 'D',
        value: gradeRate.tyLeD * 100,
        count: gradeRate.soD,
        color: Colors.red.shade600,
      ),
      _GradeSection(
        label: 'F',
        value: gradeRate.tyLeF * 100,
        count: gradeRate.soF,
        color: Colors.red.shade900,
      ),
    ].where((section) => section.value > 0).toList();

    return _buildPieChartWidget(
      gradeSections: gradeSections,
      tongMon: gradeRate.tongMon,
    );
  }

  Widget _buildPieChartWidget({
    required List<_GradeSection> gradeSections,
    required int tongMon,
  }) {
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
                              final clampedValue = value.clamp(0.0, 1.0);
                              return Transform.scale(
                                scale: clampedValue,
                                child: Transform.rotate(
                                  angle: (1 - clampedValue) * 0.3,
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
                                Icons.pie_chart,
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
                                final clampedValue = value.clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: clampedValue,
                                  child: Transform.translate(
                                    offset: Offset(20 * (1 - clampedValue), 0),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tỷ lệ môn học đạt loại của sinh viên',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tổng số môn: $tongMon',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: gradeSections.asMap().entries.map((entry) {
                              final index = entry.key;
                              final section = entry.value;
                              return PieChartSectionData(
                                value: section.value,
                                title: section.value > 0 ? '${section.value.toStringAsFixed(1)}%' : '',
                                color: section.color,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                showTitle: section.value > 0,
                              );
                            }).toList(),
                            pieTouchData: PieTouchData(
                              enabled: false, // Tắt hover/touch
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Legend với điểm chữ
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: gradeSections.map((section) {
                          return _buildLegendItem(
                            section.color,
                            section.label,
                            section.value,
                            section.count,
                          );
                        }).toList(),
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

  Widget _buildContent({
    required double gioiPercent,
    required double khaPercent,
    required double trungBinhPercent,
    required double yeuPercent,
    required int gioi,
    required int kha,
    required int trungBinh,
    required int yeu,
  }) {

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
                              final clampedValue = value.clamp(0.0, 1.0);
                              return Transform.scale(
                                scale: clampedValue,
                                child: Transform.rotate(
                                  angle: (1 - clampedValue) * 0.3,
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
                                Icons.pie_chart,
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
                                final clampedValue = value.clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: clampedValue,
                                  child: Transform.translate(
                                    offset: Offset(20 * (1 - clampedValue), 0),
                                    child: child,
                                  ),
                                );
                              },
                              child: const Text(
                                'Tỷ lệ môn đạt loại giỏi, khá, trung bình, yếu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                value: gioiPercent,
                                title: '${gioiPercent.toStringAsFixed(1)}%',
                                color: Colors.green.shade600,
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: khaPercent,
                                title: '${khaPercent.toStringAsFixed(1)}%',
                                color: Colors.blue.shade600,
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: trungBinhPercent,
                                title: '${trungBinhPercent.toStringAsFixed(1)}%',
                                color: Colors.orange.shade600,
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: yeuPercent,
                                title: '${yeuPercent.toStringAsFixed(1)}%',
                                color: Colors.red.shade600,
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Legend thành 2 dòng
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLegendItem(Colors.green, 'Giỏi', gioiPercent, gioi),
                                  const SizedBox(height: 12),
                                  _buildLegendItem(Colors.blue, 'Khá', khaPercent, kha),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLegendItem(Colors.orange, 'Trung bình', trungBinhPercent, trungBinh),
                                  const SizedBox(height: 12),
                                  _buildLegendItem(Colors.red, 'Yếu', yeuPercent, yeu),
                                ],
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
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double percent, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Điểm $label',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '$count môn (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Helper class để chứa thông tin về điểm chữ
class _GradeSection {
  final String label;
  final double value;
  final int count;
  final Color color;

  _GradeSection({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });
}

