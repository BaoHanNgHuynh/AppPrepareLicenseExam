import 'package:flutter/material.dart';
import 'dart:async';

import 'package:bo_de_600_gplx/services/exam_service.dart';
import 'package:bo_de_600_gplx/models/exam.dart';
import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/screen/exam/exam_result.dart';

import 'package:bo_de_600_gplx/ui/quiz_app_bar.dart';
import 'package:bo_de_600_gplx/ui/quiz_ui.dart';

import 'package:bo_de_600_gplx/ui/info_dialog.dart';
import 'package:bo_de_600_gplx/ui/tts_page.dart';

class ExamScreen extends StatefulWidget {
  final String examId;
  final String examName;

  const ExamScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  Future<ExamDetail>? _future;

  List<int?> _selected = [];
  int _current = 0;

  Timer? _timer;
  int _timeLimit = 0;
  int _remainingSeconds = 0;

  bool _examLoaded = false;
  bool _submitted = false;

  bool _started = false;
  bool _dialogShown = false;

  TtsHelper? _tts;

  @override
  void initState() {
    super.initState();
    _future = ExamService.fetchExamDetail(widget.examId);

    _tts = TtsHelper(onStateChanged: () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts?.stop();
    _tts = null;
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startTimer(List<Question> questions) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        t.cancel();
        if (!_submitted) _submitExam(questions);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _showStartDialogOnce({
    required int totalQuestions,
    required int timeLimitSeconds,
    required int diemLietCount,
    required List<Question> questions,
  }) {
    if (_dialogShown || _started) return;
    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      const passScore = 21;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          title: const Text(
            'Cấu trúc đề thi',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLine.item(
                Icons.timer,
                'Thời gian: ${timeLimitSeconds ~/ 60} phút',
                iconColor: Colors.blue,
              ),
              InfoLine.item(
                Icons.help_outline,
                'Số câu: $totalQuestions',
                iconColor: Colors.indigo,
              ),
              InfoLine.item(
                Icons.check_circle_outline,
                'Đạt: $passScore/$totalQuestions',
                iconColor: Colors.green,
              ),
              InfoLine.item(
                Icons.warning_amber_rounded,
                'Điểm liệt: $diemLietCount câu',
                iconColor: Colors.redAccent,
              ),
              const SizedBox(height: 6),
              const Text(
                'Sai câu điểm liệt = trượt.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

      if (!_started && mounted) {
        setState(() => _started = true);
        _startTimer(questions);
      }
    });
  }

  void _prev() {
    if (!_started) return;
    if (_current > 0) {
      _tts?.stop();
      setState(() => _current--);
    }
  }

  void _next(int total) {
    if (!_started) return;
    if (_current >= total - 1) return;

    _tts?.stop();
    setState(() => _current++);
  }

  void _submitExam(List<Question> questions) {
    if (_submitted) return;
    _submitted = true;

    _timer?.cancel();
    _tts?.stop();

    int correct = 0;
    int diemLietWrong = 0;

    final Map<String, Map<String, int>> chapterStats = {};

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final sel = _selected[i];

      final chapterKey = (q.chapterTitle ?? q.chapterTag ?? '').trim();
      if (chapterKey.isNotEmpty) {
        chapterStats.putIfAbsent(chapterKey, () => {'total': 0, 'correct': 0});
        chapterStats[chapterKey]!['total'] =
            chapterStats[chapterKey]!['total']! + 1;
      }

      if (sel != null && sel == q.correctAnswerIndex) {
        correct++;
        if (chapterKey.isNotEmpty) {
          chapterStats[chapterKey]!['correct'] =
              chapterStats[chapterKey]!['correct']! + 1;
        }
      } else if (q.isDiemLiet == true) {
        diemLietWrong++;
      }
    }

    final usedSeconds = _timeLimit - _remainingSeconds;
    final safeUsedSeconds = usedSeconds < 0 ? 0 : usedSeconds;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamResultPage(
          examId: widget.examId,
          examName: widget.examName,
          totalQuestion: questions.length,
          correct: correct,
          diemLietWrong: diemLietWrong,
          usedSeconds: safeUsedSeconds,
          chapterResult: chapterStats,
          questions: questions,
          selections: List<int?>.from(_selected),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExamDetail>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: QuizAppBar(title: widget.examName),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            appBar: QuizAppBar(title: widget.examName),
            body: Center(child: Text('Lỗi: ${snap.error}')),
          );
        }

        final detail = snap.data!;
        final questions = detail.questions;

        if (questions.isEmpty) {
          return Scaffold(
            appBar: QuizAppBar(title: widget.examName),
            body: const Center(child: Text('Đề thi không có câu hỏi.')),
          );
        }

        if (!_examLoaded) {
          _examLoaded = true;

          _timeLimit = detail.timeLimit;
          _remainingSeconds = _timeLimit;

          if (_selected.length != questions.length) {
            _selected =
                List<int?>.filled(questions.length, null, growable: false);
          }

          const int diemLietCount = 1;

          _showStartDialogOnce(
            totalQuestions: questions.length,
            timeLimitSeconds: _timeLimit,
            diemLietCount: diemLietCount,
            questions: questions,
          );
        }

        final int cur = _current.clamp(0, questions.length - 1);
        final q = questions[cur];
        final answered = _selected.where((e) => e != null).length;

        // ✅ chiều cao ảnh: vừa đủ to, không che UI
        final imageBoxHeight = MediaQuery.of(context).size.height * 0.28;

        return Scaffold(
          appBar: QuizAppBar(
            title: widget.examName,
            onFinish: () async {
              if (!_started) return;

              final ok = await showConfirmFinishDialog(
                context,
                answered: answered,
                total: questions.length,
                title: 'Kết thúc bài thi?',
                message: 'Bạn đã trả lời $answered/${questions.length} câu.\n'
                    'Bạn muốn nộp bài và xem kết quả?',
              );

              if (ok) _submitExam(questions);
            },
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: QuizTopBar(
                  current: _current + 1,
                  total: questions.length,
                  isDiemLiet: q.isDiemLiet == true,
                  trailing: QuizTimerBadge(
                    timeText: _formatTime(_remainingSeconds),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ FIX: không crop ảnh nữa
                      if ((q.imageUrl ?? '').trim().isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: imageBoxHeight,
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Image.network(
                              q.imageUrl!,
                              fit: BoxFit.contain, // ✅ quan trọng
                              alignment: Alignment.center,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Text('Không tải được ảnh')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: QuizQuestionText(q.questionText)),
                          (_tts == null)
                              ? const SizedBox.shrink()
                              : _tts!.buildSpeakButton(
                                  text: q.questionText,
                                  key: "q",
                                  tooltip: "Đọc câu hỏi",
                                ),
                        ],
                      ),

                      QuizAnswerList(
                        answers: q.answers,
                        correctIndex: q.correctAnswerIndex,
                        groupValue: _selected[cur],
                        onChanged: !_started
                            ? null
                            : (index) => setState(() => _selected[cur] = index),
                        showResult: false,
                        tts: _tts,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: QuizBottomBar(
            canPrev: _started && _current > 0,
            canNext:
                _started && _current < questions.length - 1, 
            onPrev: _prev,
            onNext: () => _next(questions.length),
            nextLabel: 'Câu tiếp',
          ),
        );
      },
    );
  }
}
