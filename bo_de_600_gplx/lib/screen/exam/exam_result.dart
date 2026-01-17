import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bo_de_600_gplx/services/history_service.dart';
import 'package:bo_de_600_gplx/screen/exam/exam_review.dart';
import 'package:bo_de_600_gplx/models/question.dart';

class ExamResultPage extends StatefulWidget {
  final String examId;
  final String examName;
  final int totalQuestion;
  final int correct;
  final int diemLietWrong;
  final int usedSeconds;
  final Map<String, dynamic>? chapterResult;

  final List<Question> questions;
  final List<int?> selections;

  const ExamResultPage({
    super.key,
    required this.examId,
    required this.examName,
    required this.totalQuestion,
    required this.correct,
    required this.diemLietWrong,
    required this.usedSeconds,
    this.chapterResult,
    this.questions = const [],
    this.selections = const [],
  });

  Map<String, String> analyzeChapterStats(Map<String, dynamic>? stats) {
    if (stats == null) return {};

    final Map<String, String> result = {};

    stats.forEach((chapter, data) {
      final int total = data['total'] ?? 0;
      final int correct = data['correct'] ?? 0;

      if (total == 0) {
        result[chapter] = 'Không có dữ liệu';
        return;
      }

      final double accuracy = correct / total * 100;

      if (accuracy >= 80) {
        result[chapter] = 'Tốt – Bạn nắm chắc chương này.';
      } else if (accuracy >= 60) {
        result[chapter] = 'Tạm ổn – Bạn nên luyện tập thêm.';
      } else {
        result[chapter] = 'Yếu – Bạn cần ôn tập lại chương này.';
      }
    });

    return result;
  }

  @override
  State<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends State<ExamResultPage> {
  bool _saving = false;
  bool _saved = false;
  String? _error;

  bool get _passed => widget.correct >= 21 && widget.diemLietWrong == 0;

  double get _percent => widget.totalQuestion == 0
      ? 0
      : widget.correct * 100.0 / widget.totalQuestion;

  @override
  void initState() {
    super.initState();
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _saving = false;
          _error = 'Không tìm thấy token đăng nhập. Kết quả không được lưu.';
        });
        return;
      }

      const service = HistoryService();
      final ok = await service.saveExamResult(
        token: token,
        examId: widget.examId,
        totalQuestion: widget.totalQuestion,
        correct: widget.correct,
        diemLietWrong: widget.diemLietWrong,
        passed: _passed,
        time: widget.usedSeconds,
        chapterResult: widget.chapterResult,
      );

      setState(() {
        _saving = false;
        _saved = ok;
        if (!ok) _error = 'Không lưu được lịch sử thi.';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Lỗi khi lưu kết quả: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool passed = _passed;
    final Color statusColor = passed ? Colors.green : Colors.redAccent;
    final String statusLabel = passed ? 'ĐẠT' : 'KHÔNG ĐẠT';
    final chapterAnalysis = widget.analyzeChapterStats(widget.chapterResult);

    final bool canReview = widget.questions.isNotEmpty &&
        widget.questions.length == widget.selections.length;

    Widget buildChapterRow(String chapter, String msg) {
      final bool isWeak = msg.startsWith('Yếu');
      final bool isOk = msg.startsWith('Tạm ổn');
      final bool isGood = msg.startsWith('Tốt');

      final parts = msg.split('–');
      final String status = parts.first.trim();
      final String detail =
          parts.length > 1 ? parts.sublist(1).join('–').trim() : '';

      IconData icon = Icons.info_outline;
      Color iconColor = Colors.grey;
      Color statusColor = Colors.black87;

      if (isWeak) {
        icon = Icons.error_outline;
        iconColor = const Color(0xFFD84315);
        statusColor = const Color.fromARGB(255, 255, 60, 0);
      } else if (isOk) {
        icon = Icons.lightbulb_outline;
        iconColor = const Color(0xFFEF6C00);
        statusColor = const Color(0xFFEF6C00);
      } else if (isGood) {
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF2E7D32);
        statusColor = const Color(0xFF2E7D32);
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: status,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        if (detail.isNotEmpty) ...[
                          const TextSpan(
                            text: " – ",
                            style: TextStyle(fontSize: 15),
                          ),
                          TextSpan(
                            text: detail,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Kết quả thi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ======= CARD KẾT QUẢ GIỐNG HÌNH =======
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                              255, 239, 242, 244), // xám nhạt đẹp
                          borderRadius: BorderRadius.circular(20),

                          // ⭐ Border nhẹ, tinh tế
                          border: Border.all(
                            color: Colors.black.withOpacity(0.10),
                            width: 1,
                          ),

                          // ⭐ Shadow sát khung, mềm mại
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: -2, // kéo bóng sát khung
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.examName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${widget.correct}/${widget.totalQuestion} câu đúng (${_percent.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sai câu điểm liệt: ${widget.diemLietWrong}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.80),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Thời gian làm bài: ${widget.usedSeconds} giây',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.80),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ===== NHẬN XÉT THEO CHƯƠNG =====
                      if (chapterAnalysis.isNotEmpty) ...[
                        const Text(
                          "Nhận xét theo chương",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...chapterAnalysis.entries
                            .map((e) => buildChapterRow(e.key, e.value)),
                        const SizedBox(height: 20),
                      ],

                      // ===== TRẠNG THÁI LƯU LỊCH SỬ =====
                      if (_saving) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 8),
                        const Center(child: Text('Đang lưu kết quả thi...')),
                      ] else if (_saved && _error == null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 6),
                            Text('Kết quả đã được lưu vào lịch sử thi.'),
                          ],
                        ),
                      ] else if (_error != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ===== NÚT DƯỚI =====
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: !canReview
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExamReviewPage(
                                    examName: widget.examName,
                                    questions: widget.questions,
                                    selections: widget.selections,
                                  ),
                                ),
                              );
                            },
                      child: const Text('Xem lại bài thi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('Về trang chủ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
