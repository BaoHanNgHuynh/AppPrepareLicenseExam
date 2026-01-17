import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/ui/quiz_ui.dart';

class ExamReviewPage extends StatefulWidget {
  final String examName;
  final List<Question> questions;
  final List<int?> selections;

  const ExamReviewPage({
    super.key,
    required this.examName,
    required this.questions,
    required this.selections,
  });

  @override
  State<ExamReviewPage> createState() => _ExamReviewPageState();
}

class _ExamReviewPageState extends State<ExamReviewPage> {
  int _current = 0;

  void _prev() {
    if (_current > 0) setState(() => _current--);
  }

  void _next() {
    if (_current < widget.questions.length - 1) {
      setState(() => _current++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty || widget.selections.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF296E85),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text("Xem lại: ${widget.examName}"),
        ),
        body: const Center(
          child: Text('Không có dữ liệu chi tiết bài thi để xem lại.'),
        ),
      );
    }

    final q = widget.questions[_current];
    final selected = widget.selections[_current];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Nền nhạt
      appBar: AppBar(
        backgroundColor: const Color(0xFF296E85),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        title: Text(
          "Xem lại: ${widget.examName}",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Câu X/Y ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              "Câu ${_current + 1}/${widget.questions.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Ảnh minh họa (KHÔNG nằm trong card nữa) ---
                  if ((q.imageUrl ?? "").isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        q.imageUrl!,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // --- Câu hỏi ---
                  QuizQuestionText(q.questionText),

                  // --- Danh sách đáp án ---
                  QuizAnswerList(
                    answers: q.answers,
                    correctIndex: q.correctAnswerIndex,
                    groupValue: selected,
                    onChanged: (_) {}, // disable
                    showResult: true,
                  ),

                  const SizedBox(height: 12),

                  // --- Giải thích ---
                  if ((q.explain ?? "").isNotEmpty) ...[
                    QuizExplanation(text: q.explain!),
                  ],
                ],
              ),
            ),
          ),

          // --- Thanh chuyển câu ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _current > 0 ? _prev : null,
                    child: const Text("Câu trước"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _current < widget.questions.length - 1 ? _next : null,
                    child: const Text("Câu tiếp"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
