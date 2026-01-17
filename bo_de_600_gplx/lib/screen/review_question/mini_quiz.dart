import 'package:flutter/material.dart';

import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/services/question_service.dart';
import 'package:bo_de_600_gplx/services/practice_service.dart';
import 'package:bo_de_600_gplx/ui/quiz_ui.dart';
import 'package:bo_de_600_gplx/ui/quiz_app_bar.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';
import 'package:bo_de_600_gplx/ui/tts_page.dart';

class ReviewQuizPage extends StatefulWidget {
  const ReviewQuizPage({
    super.key,
    required this.chapterId,
    this.limit,
    this.title = 'Ôn tập câu hỏi',
  });

  final String chapterId;
  final int? limit;
  final String title;

  @override
  State<ReviewQuizPage> createState() => _ReviewQuizPage();
}

class _ReviewQuizPage extends State<ReviewQuizPage> {
  late Future<List<Question>> _future;
  int _current = 0;

  /// index câu -> index đáp án đã chọn
  final Map<int, int> _chosen = {};

  // ✅ tránh LateInitializationError
  TtsHelper? _tts;

  @override
  void initState() {
    super.initState();

    _tts = TtsHelper(onStateChanged: () {
      if (mounted) setState(() {});
    });

    _future = QuestionService.getPracticeByChapter(
      widget.chapterId,
      limit: widget.limit,
    );
  }

  @override
  void dispose() {
    _tts?.stop();
    _tts = null;
    super.dispose();
  }

  void _go(int step, int total) {
    _tts?.stop(); // ✅ stop đọc khi chuyển câu
    setState(() {
      _current = (_current + step).clamp(0, total - 1);
    });
  }

  /// Gửi attempt lên server để lưu tiến trình + wrong_questions
  Future<void> _saveAttempt(Question q, int selectedIndex) async {
    final isCorrect = selectedIndex == q.correctAnswerIndex;

    try {
      await PracticeService.recordAttempt(
        questionId: q.id,
        chapterId: widget.chapterId,
        isCorrect: isCorrect,
        source: 'chapter',
      );
    } catch (e) {
      debugPrint('Lỗi save attempt (chapter review): $e');
    }
  }

  Future<void> _handleFinish(List<Question> questions) async {
    final answered = _chosen.length;
    final total = questions.length;

    final ok = await showConfirmFinishDialog(
      context,
      answered: answered,
      total: total,
      title: 'Kết thúc ôn tập?',
      message: 'Bạn đã trả lời $answered/$total câu.\n'
          'Bạn muốn kết thúc và xem kết quả ôn tập?',
    );

    if (!ok) return;

    _tts?.stop(); // ✅ stop trước khi qua trang kết quả

    // 1) selections
    final selections = List<int?>.generate(
      total,
      (i) => _chosen[i],
    );

    // 2) answerResults
    final answerResults = List<bool?>.generate(total, (i) {
      final sel = selections[i];
      if (sel == null) return null;
      return sel == questions[i].correctAnswerIndex;
    });

    // 3) isDiemLietList
    final isDiemLietList = questions.map((q) => q.isDiemLiet).toList();

    // 4) correctCount
    final correctCount = answerResults.where((e) => e == true).length;

    // 5) sang trang ResultPage
    Navigator.pushNamed(
      context,
      AppRouter.result,
      arguments: {
        'correctCount': correctCount,
        'totalQuestions': total,
        'duration': Duration.zero,
        'answerResults': answerResults,
        'isDiemLietList': isDiemLietList,
        'questions': questions,
        'selections': selections,
        'reviewTitle': 'Xem lại câu hỏi ôn tập',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }

          final questions = snap.data ?? [];
          if (questions.isEmpty) {
            return const Center(child: Text('Không có câu hỏi.'));
          }

          final q = questions[_current];
          final chosen = _chosen[_current];
          final isAnswered = chosen != null;

          return Column(
            children: [
              // === APP BAR + KẾT THÚC ===
              QuizAppBar(
                title: widget.title,
                onBack: () {
                  _tts?.stop(); // ✅ stop khi back
                  Navigator.pop(context);
                },
                onFinish: () => _handleFinish(questions),
              ),

              // === TOP BAR ===
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: QuizTopBar(
                  current: _current + 1,
                  total: questions.length,
                  isDiemLiet: q.isDiemLiet,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (q.imageUrl != null && q.imageUrl!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                q.imageUrl!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                      // ✅ CÂU HỎI + NÚT ĐỌC (y hệt 20_question)
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

                      // ✅ ĐÁP ÁN + NÚT ĐỌC TỪNG ĐÁP ÁN
                      QuizAnswerList(
                        answers: q.answers,
                        correctIndex: q.correctAnswerIndex,
                        groupValue: chosen,
                        onChanged: (v) {
                          setState(() {
                            _chosen[_current] = v;
                          });

                          // Gửi attempt để lưu câu đúng / sai
                          _saveAttempt(q, v);
                        },
                        tts: _tts, // ✅ quan trọng
                      ),

                      if (isAnswered && (q.explain?.trim().isNotEmpty ?? false))
                        QuizExplanation(text: q.explain!.trim()),
                    ],
                  ),
                ),
              ),

              // === NÚT CÂU TRƯỚC / CÂU TIẾP ===
              QuizBottomBar(
                canPrev: _current > 0,
                canNext: _current < questions.length - 1,
                onPrev: () => _go(-1, questions.length),
                onNext: () => _go(1, questions.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
