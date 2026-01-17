import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bo_de_600_gplx/services/question_service.dart';
import 'package:bo_de_600_gplx/services/progress_service.dart';
import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/ui/quiz_ui.dart';
import 'package:bo_de_600_gplx/ui/quiz_app_bar.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';
import 'package:bo_de_600_gplx/ui/info_dialog.dart';

import 'package:bo_de_600_gplx/ui/tts_page.dart';

class CauHoiNgauNhienPage extends StatefulWidget {
  const CauHoiNgauNhienPage({Key? key}) : super(key: key);

  @override
  State<CauHoiNgauNhienPage> createState() => _CauHoiNgauNhienPageState();
}

class _CauHoiNgauNhienPageState extends State<CauHoiNgauNhienPage> {
  final int totalQuestions = 25;
  final Duration examDuration = const Duration(minutes: 19);

  List<Question>? quizQuestions;
  int currentIndex = 0;
  int? selectedAnswer;

  late List<int?> userAnswers;

  late Duration remainingTime;
  Timer? _timer;
  bool _loading = true;

  bool _started = false;
  bool _dialogShown = false;

  TtsHelper? _tts;

  @override
  void initState() {
    super.initState();

    remainingTime = examDuration;

    _tts = TtsHelper(onStateChanged: () {
      if (mounted) setState(() {});
    });

    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await QuestionService.fetchRandomExam();
      if (!mounted) return;

      setState(() {
        quizQuestions = questions;
        userAnswers = List<int?>.filled(questions.length, null);
        _loading = false;
      });

      _showStartDialogOnce();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải đề ngẫu nhiên: $e')),
      );
    }
  }

  void _showStartDialogOnce() {
    if (_dialogShown || _started) return;
    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      const passScore = 21;
      const diemLietCount = 1;

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
                'Thời gian: ${examDuration.inMinutes} phút',
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
              )
            ],
          ),
        ),
      );

      if (!_started && mounted) {
        setState(() => _started = true);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (remainingTime.inSeconds > 0) {
          remainingTime -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          _navigateToResultPage();
        }
      });
    });
  }

  void _choose(int value) {
    if (!_started) return;
    setState(() {
      selectedAnswer = value;
      userAnswers[currentIndex] = value;
    });
  }

  bool get _isLast => currentIndex == quizQuestions!.length - 1;

  void _goPrev() {
    if (!_started) return;
    if (currentIndex > 0) {
      _tts?.stop(); // ✅ stop đọc khi chuyển câu
      setState(() {
        currentIndex--;
        selectedAnswer = userAnswers[currentIndex];
      });
    }
  }

  void _goNext() {
    if (!_started) return;

    _tts?.stop(); // ✅ stop đọc khi chuyển câu

    if (_isLast) {
      _navigateToResultPage();
    } else {
      setState(() {
        currentIndex++;
        selectedAnswer = userAnswers[currentIndex];
      });
    }
  }

  String? _chapterIdOf(Question q) {
    try {
      final dynamic any = q as dynamic;
      final dynamic v = (any.chapterTag ?? any.chapter_tag ?? any.chapterId);
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  bool? _isCorrectAt(int i, {required bool forceAsWrong}) {
    final sel = userAnswers[i];
    if (sel == null) return forceAsWrong ? false : null;
    return sel == quizQuestions![i].correctAnswerIndex;
  }

  Future<void> _submitAllAttempts({required bool forceAsWrong}) async {
    if (quizQuestions == null) return;

    for (int i = 0; i < quizQuestions!.length; i++) {
      final q = quizQuestions![i];

      final res = _isCorrectAt(i, forceAsWrong: forceAsWrong);
      if (res == null) continue;

      final tag = _chapterIdOf(q);
      if (tag == null) continue;

      try {
        await ProgressService.sendAttempt(
          questionId: q.id,
          chapterTag: tag,
          isCorrect: res,
          source: 'random',
        );
      } catch (_) {}
    }
  }

  Future<void> _openWrongQuestionsPage() async {
    await _submitAllAttempts(forceAsWrong: false);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRouter.wrongQuestions);
  }

  Future<void> _navigateToResultPage({bool forceAsWrong = false}) async {
    _timer?.cancel();
    _tts?.stop(); // ✅ stop TTS khi nộp bài/ra trang kết quả

    await _submitAllAttempts(forceAsWrong: forceAsWrong);

    final List<bool?> resultsForSubmit = List<bool?>.generate(
      quizQuestions!.length,
      (i) => _isCorrectAt(i, forceAsWrong: forceAsWrong),
    );

    final correctCount = resultsForSubmit.where((e) => e == true).length;

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    final entry = jsonEncode({  
      'correct': correctCount,
      'total': quizQuestions!.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setStringList('history', [...history, entry]);

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRouter.result,
      arguments: {
        'correctCount': correctCount,
        'totalQuestions': quizQuestions!.length,
        'duration': examDuration - remainingTime,
        'answerResults': resultsForSubmit,
        'isDiemLietList': quizQuestions!.map((q) => q.isDiemLiet).toList(),
        'questions': quizQuestions,
        'selections': userAnswers,
        'reviewTitle': 'Xem lại đề ngẫu nhiên',
      },
    );
  }

  void _backToHome() {
    _timer?.cancel();
    _tts?.stop();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home,
      (route) => false,
    );
  }

  Future<void> _confirmFinish() async {
    if (!_started) return;
    final ok = await showConfirmFinishDialog(
      context,
      answered: userAnswers.where((e) => e != null).length,
      total: quizQuestions?.length ?? 0,
    );
    if (ok) _navigateToResultPage(forceAsWrong: true);
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts?.stop();
    _tts = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quizQuestions == null || quizQuestions!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đề ngẫu nhiên')),
        body: const Center(child: Text('Không tải được đề ngẫu nhiên.')),
      );
    }

    final question = quizQuestions![currentIndex];

    return Scaffold(
      appBar: QuizAppBar(
        title: 'Đề ngẫu nhiên',
        onBack: _backToHome,
        onFinish: _confirmFinish,
        actions: [
          IconButton(
            icon: const Icon(Icons.error_outline, color: Colors.white),
            tooltip: 'Xem câu sai',
            onPressed: _started ? _openWrongQuestionsPage : null,
          ),
        ],
      ),
      body: Column(
        children: [
          QuizTopBar(
            current: currentIndex + 1,
            total: quizQuestions!.length,
            isDiemLiet: question.isDiemLiet,
            trailing: QuizTimerBadge(timeText: _formatTime(remainingTime)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (question.imageUrl != null &&
                      question.imageUrl!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          question.imageUrl!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                  // ✅ Câu hỏi + nút đọc (y hệt 20_question)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: QuizQuestionText(question.questionText)),
                      (_tts == null)
                          ? const SizedBox.shrink()
                          : _tts!.buildSpeakButton(
                              text: question.questionText,
                              key: "q",
                              tooltip: "Đọc câu hỏi",
                            ),
                    ],
                  ),

                  // ✅ Đáp án có loa từng câu
                  QuizAnswerList(
                    answers: question.answers,
                    correctIndex: question.correctAnswerIndex,
                    groupValue: selectedAnswer,
                    onChanged: _choose,
                    showResult: false,
                    tts: _tts, // ✅ quan trọng
                  ),
                ],
              ),
            ),
          ),
          QuizBottomBar(
            canPrev: _started && currentIndex > 0,
            canNext: _started && selectedAnswer != null,
            nextLabel: _isLast ? 'Kết thúc' : 'Câu tiếp',
            onPrev: _goPrev,
            onNext: _goNext,
          ),
        ],
      ),
    );
  }
}
