import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/ui/tts_page.dart';

import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/services/question_service.dart';
import 'package:bo_de_600_gplx/services/progress_service.dart';
import 'package:bo_de_600_gplx/ui/quiz_ui.dart';
import 'package:bo_de_600_gplx/ui/quiz_app_bar.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';

class DiemLietPage extends StatefulWidget {
  const DiemLietPage({Key? key}) : super(key: key);

  @override
  State<DiemLietPage> createState() => _DiemLietPageState();
}

class _DiemLietPageState extends State<DiemLietPage> {
  static const int _targetCount = 20;

  bool _loading = true;
  List<Question> _questions = [];

  int _index = 0;
  int? _selected;

  List<int?> _selections = const [];

  late DateTime _startedAt;

  // ✅ tránh LateInitializationError
  TtsHelper? _tts;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    _tts = TtsHelper(onStateChanged: () {
      if (mounted) setState(() {});
    });

    _loadQuestions();
  }

  @override
  void dispose() {
    _tts?.stop();
    _tts = null;
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _questions = [];
      _index = 0;
      _selected = null;
      _selections = const [];
      _startedAt = DateTime.now();
    });

    try {
      final data =
          await QuestionService.fetchDiemLietQuestions(limit: _targetCount);
      if (!mounted) return;

      setState(() {
        _questions = data;
        _selections = List<int?>.filled(_questions.length, null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải câu điểm liệt: $e')),
      );
    }
  }

  Question get _q => _questions[_index];
  bool get _answered => _selected != null;

  void _onSelect(int idx) {
    setState(() {
      _selected = idx;
      if (_index < _selections.length) _selections[_index] = idx;
    });
  }

  void _goPrev() {
    if (_index == 0) return;
    _tts?.stop();
    setState(() {
      _index--;
      _selected = _selections[_index];
    });
  }

  void _goNext() {
    if (!_answered) return;
    _tts?.stop();

    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = _selections[_index];
      });
    } else {
      _finish();
    }
  }

  Future<void> _confirmEarlyFinish() async {
    final ok = await showConfirmFinishDialog(
      context,
      answered: _selections.where((e) => e != null).length,
      total: _questions.length,
    );
    if (ok) _finish(forceAsWrong: true);
  }

  String? _chapterTagOf(Question q) {
    try {
      final dynamic any = q as dynamic;
      final dynamic v = (any.chapterTag ?? any.chapter_tag ?? any.chapterId);
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return q.chapterTag;
  }

  bool? _isCorrectAt(int i, {required bool forceAsWrong}) {
    final sel = _selections[i];
    if (sel == null) return forceAsWrong ? false : null;
    return sel == _questions[i].correctAnswerIndex;
  }

  Future<void> _submitAllAttempts({required bool forceAsWrong}) async {
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final res = _isCorrectAt(i, forceAsWrong: forceAsWrong);
      if (res == null) continue;

      final chapId = _chapterTagOf(q);
      if (chapId == null || chapId.isEmpty) continue;

      try {
        await ProgressService.sendAttempt(
          questionId: q.id,
          chapterTag: chapId,
          isCorrect: res,
          source: 'critical',
        );
      } catch (_) {}
    }
  }

  Future<void> _openWrongQuestionsPage() async {
    await _submitAllAttempts(forceAsWrong: false);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRouter.wrongQuestions);
  }

  Future<void> _finish({bool forceAsWrong = false}) async {
    await _submitAllAttempts(forceAsWrong: forceAsWrong);

    final answerResults = List<bool?>.generate(_questions.length, (i) {
      return _isCorrectAt(i, forceAsWrong: forceAsWrong);
    });

    final isDiemLietList = _questions.map((q) => q.isDiemLiet).toList();
    final correctCount = answerResults.where((e) => e == true).length;
    final duration = DateTime.now().difference(_startedAt);

    Navigator.pushNamed(
      context,
      AppRouter.result,
      arguments: {
        'correctCount': correctCount,
        'totalQuestions': _questions.length,
        'duration': duration,
        'answerResults': answerResults,
        'isDiemLietList': isDiemLietList,
        'questions': _questions,
        'selections': _selections,
        'reviewTitle': 'Xem lại câu điểm liệt',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('20 Câu điểm liệt')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không có câu hỏi điểm liệt.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    final q = _q;

    return Scaffold(
      appBar: QuizAppBar(
        title: 'Câu điểm liệt',
        onFinish: _confirmEarlyFinish,
        actions: [
          IconButton(
            icon: const Icon(Icons.error_outline, color: Colors.white),
            tooltip: 'Xem câu sai',
            onPressed: _openWrongQuestionsPage,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: QuizTopBar(
              current: _index + 1,
              total: _questions.length,
              isDiemLiet: q.isDiemLiet,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          q.imageUrl!,
                          height: 180,
                          errorBuilder: (_, __, ___) =>
                              const Text('Không tải được ảnh'),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  QuizAnswerList(
                    answers: q.answers,
                    correctIndex: q.correctAnswerIndex,
                    groupValue: _selected,
                    onChanged: _onSelect,
                    tts: _tts, // ✅ thêm dòng này
                  ),
                ],
              ),
            ),
          ),
          QuizBottomBar(
            canPrev: _index > 0,
            canNext: _answered,
            onPrev: _goPrev,
            onNext: _goNext,
            nextLabel:
                _index < _questions.length - 1 ? 'Câu tiếp' : 'Hoàn thành',
          ),
        ],
      ),
    );
  }
}
