import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/services/wrong_service.dart';

/// Trang hiển thị danh sách các câu hỏi đã trả lời sai (từ backend)
class IncorrectQuestionsPage extends StatefulWidget {
  const IncorrectQuestionsPage({Key? key}) : super(key: key);

  @override
  State<IncorrectQuestionsPage> createState() => _IncorrectQuestionsPageState();
}

class _IncorrectQuestionsPageState extends State<IncorrectQuestionsPage> {
  late Future<List<Question>> _future;

  @override
  void initState() {
    super.initState();
    _future = WrongService.fetchWrongQuestions(); // lấy tất cả
  }

  Future<void> _reload() async {
    setState(() {
      _future = WrongService.fetchWrongQuestions();
    });
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả câu sai?'),
        content: const Text(
          'Bạn chắc chắn muốn xóa toàn bộ câu sai không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final success = await WrongService.clearWrong(); // xoá tất cả
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tất cả câu sai')),
          );
          _reload();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa thất bại, thử lại sau!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xoá: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5D84),
        title: const Text('Câu trả lời sai',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            color: Colors.white,
            tooltip: 'Xóa tất cả câu sai',
            onPressed: _confirmDeleteAll,
          ),
        ],
      ),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            );
          }

          final incorrectQuestions = snapshot.data ?? [];
          if (incorrectQuestions.isEmpty) {
            return const Center(
              child: Text('Không có câu trả lời sai nào được lưu.'),
            );
          }

          return ListView.builder(
            itemCount: incorrectQuestions.length,
            itemBuilder: (context, index) {
              final q = incorrectQuestions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Câu ${q.indexNumber ?? (index + 1)}: ${q.questionText}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(q.answers.length, (i) {
                          final isCorrect = i == q.correctAnswerIndex;
                          final answerText =
                              '${String.fromCharCode(65 + i)}. ${q.answers[i]}';

                          if (isCorrect) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDFF1E0), // nền xanh nhạt
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      answerText,
                                      style: const TextStyle(
                                        fontSize: 16, // chữ to hơn
                                        fontWeight: FontWeight.w700, // in đậm
                                        color: Color(0xFF1B5E20), // xanh đậm
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: Color(0xFF2E7D32), // tick xanh
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // 🔹 Các đáp án còn lại
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                answerText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
