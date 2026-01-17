import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/ui/quiz_ui.dart';
import 'package:bo_de_600_gplx/ui/quiz_app_bar.dart';

class QuizReviewPage extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final List<int?> selections;
  final List<bool?> answerResults;
  final int initialIndex;

  const QuizReviewPage({
    super.key,
    required this.title,
    required this.questions,
    required this.selections,
    required this.answerResults,
    this.initialIndex = 0,
  }) : assert(
          questions.length == selections.length &&
              questions.length == answerResults.length,
          'questions, selections, answerResults phải cùng độ dài',
        );

  @override
  State<QuizReviewPage> createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  void _goPrev() {
    if (_index <= 0) return;
    setState(() => _index--);
    _controller.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _goNext() {
    if (_index >= widget.questions.length - 1) return;
    setState(() => _index++);
    _controller.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuizAppBar(
        title: widget.title,
        
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          QuizTopBar(
            current: _index + 1,
            total: widget.questions.length,
            isDiemLiet: widget.questions[_index].isDiemLiet,
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.questions.length,
              itemBuilder: (context, i) {
                final q = widget.questions[i];
                final selected = widget.selections[i];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (q.imageUrl != null && q.imageUrl!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              q.imageUrl!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      QuizQuestionText(q.questionText),

                      // ✅ REVIEW MODE: showResult = true, onChanged = null (khóa chọn)
                      QuizAnswerList(
                        answers: q.answers,
                        correctIndex: q.correctAnswerIndex,
                        groupValue: selected,
                        onChanged: null,      // ❌ khóa chọn đáp án
                        showResult: true,     // ✅ hiện đúng/sai
                      ),

                      if (q.explain != null && q.explain!.trim().isNotEmpty)
                        QuizExplanation(text: q.explain!.trim()),
                    ],
                  ),
                );
              },
            ),
          ),
          QuizBottomBar(
            canPrev: _index > 0,
            canNext: _index < widget.questions.length - 1,
            onPrev: _goPrev,
            onNext: _goNext,
            nextLabel: _index < widget.questions.length - 1 ? 'Câu tiếp' : 'Hết',
          ),
        ],
      ),
    );
  }
}
